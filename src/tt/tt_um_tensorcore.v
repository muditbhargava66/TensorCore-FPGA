/*
 * Copyright (c) 2024 TensorCore-FPGA Project
 * SPDX-License-Identifier: Apache-2.0
 *
 * TinyTapeout Top Module - TensorCore 2x2 Systolic Array
 * 
 * Features:
 * - 2x2 Systolic Array (4 MAC units)
 * - Weight stationary dataflow
 * - 8-bit signed arithmetic with saturation
 * - Streaming activation input
 * - 50 MHz target frequency
 *
 * Pin Mapping:
 *   ui_in[7:0]  - Data input (row select + activation data)
 *                 ui_in[7:6]: Mode/Row select
 *                 ui_in[5:0]: Data (6-bit, sign-extended to 8-bit)
 *   uio_in[7:0] - Weight input (col select + weight data)
 *                 uio_in[7:6]: Column select
 *                 uio_in[5:0]: Weight (6-bit, sign-extended to 8-bit)
 *   uo_out[7:0] - Result output (selected PE result)
 *   
 *   uio_out[3:0] - Overflow flags for PEs
 *   uio_out[5:4] - Selected PE indicator
 *   uio_out[7:6] - Status
 */

`default_nettype none

module tt_um_tensorcore (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (1=output)
    input  wire       ena,      // always 1 when design powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // =========================================================================
    // Signal Declarations
    // =========================================================================
    
    // Buffered control signals to reduce fanout
    (* max_fanout = 4 *) reg        enable_buf;
    (* max_fanout = 4 *) reg        clear_acc_buf;
    (* max_fanout = 4 *) reg        load_weights_buf;
    
    // Control state
    reg [1:0] state;
    localparam IDLE        = 2'b00;
    localparam LOAD_WEIGHT = 2'b01;
    localparam COMPUTE     = 2'b10;
    localparam READOUT     = 2'b11;
    
    // Input parsing
    wire [1:0] ui_mode   = ui_in[7:6];
    wire [5:0] ui_data   = ui_in[5:0];
    wire [1:0] uio_sel   = uio_in[7:6];
    wire [5:0] uio_data  = uio_in[5:0];
    
    // Sign-extended inputs
    wire signed [7:0] data_ext   = {{2{ui_data[5]}}, ui_data};
    wire signed [7:0] weight_ext = {{2{uio_data[5]}}, uio_data};
    
    // Mode definitions
    localparam MODE_NOP         = 2'b00;
    localparam MODE_CLEAR       = 2'b01;
    localparam MODE_LOAD_WEIGHT = 2'b10;
    localparam MODE_COMPUTE     = 2'b11;
    
    // Edge detection
    reg [1:0] ui_mode_prev;
    wire mode_edge = (ui_mode != ui_mode_prev);
    
    always @(posedge clk) begin
        if (!rst_n) begin
            ui_mode_prev <= 2'b00;
        end else begin
            ui_mode_prev <= ui_mode;
        end
    end
    
    // Control signal generation with buffering
    always @(posedge clk) begin
        if (!rst_n) begin
            enable_buf       <= 1'b0;
            clear_acc_buf    <= 1'b0;
            load_weights_buf <= 1'b0;
            state            <= IDLE;
        end else begin
            // Default
            clear_acc_buf    <= 1'b0;
            load_weights_buf <= 1'b0;
            
            case (ui_mode)
                MODE_NOP: begin
                    enable_buf <= 1'b0;
                    state <= IDLE;
                end
                
                MODE_CLEAR: begin
                    if (mode_edge) begin
                        clear_acc_buf <= 1'b1;
                    end
                    enable_buf <= 1'b1;
                    state <= IDLE;
                end
                
                MODE_LOAD_WEIGHT: begin
                    if (mode_edge) begin
                        load_weights_buf <= 1'b1;
                    end
                    enable_buf <= 1'b1;
                    state <= LOAD_WEIGHT;
                end
                
                MODE_COMPUTE: begin
                    enable_buf <= 1'b1;
                    state <= COMPUTE;
                end
            endcase
        end
    end
    
    // =========================================================================
    // Data routing for 2x2 array
    // =========================================================================
    
    // Select which row/column gets the input
    reg signed [7:0] data_row0, data_row1;
    reg signed [7:0] weight_col0, weight_col1;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            data_row0   <= 8'd0;
            data_row1   <= 8'd0;
            weight_col0 <= 8'd0;
            weight_col1 <= 8'd0;
        end else if (enable_buf) begin
            // Route activation based on ui_in[6] (row select)
            if (ui_in[6]) begin
                data_row1 <= data_ext;
            end else begin
                data_row0 <= data_ext;
            end
            
            // Route weight based on uio_in[6] (col select)
            if (uio_in[6]) begin
                weight_col1 <= weight_ext;
            end else begin
                weight_col0 <= weight_ext;
            end
        end
    end
    
    // =========================================================================
    // 2x2 Systolic Array Instance
    // =========================================================================
    
    wire signed [7:0] result_00, result_01, result_10, result_11;
    wire [3:0] overflow_flags;
    
    systolic_2x2 array_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable_buf),
        .clear_acc(clear_acc_buf),
        .load_weights(load_weights_buf),
        .data_row0(data_row0),
        .data_row1(data_row1),
        .weight_col0(weight_col0),
        .weight_col1(weight_col1),
        .result_00(result_00),
        .result_01(result_01),
        .result_10(result_10),
        .result_11(result_11),
        .overflow_flags(overflow_flags)
    );
    
    // =========================================================================
    // Output Multiplexing
    // =========================================================================
    
    // Select result based on uio_in[7:6]
    reg signed [7:0] selected_result;
    
    always @(*) begin
        case (uio_sel)
            2'b00: selected_result = result_00;
            2'b01: selected_result = result_01;
            2'b10: selected_result = result_10;
            2'b11: selected_result = result_11;
        endcase
    end
    
    // =========================================================================
    // Output Assignments
    // =========================================================================
    
    assign uo_out = selected_result;
    
    assign uio_out[3:0] = overflow_flags;
    assign uio_out[5:4] = uio_sel;
    assign uio_out[7:6] = state;
    
    assign uio_oe = 8'b11111111;
    
    // Unused inputs
    wire _unused = &{ena, 1'b0};

endmodule
