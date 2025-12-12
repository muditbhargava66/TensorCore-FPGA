`include "fixed_point_pkg.vh"

/**
 * @module MAC (Multiply-Accumulate Unit)
 * @brief Synthesizable fixed-point MAC for systolic array.
 *
 * Performs: accumulator = accumulator + (a * b)
 * Uses Q16.16 fixed-point format.
 * 
 * Pipeline: 1 cycle (combinational multiply, registered accumulate)
 *
 * @note For higher clock frequencies, add pipeline registers to the multiplier.
 */
module MAC (
    input  wire                        clk,
    input  wire                        reset,
    input  wire                        clear,      // Clear accumulator
    input  wire                        enable,     // Enable accumulation
    input  wire signed [`FP_WIDTH-1:0] a,          // Multiplicand (Q16.16)
    input  wire signed [`FP_WIDTH-1:0] b,          // Multiplier (Q16.16)
    output reg  signed [`FP_WIDTH-1:0] result      // Result (Q16.16, truncated)
);

    // Internal accumulator with extended precision to prevent overflow
    // 32-bit * 32-bit = 64-bit product, but we only need 48 bits for reasonable accumulation
    reg signed [`MAC_ACC_WIDTH-1:0] accumulator;
    
    // Full precision product (64-bit)
    wire signed [63:0] product_full;
    
    // Truncated product back to Q16.16 (take middle 32 bits of 64)
    // After multiplying two Q16.16 numbers, result is Q32.32
    // We need to shift right by 16 to get back to Q16.16
    wire signed [`MAC_ACC_WIDTH-1:0] product_scaled;
    
    // Multiplication
    assign product_full = a * b;
    
    // Scale back to Q16.16 by taking bits [47:16] of 64-bit result
    // This gives us Q16.16 with proper fractional alignment
    assign product_scaled = product_full[`FP_FRAC_BITS +: `MAC_ACC_WIDTH];
    
    // Accumulation logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            accumulator <= 0;
        end else if (clear) begin
            accumulator <= 0;
        end else if (enable) begin
            accumulator <= accumulator + product_scaled;
        end
    end
    
    // Output: truncate accumulator to 32-bit Q16.16
    // Saturate if overflow (optional, can be removed for speed)
    always @(*) begin
        // Simple truncation (no saturation)
        result = accumulator[`FP_WIDTH-1:0];
    end

endmodule

/**
 * @module MAC_Pipelined
 * @brief 2-stage pipelined MAC for higher clock frequencies.
 *
 * Stage 1: Multiply
 * Stage 2: Accumulate
 *
 * Latency: 2 cycles
 * Throughput: 1 MAC/cycle after pipeline is full
 */
module MAC_Pipelined (
    input  wire                        clk,
    input  wire                        reset,
    input  wire                        clear,
    input  wire                        enable,
    input  wire signed [`FP_WIDTH-1:0] a,
    input  wire signed [`FP_WIDTH-1:0] b,
    output reg  signed [`FP_WIDTH-1:0] result
);

    // Pipeline registers
    reg signed [63:0] product_reg;
    reg               enable_reg;
    
    // Accumulator
    reg signed [`MAC_ACC_WIDTH-1:0] accumulator;
    
    // Stage 1: Multiply (registered)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            product_reg <= 0;
            enable_reg  <= 0;
        end else begin
            product_reg <= a * b;
            enable_reg  <= enable;
        end
    end
    
    // Stage 2: Accumulate
    wire signed [`MAC_ACC_WIDTH-1:0] product_scaled;
    assign product_scaled = product_reg[`FP_FRAC_BITS +: `MAC_ACC_WIDTH];
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            accumulator <= 0;
        end else if (clear) begin
            accumulator <= 0;
        end else if (enable_reg) begin
            accumulator <= accumulator + product_scaled;
        end
    end
    
    // Output
    always @(*) begin
        result = accumulator[`FP_WIDTH-1:0];
    end

endmodule
