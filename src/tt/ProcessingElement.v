/*
 * Copyright (c) 2024 TensorCore-FPGA Project
 * SPDX-License-Identifier: Apache-2.0
 *
 * Enhanced Processing Element for TinyTapeout
 * Features:
 * - 8-bit signed MAC (Multiply-Accumulate)
 * - Systolic data flow (pass-through for array connectivity)
 * - Pipeline registers for timing
 * - Saturation arithmetic with overflow detection
 */

`default_nettype none

module pe_enhanced (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    
    // Control
    input  wire        clear_acc,    // Clear accumulator
    input  wire        load_weight,  // Load weight register
    
    // Systolic data inputs
    input  wire signed [7:0] data_in,     // Activation from left
    input  wire signed [7:0] weight_in,   // Weight from top (or preload)
    
    // Systolic data outputs (for array connectivity)
    output reg  signed [7:0] data_out,    // Activation to right
    output reg  signed [7:0] weight_out,  // Weight to bottom
    
    // Result outputs
    output reg  signed [7:0] acc_out,     // Accumulated result (saturated)
    output wire              overflow     // Overflow indicator
);

    // Internal registers
    (* max_fanout = 8 *) reg signed [7:0]  weight_reg;    // Stationary weight
    reg signed [15:0] accumulator;   // Extended precision accumulator
    
    // MAC computation
    wire signed [15:0] product;
    wire signed [16:0] acc_next;
    
    assign product = data_in * weight_reg;
    assign acc_next = {accumulator[15], accumulator} + {product[15], product};
    
    // Overflow detection
    assign overflow = (acc_next[16] != acc_next[15]);
    
    // Saturation logic for 8-bit output
    wire signed [7:0] saturated;
    assign saturated = (accumulator > 16'sd127)  ? 8'sd127 :
                       (accumulator < -16'sd128) ? -8'sd128 :
                       accumulator[7:0];
    
    always @(posedge clk) begin
        if (!rst_n) begin
            weight_reg  <= 8'd0;
            accumulator <= 16'd0;
            acc_out     <= 8'd0;
            data_out    <= 8'd0;
            weight_out  <= 8'd0;
        end else if (enable) begin
            // Weight loading
            if (load_weight) begin
                weight_reg <= weight_in;
            end
            
            // Accumulator control
            if (clear_acc) begin
                accumulator <= 16'd0;
            end else begin
                // Accumulate with saturation
                if (overflow) begin
                    accumulator <= acc_next[16] ? -16'sd32768 : 16'sd32767;
                end else begin
                    accumulator <= acc_next[15:0];
                end
            end
            
            // Systolic data flow - pass through with register
            data_out   <= data_in;
            weight_out <= weight_in;
            
            // Update output register
            acc_out <= saturated;
        end
    end

endmodule
