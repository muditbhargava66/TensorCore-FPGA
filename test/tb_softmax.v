`timescale 1ns/1ps
module tb_softmax;
    reg clk, rst_n, start, valid_in;
    reg signed [7:0] data_in;
    wire done, valid_out;
    wire [7:0] prob_out;
    
    softmax_unit #(.VECTOR_LEN(4)) dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .valid_in(valid_in), .data_in(data_in),
        .done(done), .valid_out(valid_out), .prob_out(prob_out)
    );
    
    initial begin
        $dumpfile("tb_softmax.vcd");
        $dumpvars(0, tb_softmax);
    end
endmodule
