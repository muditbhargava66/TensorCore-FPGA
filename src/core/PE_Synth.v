`include "fixed_point_pkg.vh"

/**
 * @module PE_Synth (Processing Element - Synthesizable)
 * @brief Synthesizable fixed-point PE for FPGA/ASIC implementation.
 *
 * Performs MAC (Multiply-Accumulate) operations using Q16.16 fixed-point.
 * Supports:
 * - Weight Stationary (WS): Preload weight, stream activations
 * - Output Stationary (OS): Stream both inputs, accumulate in place
 *
 * @note This replaces the behavioral PE.v for synthesis targets.
 */
module PE_Synth (
    input  wire                        clk,
    input  wire                        reset,
    input  wire                        output_stationary,
    input  wire signed [`FP_WIDTH-1:0] in_top,
    input  wire signed [`FP_WIDTH-1:0] in_left,
    output reg  signed [`FP_WIDTH-1:0] out_right,
    output reg  signed [`FP_WIDTH-1:0] out_bottom,
    input  wire                        preload_valid,
    input  wire signed [`FP_WIDTH-1:0] preload_data
);

    // Internal registers
    reg signed [`FP_WIDTH-1:0]     weight_reg;      // Stationary weight (WS mode)
    reg signed [`MAC_ACC_WIDTH-1:0] accumulator;    // Extended precision accumulator
    reg                             drain_phase;
    
    // MAC computation (combinational)
    wire signed [63:0] product;
    wire signed [`MAC_ACC_WIDTH-1:0] product_scaled;
    
    // Select operands based on mode
    wire signed [`FP_WIDTH-1:0] mul_a;
    wire signed [`FP_WIDTH-1:0] mul_b;
    
    assign mul_a = output_stationary ? in_left : in_left;
    assign mul_b = output_stationary ? in_top  : weight_reg;
    
    // Fixed-point multiplication
    assign product = mul_a * mul_b;
    assign product_scaled = product[`FP_FRAC_BITS +: `MAC_ACC_WIDTH];
    
    // Main sequential logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            weight_reg   <= 0;
            accumulator  <= 0;
            out_right    <= 0;
            out_bottom   <= 0;
            drain_phase  <= 0;
        end else begin
            
            if (output_stationary) begin
                // =============================================
                // OUTPUT STATIONARY MODE
                // =============================================
                // Accumulate products in place
                // Drain accumulated values when preload_valid
                
                if (preload_valid) begin
                    // Drain phase: output accumulated value, then reset
                    if (!drain_phase) begin
                        out_bottom <= accumulator[`FP_WIDTH-1:0];
                        drain_phase <= 1;
                    end else begin
                        out_bottom <= in_top;  // Pass through
                    end
                    out_right <= 0;
                    accumulator <= 0;
                end else begin
                    // Compute phase
                    accumulator <= accumulator + product_scaled;
                    out_right   <= in_left;    // Pass activation right
                    out_bottom  <= in_top;     // Pass weight down
                    drain_phase <= 0;
                end
                
            end else begin
                // =============================================
                // WEIGHT STATIONARY MODE
                // =============================================
                // Weight is preloaded and stays stationary
                // Activations flow through, partial sums accumulate vertically
                
                if (preload_valid) begin
                    // Preload weight
                    weight_reg <= preload_data;
                end
                
                // Compute: out = in_top + (in_left * weight)
                // in_top carries partial sum from above
                accumulator <= {{(`MAC_ACC_WIDTH-`FP_WIDTH){in_top[`FP_WIDTH-1]}}, in_top} + product_scaled;
                
                // Output: partial sum goes down, activation goes right
                out_bottom <= accumulator[`FP_WIDTH-1:0];
                out_right  <= in_left;
            end
        end
    end

endmodule
