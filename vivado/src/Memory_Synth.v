`include "fixed_point_pkg.vh"

/**
 * @module Memory_Synth
 * @brief Synthesizable Memory Module using BRAM inference.
 *
 * Simple synchronous read/write memory optimized for FPGA BRAM inference.
 * Replaces the behavioral Memory module for synthesis.
 *
 * @param ADDR_WIDTH Address bus width.
 * @param DATA_WIDTH Data bus width (default 32-bit for Q16.16 fixed-point).
 * @param MEM_SIZE Total entries in bytes (divided by data width for actual slots).
 */
module Memory_Synth #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter MEM_SIZE   = 65536
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     read_enable,
    input  wire                     write_enable,
    input  wire [ADDR_WIDTH-1:0]    address,
    input  wire [DATA_WIDTH-1:0]    write_data,
    output reg  [DATA_WIDTH-1:0]    read_data,
    output reg                      ready
);

    // Calculate number of memory entries based on data width
    localparam MEM_DEPTH = MEM_SIZE / (DATA_WIDTH / 8);
    localparam ADDR_SHIFT = $clog2(DATA_WIDTH / 8);
    
    // BRAM-inferrable memory array
    // Use (* ram_style = "block" *) for explicit BRAM inference
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] mem_array [0:MEM_DEPTH-1];
    
    // State machine for pipelined access
    localparam IDLE  = 2'b00;
    localparam READ  = 2'b01;
    localparam WRITE = 2'b10;
    
    reg [1:0] state;
    reg [ADDR_WIDTH-ADDR_SHIFT-1:0] word_addr;
    
    // Initialize memory to zero (synthesizable with some tools)
    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem_array[i] = {DATA_WIDTH{1'b0}};
        end
    end
    
    // Word address calculation
    always @(*) begin
        word_addr = address[ADDR_WIDTH-1:ADDR_SHIFT];
    end
    
    // State machine and memory operations
    always @(posedge clk) begin
        if (reset) begin
            state     <= IDLE;
            read_data <= {DATA_WIDTH{1'b0}};
            ready     <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b0;
                    if (read_enable && !write_enable) begin
                        state <= READ;
                    end else if (write_enable && !read_enable) begin
                        // Write on same cycle for better timing
                        mem_array[word_addr] <= write_data;
                        state <= WRITE;
                    end
                end
                
                READ: begin
                    read_data <= mem_array[word_addr];
                    ready     <= 1'b1;
                    state     <= IDLE;
                end
                
                WRITE: begin
                    ready <= 1'b1;
                    state <= IDLE;
                end
                
                default: begin
                    state <= IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule
