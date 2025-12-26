/*
 * Copyright (c) 2024 TensorCore-FPGA Project
 * SPDX-License-Identifier: Apache-2.0
 *
 * 2x2 Mini Systolic Array for TinyTapeout
 * 
 * Architecture:
 *   [PE(0,0)] ---> [PE(0,1)]
 *      |             |
 *      v             v
 *   [PE(1,0)] ---> [PE(1,1)]
 *
 * Data flows: 
 *   - Activations flow left-to-right
 *   - Weights flow top-to-bottom
 *   - Results accumulate in each PE
 */

`default_nettype none

module systolic_2x2 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    
    // Control
    input  wire        clear_acc,     // Clear all accumulators
    input  wire        load_weights,  // Load weights from weight_in
    
    // Data inputs (2 rows x 2 cols)
    input  wire signed [7:0] data_row0,    // Activation for row 0
    input  wire signed [7:0] data_row1,    // Activation for row 1
    input  wire signed [7:0] weight_col0,  // Weight for column 0
    input  wire signed [7:0] weight_col1,  // Weight for column 1
    
    // Result outputs (4 PEs)
    output wire signed [7:0] result_00,
    output wire signed [7:0] result_01,
    output wire signed [7:0] result_10,
    output wire signed [7:0] result_11,
    
    // Status
    output wire [3:0]        overflow_flags  // Overflow from each PE
);

    // Internal wires for systolic connections
    wire signed [7:0] data_00_to_01;
    wire signed [7:0] data_10_to_11;
    wire signed [7:0] weight_00_to_10;
    wire signed [7:0] weight_01_to_11;
    
    // PE (0,0) - Top Left
    pe_enhanced pe_00 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .clear_acc(clear_acc),
        .load_weight(load_weights),
        .data_in(data_row0),
        .weight_in(weight_col0),
        .data_out(data_00_to_01),
        .weight_out(weight_00_to_10),
        .acc_out(result_00),
        .overflow(overflow_flags[0])
    );
    
    // PE (0,1) - Top Right
    pe_enhanced pe_01 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .clear_acc(clear_acc),
        .load_weight(load_weights),
        .data_in(data_00_to_01),
        .weight_in(weight_col1),
        .data_out(),  // End of row
        .weight_out(weight_01_to_11),
        .acc_out(result_01),
        .overflow(overflow_flags[1])
    );
    
    // PE (1,0) - Bottom Left
    pe_enhanced pe_10 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .clear_acc(clear_acc),
        .load_weight(load_weights),
        .data_in(data_row1),
        .weight_in(weight_00_to_10),
        .data_out(data_10_to_11),
        .weight_out(),  // End of column
        .acc_out(result_10),
        .overflow(overflow_flags[2])
    );
    
    // PE (1,1) - Bottom Right
    pe_enhanced pe_11 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .clear_acc(clear_acc),
        .load_weight(load_weights),
        .data_in(data_10_to_11),
        .weight_in(weight_01_to_11),
        .data_out(),  // End of row
        .weight_out(),  // End of column
        .acc_out(result_11),
        .overflow(overflow_flags[3])
    );

endmodule
