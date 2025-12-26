`include "fixed_point_pkg.vh"

/**
 * @module SA_MxN_Synth
 * @brief Synthesizable Systolic Array using fixed-point PEs.
 *
 * A grid of PE_Synth modules connected in systolic fashion.
 * Uses Q16.16 fixed-point arithmetic for FPGA/ASIC synthesis.
 *
 * @param M Number of Rows.
 * @param N Number of Columns.
 */
module SA_MxN_Synth #(
    parameter M = 3,
    parameter N = 3
)(
    input  wire                            clk,
    input  wire                            reset,
    input  wire                            output_stationary,
    input  wire [`FP_WIDTH*N-1:0]          in_top,
    input  wire [`FP_WIDTH*M-1:0]          in_left,
    output wire [`FP_WIDTH*M-1:0]          out_right,
    output wire [`FP_WIDTH*N-1:0]          out_bottom,
    input  wire                            preload_valid,
    input  wire [`FP_WIDTH*M*N-1:0]        preload_data
);

    // Internal wires for PE interconnections
    wire signed [`FP_WIDTH-1:0] pe_out_right  [0:M-1][0:N-1];
    wire signed [`FP_WIDTH-1:0] pe_out_bottom [0:M-1][0:N-1];
    wire signed [`FP_WIDTH-1:0] pe_in_top     [0:M-1][0:N-1];
    wire signed [`FP_WIDTH-1:0] pe_in_left    [0:M-1][0:N-1];
    
    // Unpacked I/O arrays
    wire signed [`FP_WIDTH-1:0] in_top_unpacked     [0:N-1];
    wire signed [`FP_WIDTH-1:0] in_left_unpacked    [0:M-1];
    wire signed [`FP_WIDTH-1:0] out_right_unpacked  [0:M-1];
    wire signed [`FP_WIDTH-1:0] out_bottom_unpacked [0:N-1];
    wire signed [`FP_WIDTH-1:0] preload_unpacked    [0:M*N-1];
    
    // Unpack inputs
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : unpack_top
            assign in_top_unpacked[i] = in_top[`FP_WIDTH*(i+1)-1:`FP_WIDTH*i];
        end
        for (i = 0; i < M; i = i + 1) begin : unpack_left
            assign in_left_unpacked[i] = in_left[`FP_WIDTH*(i+1)-1:`FP_WIDTH*i];
        end
        for (i = 0; i < M; i = i + 1) begin : pack_right
            assign out_right[`FP_WIDTH*(i+1)-1:`FP_WIDTH*i] = out_right_unpacked[i];
        end
        for (i = 0; i < N; i = i + 1) begin : pack_bottom
            assign out_bottom[`FP_WIDTH*(i+1)-1:`FP_WIDTH*i] = out_bottom_unpacked[i];
        end
        for (i = 0; i < M*N; i = i + 1) begin : unpack_preload
            assign preload_unpacked[i] = preload_data[`FP_WIDTH*(i+1)-1:`FP_WIDTH*i];
        end
    endgenerate

    // Generate PE grid
    genvar row, col;
    generate
        for (row = 0; row < M; row = row + 1) begin : row_gen
            for (col = 0; col < N; col = col + 1) begin : col_gen
                
                // Left input connection
                if (col == 0) begin : left_edge
                    assign pe_in_left[row][col] = in_left_unpacked[row];
                end else begin : left_internal
                    assign pe_in_left[row][col] = pe_out_right[row][col-1];
                end
                
                // Top input connection
                if (row == 0) begin : top_edge
                    assign pe_in_top[row][col] = in_top_unpacked[col];
                end else begin : top_internal
                    assign pe_in_top[row][col] = pe_out_bottom[row-1][col];
                end
                
                // Right edge output
                if (col == N-1) begin : right_edge
                    assign out_right_unpacked[row] = pe_out_right[row][col];
                end
                
                // Bottom edge output
                if (row == M-1) begin : bottom_edge
                    assign out_bottom_unpacked[col] = pe_out_bottom[row][col];
                end
                
                // Instantiate PE
                PE_Synth pe_inst (
                    .clk(clk),
                    .reset(reset),
                    .output_stationary(output_stationary),
                    .in_top(pe_in_top[row][col]),
                    .in_left(pe_in_left[row][col]),
                    .out_right(pe_out_right[row][col]),
                    .out_bottom(pe_out_bottom[row][col]),
                    .preload_valid(preload_valid),
                    .preload_data(preload_unpacked[row*N + col])
                );
            end
        end
    endgenerate

endmodule
