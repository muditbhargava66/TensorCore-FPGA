`timescale 1ns/1ps
module tb_vpu;
    reg clk, rst_n, start, valid_in;
    reg [1:0] op_sel;
    reg signed [7:0] data_in;
    wire valid_out, done;
    wire [7:0] data_out;
    
    vpu_mini #(.VECTOR_LEN(4)) dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .op_sel(op_sel), .valid_in(valid_in), .data_in(data_in),
        .valid_out(valid_out), .data_out(data_out), .done(done)
    );
    
    initial begin
        $dumpfile("tb_vpu.vcd");
        $dumpvars(0, tb_vpu);
    end
endmodule
