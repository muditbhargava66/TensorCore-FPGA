/*
 * Copyright (c) 2024 TensorCore-FPGA Project
 * SPDX-License-Identifier: Apache-2.0
 *
 * SPI Slave for Weight Loading
 * - Mode 0 (CPOL=0, CPHA=0)
 * - 8-bit transfers
 */

`default_nettype none

module spi_slave (
    input  wire       clk,
    input  wire       rst_n,
    
    // SPI interface
    input  wire       sck,
    input  wire       cs_n,
    input  wire       mosi,
    output wire       miso,
    
    // Data interface
    output reg  [7:0] rx_data,
    output reg        rx_valid,
    input  wire [7:0] tx_data,
    input  wire       tx_load
);

    reg [2:0] bit_cnt;
    reg [7:0] shift_in;
    reg [7:0] shift_out;
    reg       sck_d1, sck_d2;
    reg       cs_n_d1;
    
    wire sck_rising  = sck_d1 && !sck_d2;
    wire sck_falling = !sck_d1 && sck_d2;
    
    // Synchronize SPI signals to system clock
    always @(posedge clk) begin
        if (!rst_n) begin
            sck_d1 <= 0;
            sck_d2 <= 0;
            cs_n_d1 <= 1;
        end else begin
            sck_d1 <= sck;
            sck_d2 <= sck_d1;
            cs_n_d1 <= cs_n;
        end
    end
    
    // MISO output
    assign miso = shift_out[7];
    
    // Receive shift register
    always @(posedge clk) begin
        if (!rst_n || cs_n_d1) begin
            bit_cnt <= 0;
            shift_in <= 0;
            rx_valid <= 0;
        end else if (sck_rising) begin
            shift_in <= {shift_in[6:0], mosi};
            bit_cnt <= bit_cnt + 1;
            
            if (bit_cnt == 7) begin
                rx_data <= {shift_in[6:0], mosi};
                rx_valid <= 1;
            end else begin
                rx_valid <= 0;
            end
        end else begin
            rx_valid <= 0;
        end
    end
    
    // Transmit shift register
    always @(posedge clk) begin
        if (!rst_n || cs_n_d1) begin
            shift_out <= 8'h00;
        end else if (tx_load) begin
            shift_out <= tx_data;
        end else if (sck_falling) begin
            shift_out <= {shift_out[6:0], 1'b0};
        end
    end

endmodule
