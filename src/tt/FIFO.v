/*
 * Copyright (c) 2024 TensorCore-FPGA Project
 * SPDX-License-Identifier: Apache-2.0
 *
 * Synchronous FIFO Buffer
 * - 8-entry x 8-bit data staging
 * - Full/empty flags
 */

`default_nettype none

module fifo_sync #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    
    // Write interface
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  full,
    
    // Read interface
    input  wire                  rd_en,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire                  empty,
    
    // Status
    output wire [$clog2(DEPTH):0] count
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr;
    reg [$clog2(DEPTH)-1:0] rd_ptr;
    reg [$clog2(DEPTH):0]   fifo_count;
    
    assign full  = (fifo_count == DEPTH);
    assign empty = (fifo_count == 0);
    assign count = fifo_count;
    assign rd_data = mem[rd_ptr];
    
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= wr_data;
            wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
        end
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
        end
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            fifo_count <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: fifo_count <= fifo_count + 1;
                2'b01: fifo_count <= fifo_count - 1;
                default: fifo_count <= fifo_count;
            endcase
        end
    end

endmodule
