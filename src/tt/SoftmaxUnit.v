/*
 * Copyright (c) 2024 TensorCore-FPGA Project
 * SPDX-License-Identifier: Apache-2.0
 *
 * INT8 Softmax Approximation Unit
 * - Online max tracking
 * - exp() via lookup table
 * - Fixed-point division approximation
 */

`default_nettype none

module softmax_unit #(
    parameter VECTOR_LEN = 4
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire        valid_in,
    input  wire signed [7:0] data_in,
    
    output reg         done,
    output reg         valid_out,
    output reg  [7:0]  prob_out  // Normalized probability (0-255 = 0.0-1.0)
);

    // States
    localparam IDLE    = 2'd0;
    localparam FIND_MAX = 2'd1;
    localparam COMPUTE = 2'd2;
    localparam OUTPUT  = 2'd3;
    
    reg [1:0] state;
    reg [2:0] idx;
    
    // Storage
    reg signed [7:0] values [0:VECTOR_LEN-1];
    reg signed [7:0] max_val;
    reg [15:0] exp_sum;
    reg [7:0]  exp_vals [0:VECTOR_LEN-1];
    
    // exp() LUT (approximate: exp(x) for x in [-8,0])
    // Index = (x + 8), scaled output 0-255
    function [7:0] exp_lut;
        input signed [7:0] x;
        reg signed [7:0] x_clamped;
        begin
            x_clamped = (x < -8) ? -8 : (x > 0) ? 0 : x;
            case (x_clamped)
                -8: exp_lut = 8'd1;
                -7: exp_lut = 8'd2;
                -6: exp_lut = 8'd6;
                -5: exp_lut = 8'd17;
                -4: exp_lut = 8'd46;
                -3: exp_lut = 8'd64;
                -2: exp_lut = 8'd94;
                -1: exp_lut = 8'd135;
                 0: exp_lut = 8'd255;
                default: exp_lut = 8'd1;
            endcase
        end
    endfunction
    
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 0;
            valid_out <= 0;
            idx <= 0;
            max_val <= -128;
            exp_sum <= 0;
        end else begin
            valid_out <= 0;
            done <= 0;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= FIND_MAX;
                        idx <= 0;
                        max_val <= -128;
                    end else if (valid_in) begin
                        values[idx] <= data_in;
                        idx <= idx + 1;
                    end
                end
                
                FIND_MAX: begin
                    if (idx < VECTOR_LEN) begin
                        if (values[idx] > max_val)
                            max_val <= values[idx];
                        idx <= idx + 1;
                    end else begin
                        state <= COMPUTE;
                        idx <= 0;
                        exp_sum <= 0;
                    end
                end
                
                COMPUTE: begin
                    if (idx < VECTOR_LEN) begin
                        exp_vals[idx] <= exp_lut(values[idx] - max_val);
                        exp_sum <= exp_sum + exp_lut(values[idx] - max_val);
                        idx <= idx + 1;
                    end else begin
                        state <= OUTPUT;
                        idx <= 0;
                    end
                end
                
                OUTPUT: begin
                    if (idx < VECTOR_LEN) begin
                        // Approximate division: (exp_val * 256) / exp_sum
                        prob_out <= (exp_vals[idx] << 8) / (exp_sum[15:0] + 1);
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
