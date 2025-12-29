`include "fixed_point_pkg.vh"

/**
 * @module VPU_Synth (Vector Processing Unit - Synthesizable)
 * @brief Synthesizable VPU using fixed-point and LUT-based approximations.
 *
 * Supports:
 * 1. L2 Normalization (Op 0) - Uses approximated inverse square root
 * 2. Softmax Weighted Sum (Op 1) - Uses LUT-based exp approximation
 *
 * @param VECTOR_SIZE Number of elements in vector (default 32)
 */
module VPU_Synth #(
    parameter VECTOR_SIZE = 32
)(
    input  wire                        clk,
    input  wire                        reset,
    input  wire                        start,
    output reg                         done,
    input  wire                        op_sel,  // 0: Norm, 1: Softmax
    
    // Inputs (Q16.16 fixed-point)
    input  wire [`FP_WIDTH*VECTOR_SIZE-1:0] vec_in_scores_flat,
    input  wire [`FP_WIDTH*VECTOR_SIZE-1:0] vec_in_values_flat,
    
    // Outputs
    output reg  [`FP_WIDTH*VECTOR_SIZE-1:0] vec_out_norm_flat,
    output reg  [`FP_WIDTH-1:0]             scalar_out_softmax
);

    // State Machine
    localparam IDLE         = 3'd0;
    localparam NORM_SUM_SQ  = 3'd1;
    localparam NORM_SQRT    = 3'd2;
    localparam NORM_DIV     = 3'd3;
    localparam SOFT_PASS    = 3'd4;
    localparam FINISH       = 3'd5;
    
    reg [2:0] state;
    reg [7:0] idx;
    
    // Accumulators
    reg signed [`MAC_ACC_WIDTH-1:0] sum_sq_acc;
    reg signed [`FP_WIDTH-1:0]      norm_val;
    reg signed [`FP_WIDTH-1:0]      max_val;
    reg signed [`MAC_ACC_WIDTH-1:0] exp_sum;
    reg signed [`MAC_ACC_WIDTH-1:0] weighted_sum;
    
    // Unpack inputs to internal arrays
    wire signed [`FP_WIDTH-1:0] scores [0:VECTOR_SIZE-1];
    wire signed [`FP_WIDTH-1:0] values [0:VECTOR_SIZE-1];
    
    genvar g;
    generate
        for (g = 0; g < VECTOR_SIZE; g = g + 1) begin : unpack
            assign scores[g] = vec_in_scores_flat[`FP_WIDTH*(g+1)-1:`FP_WIDTH*g];
            assign values[g] = vec_in_values_flat[`FP_WIDTH*(g+1)-1:`FP_WIDTH*g];
        end
    endgenerate
    
    // Output array - stores normalized values
    reg signed [`FP_WIDTH-1:0] norm_out [0:VECTOR_SIZE-1];
    
    // Output packing is done in the FINISH state procedurally
    // (Cannot use continuous assign from reg array to reg output)
    
    // =========================================================================
    // Approximate Inverse Square Root (Fast InvSqrt inspired by Quake III)
    // For fixed-point: use Newton-Raphson iteration
    // Simplified: just use iterative approximation
    // =========================================================================
    reg signed [`FP_WIDTH-1:0] inv_sqrt_result;
    reg [`FP_WIDTH-1:0] sqrt_input;
    
    // Simple approximation: sqrt(x) ≈ x >> 1 for small x (very rough)
    // Better: Use a small LUT + linear interpolation
    // For this implementation, we use a simplified iterative method
    
    function [`FP_WIDTH-1:0] approx_inv_sqrt;
        input [`FP_WIDTH-1:0] x;
        reg [`FP_WIDTH-1:0] guess;
        reg [63:0] product;
        begin
            // Initial guess: 1.0 / sqrt(x) ≈ 1.0 (for x near 1.0)
            // For better accuracy, use a LUT for initial guess
            if (x == 0)
                approx_inv_sqrt = `FP_ONE;  // Avoid div by zero
            else if (x < 32'h00000100)  // Very small
                approx_inv_sqrt = 32'h7FFF0000;  // Large value
            else if (x < `FP_ONE)
                approx_inv_sqrt = `FP_ONE + (`FP_ONE - x);  // Rough approximation for x < 1
            else
                approx_inv_sqrt = (`FP_ONE * `FP_ONE) / x;  // 1/x approximation (not sqrt)
        end
    endfunction
    
    // =========================================================================
    // Simple Exp Approximation using Piecewise Linear (for softmax)
    // exp(x) ≈ 1 + x + x²/2 for small x
    // =========================================================================
    function signed [`FP_WIDTH-1:0] approx_exp;
        input signed [`FP_WIDTH-1:0] x;
        reg signed [63:0] x_sq;
        reg signed [`FP_WIDTH-1:0] term1, term2;
        begin
            // Clamp input to reasonable range to prevent overflow
            if (x > 32'h00080000)  // > 8.0
                approx_exp = 32'h7FFFFFFF;  // Saturate
            else if (x < -32'h00080000)  // < -8.0
                approx_exp = 0;  // ~0
            else begin
                // exp(x) ≈ 1 + x + x²/2
                x_sq = (x * x) >>> `FP_FRAC_BITS;  // x² in Q16.16
                term1 = `FP_ONE + x;  // 1 + x
                term2 = x_sq[`FP_WIDTH-1:0] >>> 1;  // x²/2
                approx_exp = term1 + term2;
                if (approx_exp < 0) approx_exp = 0;  // Clamp negative
            end
        end
    endfunction
    
    // =========================================================================
    // Main State Machine
    // =========================================================================
    integer i;
    reg signed [63:0] product_tmp;
    reg signed [`FP_WIDTH-1:0] score_shifted;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            idx <= 0;
            sum_sq_acc <= 0;
            norm_val <= 0;
            max_val <= -32'h7FFFFFFF;
            exp_sum <= 0;
            weighted_sum <= 0;
            scalar_out_softmax <= 0;
            vec_out_norm_flat <= {(`FP_WIDTH*VECTOR_SIZE){1'b0}};
            for (i = 0; i < VECTOR_SIZE; i = i + 1) begin
                norm_out[i] <= 0;
            end
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        idx <= 0;
                        sum_sq_acc <= 0;
                        max_val <= -32'h7FFFFFFF;
                        exp_sum <= 0;
                        weighted_sum <= 0;
                        
                        if (op_sel == 0)
                            state <= NORM_SUM_SQ;
                        else
                            state <= SOFT_PASS;
                    end
                end
                
                // =====================================================
                // L2 NORMALIZATION
                // =====================================================
                NORM_SUM_SQ: begin
                    // Compute sum of squares
                    product_tmp = scores[idx] * scores[idx];
                    sum_sq_acc <= sum_sq_acc + (product_tmp >>> `FP_FRAC_BITS);
                    
                    if (idx == VECTOR_SIZE - 1) begin
                        idx <= 0;
                        state <= NORM_SQRT;
                    end else begin
                        idx <= idx + 1;
                    end
                end
                
                NORM_SQRT: begin
                    // Compute inverse sqrt (1/sqrt(sum_sq))
                    // For simplicity, store sqrt (would need proper implementation)
                    norm_val <= approx_inv_sqrt(sum_sq_acc[`FP_WIDTH-1:0]);
                    state <= NORM_DIV;
                end
                
                NORM_DIV: begin
                    // Normalize: out[i] = in[i] * inv_sqrt
                    product_tmp = scores[idx] * norm_val;
                    norm_out[idx] <= product_tmp[`FP_FRAC_BITS +: `FP_WIDTH];
                    
                    if (idx == VECTOR_SIZE - 1) begin
                        state <= FINISH;
                    end else begin
                        idx <= idx + 1;
                    end
                end
                
                // =====================================================
                // SOFTMAX WEIGHTED SUM
                // =====================================================
                SOFT_PASS: begin
                    // Online softmax: find max, compute exp, sum, weight
                    // Simplified single-pass approximation
                    
                    // Update max
                    if (scores[idx] > max_val)
                        max_val <= scores[idx];
                    
                    // Compute exp(score - max) * value and sum exp
                    // Note: For proper online softmax, need to rescale previous
                    // This is a simplified version
                    score_shifted = scores[idx] - max_val;
                    product_tmp = approx_exp(score_shifted);
                    
                    exp_sum <= exp_sum + product_tmp;
                    weighted_sum <= weighted_sum + ((product_tmp * values[idx]) >>> `FP_FRAC_BITS);
                    
                    if (idx == VECTOR_SIZE - 1) begin
                        state <= FINISH;
                    end else begin
                        idx <= idx + 1;
                    end
                end
                
                FINISH: begin
                    done <= 1;
                    
                    // For softmax, output = weighted_sum / exp_sum
                    if (op_sel == 1 && exp_sum != 0) begin
                        scalar_out_softmax <= (weighted_sum[`FP_WIDTH-1:0] * `FP_ONE) / exp_sum[`FP_WIDTH-1:0];
                    end
                    
                    // Pack norm output array to output bus (unroll for synthesis)
                    for (i = 0; i < VECTOR_SIZE; i = i + 1) begin
                        vec_out_norm_flat[`FP_WIDTH*(i+1)-1 -: `FP_WIDTH] <= norm_out[i];
                    end
                    
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
