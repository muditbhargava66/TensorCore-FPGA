/*
 * Copyright (c) 2024 TensorCore-FPGA Project
 * SPDX-License-Identifier: Apache-2.0
 *
 * 4x4 Systolic Array for TinyTapeout (16 MACs)
 */

`default_nettype none

module systolic_4x4 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    (* max_fanout = 4 *) input wire clear_acc,
    (* max_fanout = 4 *) input wire load_weights,
    input  wire signed [7:0] data_row0, data_row1, data_row2, data_row3,
    input  wire signed [7:0] weight_col0, weight_col1, weight_col2, weight_col3,
    output wire signed [7:0] result_00, result_01, result_02, result_03,
    output wire signed [7:0] result_10, result_11, result_12, result_13,
    output wire signed [7:0] result_20, result_21, result_22, result_23,
    output wire signed [7:0] result_30, result_31, result_32, result_33,
    output wire [15:0] overflow_flags
);
    // Control buffering
    (* max_fanout = 4 *) reg clear_r0, clear_r1, load_r0, load_r1;
    always @(posedge clk) begin
        if (!rst_n) begin clear_r0<=0; clear_r1<=0; load_r0<=0; load_r1<=0; end
        else begin clear_r0<=clear_acc; clear_r1<=clear_acc; load_r0<=load_weights; load_r1<=load_weights; end
    end

    // Data wires
    wire signed [7:0] d0_01, d0_12, d0_23, d1_01, d1_12, d1_23, d2_01, d2_12, d2_23, d3_01, d3_12, d3_23;
    wire signed [7:0] w0_01, w0_12, w0_23, w1_01, w1_12, w1_23, w2_01, w2_12, w2_23, w3_01, w3_12, w3_23;

    // Row 0
    pe_enhanced pe_00 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r0),.load_weight(load_r0),.data_in(data_row0),.weight_in(weight_col0),.data_out(d0_01),.weight_out(w0_01),.acc_out(result_00),.overflow(overflow_flags[0]));
    pe_enhanced pe_01 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r0),.load_weight(load_r0),.data_in(d0_01),.weight_in(weight_col1),.data_out(d0_12),.weight_out(w1_01),.acc_out(result_01),.overflow(overflow_flags[1]));
    pe_enhanced pe_02 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r1),.load_weight(load_r1),.data_in(d0_12),.weight_in(weight_col2),.data_out(d0_23),.weight_out(w2_01),.acc_out(result_02),.overflow(overflow_flags[2]));
    pe_enhanced pe_03 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r1),.load_weight(load_r1),.data_in(d0_23),.weight_in(weight_col3),.data_out(),.weight_out(w3_01),.acc_out(result_03),.overflow(overflow_flags[3]));
    
    // Row 1
    pe_enhanced pe_10 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r0),.load_weight(load_r0),.data_in(data_row1),.weight_in(w0_01),.data_out(d1_01),.weight_out(w0_12),.acc_out(result_10),.overflow(overflow_flags[4]));
    pe_enhanced pe_11 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r0),.load_weight(load_r0),.data_in(d1_01),.weight_in(w1_01),.data_out(d1_12),.weight_out(w1_12),.acc_out(result_11),.overflow(overflow_flags[5]));
    pe_enhanced pe_12 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r1),.load_weight(load_r1),.data_in(d1_12),.weight_in(w2_01),.data_out(d1_23),.weight_out(w2_12),.acc_out(result_12),.overflow(overflow_flags[6]));
    pe_enhanced pe_13 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r1),.load_weight(load_r1),.data_in(d1_23),.weight_in(w3_01),.data_out(),.weight_out(w3_12),.acc_out(result_13),.overflow(overflow_flags[7]));
    
    // Row 2
    pe_enhanced pe_20 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r0),.load_weight(load_r0),.data_in(data_row2),.weight_in(w0_12),.data_out(d2_01),.weight_out(w0_23),.acc_out(result_20),.overflow(overflow_flags[8]));
    pe_enhanced pe_21 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r0),.load_weight(load_r0),.data_in(d2_01),.weight_in(w1_12),.data_out(d2_12),.weight_out(w1_23),.acc_out(result_21),.overflow(overflow_flags[9]));
    pe_enhanced pe_22 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r1),.load_weight(load_r1),.data_in(d2_12),.weight_in(w2_12),.data_out(d2_23),.weight_out(w2_23),.acc_out(result_22),.overflow(overflow_flags[10]));
    pe_enhanced pe_23 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r1),.load_weight(load_r1),.data_in(d2_23),.weight_in(w3_12),.data_out(),.weight_out(w3_23),.acc_out(result_23),.overflow(overflow_flags[11]));
    
    // Row 3
    pe_enhanced pe_30 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r0),.load_weight(load_r0),.data_in(data_row3),.weight_in(w0_23),.data_out(d3_01),.weight_out(),.acc_out(result_30),.overflow(overflow_flags[12]));
    pe_enhanced pe_31 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r0),.load_weight(load_r0),.data_in(d3_01),.weight_in(w1_23),.data_out(d3_12),.weight_out(),.acc_out(result_31),.overflow(overflow_flags[13]));
    pe_enhanced pe_32 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r1),.load_weight(load_r1),.data_in(d3_12),.weight_in(w2_23),.data_out(d3_23),.weight_out(),.acc_out(result_32),.overflow(overflow_flags[14]));
    pe_enhanced pe_33 (.clk(clk),.rst_n(rst_n),.enable(enable),.clear_acc(clear_r1),.load_weight(load_r1),.data_in(d3_23),.weight_in(w3_23),.data_out(),.weight_out(),.acc_out(result_33),.overflow(overflow_flags[15]));

endmodule
