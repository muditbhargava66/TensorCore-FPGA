/**
 * @module VPU (Vector Processing Unit)
 * @brief Handles non-linear vector operations for the accelerator.
 * 
 * Supports two main operations:
 * 1. L2 Normalization (Op 0)
 * 2. Softmax Weighted Sum (Op 1) - FlashAttention style
 *
 * NOTE: Uses 'real' types for behavioral simulation. Not synthesizable as-is.
 */
module VPU #(
    parameter VECTOR_SIZE = 32
)(
    input wire clk,
    input wire reset,
    input wire start,
    output reg done,
    input wire op_sel, // 0: Norm, 1: Softmax-Sum
    
    // Inputs
    input wire [63:0] vec_in_scores_flat [0:VECTOR_SIZE-1],
    input wire [63:0] vec_in_values_flat [0:VECTOR_SIZE-1],
    
    // Outputs
    output reg [63:0] vec_out_norm_flat [0:VECTOR_SIZE-1],
    output reg [63:0] scalar_out_softmax
);

    // Internal Real Buffers
    real scores [0:VECTOR_SIZE-1];
    real values [0:VECTOR_SIZE-1];
    real norm_out [0:VECTOR_SIZE-1];
    
    real sum_sq, norm, d_i, m_i, o_i;
    real m_prev, d_prev, o_prev;
    real x_i, v_i, exp_val_m, exp_val_x;
    
    integer i;

    // Main Processing Block
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            done <= 1'b0;
            scalar_out_softmax <= 64'h0;
            for (i=0; i<VECTOR_SIZE; i=i+1) begin
                vec_out_norm_flat[i] <= 64'h0;
            end
        end else begin
            if (start) begin
                done <= 1'b0;
                
                // Convert inputs to real
                for (i=0; i<VECTOR_SIZE; i=i+1) begin
                    scores[i] = $bitstoreal(vec_in_scores_flat[i]);
                    values[i] = $bitstoreal(vec_in_values_flat[i]);
                end
                
                if (op_sel == 1'b0) begin
                    // --- Operation 0: L2 Normalization ---
                    sum_sq = 0;
                    
                    // 1. Calculate Sum of Squares
                    for (i=0; i<VECTOR_SIZE; i=i+1) begin
                        sum_sq = sum_sq + (scores[i] * scores[i]);
                    end
                    
                    // 2. Calculate Norm
                    norm = $sqrt(sum_sq);
                    
                    // 3. Normalize
                    for (i=0; i<VECTOR_SIZE; i=i+1) begin
                        if (norm != 0) begin
                            norm_out[i] = scores[i] / norm;
                        end else begin
                            norm_out[i] = 0;
                        end
                        vec_out_norm_flat[i] <= $realtobits(norm_out[i]);
                    end
                    
                    done <= 1'b1;
                    
                end else begin
                    // --- Operation 1: Softmax Weighted Sum (Safe Online Version) ---
                    // Algorithm based on FlashAttention paper
                    
                    m_i = -1.0e300; // Negative Infinity approximation
                    d_i = 0;
                    o_i = 0;
                    
                    for (i=0; i<VECTOR_SIZE; i=i+1) begin
                        x_i = scores[i];
                        v_i = values[i];
                        
                        m_prev = m_i;
                        d_prev = d_i;
                        o_prev = o_i;
                        
                        // Update Max
                        if (x_i > m_i) m_i = x_i;
                        
                        // Compute Exponentials
                        // exp(m_prev - m_i) handles the scaling when max changes
                        exp_val_m = $exp(m_prev - m_i);
                        exp_val_x = $exp(x_i - m_i);
                        
                        // Update Denominator (Sum of Exps)
                        d_i = (d_prev * exp_val_m) + exp_val_x;
                        
                        // Update Numerator (Weighted Sum)
                        o_i = (o_prev * exp_val_m) + (exp_val_x * v_i);
                    end
                    
                    // Final Division
                    if (d_i != 0) begin
                        scalar_out_softmax <= $realtobits(o_i / d_i);
                    end else begin
                        scalar_out_softmax <= 64'h0;
                    end
                    
                    done <= 1'b1;
                end
            end else begin
                // Reset done when start is low
                done <= 1'b0;
            end
        end
    end

endmodule
