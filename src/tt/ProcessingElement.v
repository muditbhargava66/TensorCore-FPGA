/*
 * Copyright (c) 2024 TensorCore-FPGA Project
 * SPDX-License-Identifier: Apache-2.0
 *
 * Enhanced Processing Element for TinyTapeout
 * 
 * Features:
 * - 8-bit signed MAC (Multiply-Accumulate)
 * - 24-bit internal accumulator for extended precision
 * - Weight double-buffering for overlapped loading
 * - Systolic data flow with pipeline registers
 * - Saturation arithmetic with overflow detection
 * - INT8 quantization support
 */

`default_nettype none

module pe_enhanced (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    
    // Control
    input  wire        clear_acc,      // Clear accumulator
    input  wire        load_weight,    // Load weight register
    
    // Systolic data inputs
    input  wire signed [7:0] data_in,     // Activation from left
    input  wire signed [7:0] weight_in,   // Weight from top (or preload)
    
    // Systolic data outputs (for array connectivity)
    output reg  signed [7:0] data_out,    // Activation to right
    output reg  signed [7:0] weight_out,  // Weight to bottom
    
    // Result outputs
    output reg  signed [7:0] acc_out,     // Accumulated result (saturated to INT8)
    output wire              overflow     // Overflow indicator
);

    // =========================================================================
    // Weight Double-Buffering
    // =========================================================================
    (* max_fanout = 8 *) reg signed [7:0] weight_active;   // Active weight
    (* max_fanout = 8 *) reg signed [7:0] weight_shadow;   // Shadow for preload
    reg weight_pending;
    
    // =========================================================================
    // 24-bit Accumulator (extended precision for many accumulations)
    // =========================================================================
    reg signed [23:0] accumulator;
    
    // MAC computation
    wire signed [15:0] product;
    wire signed [24:0] acc_next;
    
    assign product = data_in * weight_active;
    assign acc_next = {accumulator[23], accumulator} + {{9{product[15]}}, product};
    
    // =========================================================================
    // Overflow Detection
    // =========================================================================
    assign overflow = (acc_next[24] != acc_next[23]);
    
    // =========================================================================
    // INT8 Saturation Logic
    // =========================================================================
    wire signed [7:0] saturated;
    assign saturated = (accumulator > 24'sd127)  ? 8'sd127 :
                       (accumulator < -24'sd128) ? -8'sd128 :
                       accumulator[7:0];
    
    // =========================================================================
    // Sequential Logic
    // =========================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            weight_active <= 8'd0;
            weight_shadow <= 8'd0;
            weight_pending <= 1'b0;
            accumulator <= 24'd0;
            acc_out <= 8'd0;
            data_out <= 8'd0;
            weight_out <= 8'd0;
        end else if (enable) begin
            // Weight loading with double-buffering
            if (load_weight) begin
                weight_shadow <= weight_in;
                weight_pending <= 1'b1;
            end
            
            // Swap shadow to active when clearing accumulator (new tile)
            if (clear_acc && weight_pending) begin
                weight_active <= weight_shadow;
                weight_pending <= 1'b0;
            end else if (load_weight && !weight_pending) begin
                // Direct load if no pending
                weight_active <= weight_in;
            end
            
            // Accumulator control
            if (clear_acc) begin
                accumulator <= 24'd0;
            end else begin
                // MAC with saturation on overflow
                if (overflow) begin
                    accumulator <= acc_next[24] ? -24'sd8388608 : 24'sd8388607;
                end else begin
                    accumulator <= acc_next[23:0];
                end
            end
            
            // Systolic data flow
            data_out <= data_in;
            weight_out <= weight_in;
            
            // Output register
            acc_out <= saturated;
        end
    end

endmodule
