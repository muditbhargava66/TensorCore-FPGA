/*
 * Copyright (c) 2024 TensorCore-FPGA Project
 * SPDX-License-Identifier: Apache-2.0
 *
 * VPU Mini - Minimal Vector Processing Unit for TinyTapeout
 * - L2 Norm approximation
 * - Integrates Softmax
 * - INT8 operations
 */

`default_nettype none

module vpu_mini #(
    parameter VECTOR_LEN = 4
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [1:0]  op_sel,  // 0: PassThru, 1: L2Norm, 2: Softmax, 3: ReLU
    
    // Input interface
    input  wire        valid_in,
    input  wire signed [7:0] data_in,
    
    // Output interface
    output reg         valid_out,
    output reg  [7:0]  data_out,
    output reg         done
);

    // States
    localparam IDLE     = 2'd0;
    localparam LOAD     = 2'd1;
    localparam PROCESS  = 2'd2;
    localparam OUTPUT   = 2'd3;
    
    reg [1:0] state;
    reg [2:0] idx;
    
    // Storage
    reg signed [7:0] values [0:VECTOR_LEN-1];
    reg [15:0] sum_sq;
    reg [7:0]  norm_factor;
    
    // L2 Norm approximation: sqrt via lookup (for denominator)
    function [7:0] sqrt_lut;
        input [15:0] x;
        begin
            if (x < 16) sqrt_lut = 8'd4;
            else if (x < 64) sqrt_lut = 8'd8;
            else if (x < 256) sqrt_lut = 8'd16;
            else if (x < 1024) sqrt_lut = 8'd32;
            else if (x < 4096) sqrt_lut = 8'd64;
            else if (x < 16384) sqrt_lut = 8'd128;
            else sqrt_lut = 8'd255;
        end
    endfunction
    
    // ReLU function
    function [7:0] relu;
        input signed [7:0] x;
        begin
            relu = (x < 0) ? 8'd0 : x;
        end
    endfunction
    
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
            valid_out <= 0;
            idx <= 0;
            sum_sq <= 0;
        end else begin
            valid_out <= 0;
            done <= 0;
            
            case (state)
                IDLE: begin
                    idx <= 0;
                    sum_sq <= 0;
                    if (valid_in) begin
                        values[0] <= data_in;
                        idx <= 1;
                        state <= LOAD;
                    end
                end
                
                LOAD: begin
                    if (valid_in) begin
                        values[idx] <= data_in;
                        if (idx == VECTOR_LEN - 1)
                            state <= PROCESS;
                        else
                            idx <= idx + 1;
                    end
                end
                
                PROCESS: begin
                    case (op_sel)
                        2'd0: begin  // PassThru
                            state <= OUTPUT;
                            idx <= 0;
                        end
                        2'd1: begin  // L2 Norm
                            // Compute sum of squares
                            sum_sq <= values[0]*values[0] + values[1]*values[1] + 
                                     values[2]*values[2] + values[3]*values[3];
                            norm_factor <= sqrt_lut(sum_sq);
                            state <= OUTPUT;
                            idx <= 0;
                        end
                        2'd2: begin  // Softmax (simplified - max subtraction)
                            state <= OUTPUT;
                            idx <= 0;
                        end
                        2'd3: begin  // ReLU
                            state <= OUTPUT;
                            idx <= 0;
                        end
                    endcase
                end
                
                OUTPUT: begin
                    if (idx < VECTOR_LEN) begin
                        case (op_sel)
                            2'd0: data_out <= values[idx];  // PassThru
                            2'd1: data_out <= (values[idx] << 4) / (norm_factor + 1);  // L2 Norm
                            2'd2: data_out <= values[idx];  // Placeholder for softmax
                            2'd3: data_out <= relu(values[idx]);  // ReLU
                        endcase
                        valid_out <= 1;
                        idx <= idx + 1;
                    end else begin
                        state <= IDLE;
                        done <= 1;
                    end
                end
            endcase
        end
    end

endmodule
