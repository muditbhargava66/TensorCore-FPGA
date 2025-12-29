`include "fixed_point_pkg.vh"
`include "system_defs.vh"

/**
 * @module MatMul_Controller_Synth
 * @brief Synthesizable Controller for Tiled Matrix Multiplication.
 *
 * Fully synthesizable version of MatMul_Controller.
 * Uses Q16.16 fixed-point arithmetic instead of $bitstoreal/$realtobits.
 *
 * @param M Row dimension of the Tile (SA size).
 * @param N Col dimension of the Tile (SA size).
 */
module MatMul_Controller_Synth #(
    parameter M = `SA_ROWS,
    parameter N = `SA_COLS
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     start,
    output reg                      done,
    input  wire                     output_stationary,
    input  wire [`FP_WIDTH*M*M-1:0] A_tile_flat,
    input  wire [`FP_WIDTH*M*M-1:0] W_tile_flat,
    output wire [`FP_WIDTH*M*M-1:0] C_tile_flat,
    input  wire [7:0]               k1,
    input  wire [7:0]               k2,
    input  wire [7:0]               k3
);

    // Unpacked tiles
    wire signed [`FP_WIDTH-1:0] A_tile [0:M*M-1];
    wire signed [`FP_WIDTH-1:0] W_tile [0:M*M-1];
    reg  signed [`FP_WIDTH-1:0] C_tile [0:M*M-1];
    
    genvar unpack_idx;
    generate
        for (unpack_idx = 0; unpack_idx < M*M; unpack_idx = unpack_idx + 1) begin : unpack_tiles
            assign A_tile[unpack_idx] = A_tile_flat[`FP_WIDTH*(unpack_idx+1)-1:`FP_WIDTH*unpack_idx];
            assign W_tile[unpack_idx] = W_tile_flat[`FP_WIDTH*(unpack_idx+1)-1:`FP_WIDTH*unpack_idx];
            assign C_tile_flat[`FP_WIDTH*(unpack_idx+1)-1:`FP_WIDTH*unpack_idx] = C_tile[unpack_idx];
        end
    endgenerate

    // State Machine
    localparam IDLE          = 4'd0;
    localparam WS_PRELOAD    = 4'd1;
    localparam WS_COMPUTE    = 4'd2;
    localparam WS_DONE       = 4'd3;
    localparam OS_RESET      = 4'd4;
    localparam OS_ACCUMULATE = 4'd5;
    localparam OS_DRAIN      = 4'd6;
    localparam OS_DONE       = 4'd7;
    
    reg [3:0]  state, next_state;
    reg [15:0] cycle_counter;
    reg [15:0] total_cycles;
    
    // SA control signals
    reg                        sa_reset;
    reg                        sa_preload_valid;
    wire [`FP_WIDTH*N-1:0]     sa_in_top_flat;
    wire [`FP_WIDTH*M-1:0]     sa_in_left_flat;
    wire [`FP_WIDTH*M-1:0]     sa_out_right_flat;
    wire [`FP_WIDTH*N-1:0]     sa_out_bottom_flat;
    wire [`FP_WIDTH*M*N-1:0]   sa_preload_data_flat;
    
    // Unpacked SA I/O
    reg  signed [`FP_WIDTH-1:0] sa_in_top     [0:N-1];
    reg  signed [`FP_WIDTH-1:0] sa_in_left    [0:M-1];
    wire signed [`FP_WIDTH-1:0] sa_out_right  [0:M-1];
    wire signed [`FP_WIDTH-1:0] sa_out_bottom [0:N-1];
    reg  signed [`FP_WIDTH-1:0] sa_preload_data [0:M*N-1];
    
    // Pack/Unpack SA I/O
    genvar sa_idx;
    generate
        for (sa_idx = 0; sa_idx < N; sa_idx = sa_idx + 1) begin : pack_sa_top
            assign sa_in_top_flat[`FP_WIDTH*(sa_idx+1)-1:`FP_WIDTH*sa_idx] = sa_in_top[sa_idx];
            assign sa_out_bottom[sa_idx] = sa_out_bottom_flat[`FP_WIDTH*(sa_idx+1)-1:`FP_WIDTH*sa_idx];
        end
        for (sa_idx = 0; sa_idx < M; sa_idx = sa_idx + 1) begin : pack_sa_left
            assign sa_in_left_flat[`FP_WIDTH*(sa_idx+1)-1:`FP_WIDTH*sa_idx] = sa_in_left[sa_idx];
            assign sa_out_right[sa_idx] = sa_out_right_flat[`FP_WIDTH*(sa_idx+1)-1:`FP_WIDTH*sa_idx];
        end
        for (sa_idx = 0; sa_idx < M*N; sa_idx = sa_idx + 1) begin : pack_sa_preload
            assign sa_preload_data_flat[`FP_WIDTH*(sa_idx+1)-1:`FP_WIDTH*sa_idx] = sa_preload_data[sa_idx];
        end
    endgenerate
    
    // Loop indices (kept as integers for synthesis)
    integer i, j, a_row, r_out, k_val, k_idx;
    
    // Instantiate Synthesizable Systolic Array
    SA_MxN_Synth #(.M(M), .N(N)) sa_inst (
        .clk(clk),
        .reset(sa_reset),
        .output_stationary(output_stationary),
        .in_top(sa_in_top_flat),
        .in_left(sa_in_left_flat),
        .out_right(sa_out_right_flat),
        .out_bottom(sa_out_bottom_flat),
        .preload_valid(sa_preload_valid),
        .preload_data(sa_preload_data_flat)
    );
    
    // State Register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next State Logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) begin
                    if (!output_stationary) begin
                        next_state = WS_PRELOAD;
                    end else begin
                        next_state = OS_RESET;
                    end
                end
            end
            
            WS_PRELOAD: begin
                next_state = WS_COMPUTE;
            end
            
            WS_COMPUTE: begin
                if (cycle_counter >= total_cycles - 1) begin
                    next_state = WS_DONE;
                end
            end
            
            WS_DONE: begin
                next_state = IDLE;
            end
            
            OS_RESET: begin
                next_state = OS_ACCUMULATE;
            end
            
            OS_ACCUMULATE: begin
                if (cycle_counter >= total_cycles - 1) begin
                    next_state = OS_DRAIN;
                end
            end
            
            OS_DRAIN: begin
                if (cycle_counter >= M - 1) begin
                    next_state = OS_DONE;
                end
            end
            
            OS_DONE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Output Logic and Datapath
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            done             <= 1'b0;
            sa_reset         <= 1'b1;
            sa_preload_valid <= 1'b0;
            cycle_counter    <= 16'd0;
            total_cycles     <= 16'd0;
            
            for (i = 0; i < N; i = i + 1) begin
                sa_in_top[i] <= `FP_ZERO;
            end
            for (i = 0; i < M; i = i + 1) begin
                sa_in_left[i] <= `FP_ZERO;
            end
            for (i = 0; i < M*N; i = i + 1) begin
                sa_preload_data[i] <= `FP_ZERO;
            end
            for (i = 0; i < M*M; i = i + 1) begin
                C_tile[i] <= `FP_ZERO;
            end
        end else begin
            case (state)
                IDLE: begin
                    done             <= 1'b0;
                    sa_reset         <= 1'b0;
                    sa_preload_valid <= 1'b0;
                    cycle_counter    <= 16'd0;
                    
                    if (start) begin
                        if (!output_stationary) begin
                            total_cycles <= k1 + M + N;
                        end else begin
                            total_cycles <= k2 + M + N;
                        end
                        
                        // Clear output tile
                        for (i = 0; i < M*M; i = i + 1) begin
                            C_tile[i] <= `FP_ZERO;
                        end
                    end
                end
                
                WS_PRELOAD: begin
                    sa_preload_valid <= 1'b1;
                    
                    // Preload weights
                    for (i = 0; i < M; i = i + 1) begin
                        for (j = 0; j < N; j = j + 1) begin
                            if ((i < k2) && (j < k3)) begin
                                sa_preload_data[i*N + j] <= W_tile[i*M + j];
                            end else begin
                                sa_preload_data[i*N + j] <= `FP_ZERO;
                            end
                        end
                    end
                    
                    // Clear top inputs
                    for (j = 0; j < N; j = j + 1) begin
                        sa_in_top[j] <= `FP_ZERO;
                    end
                end
                
                WS_COMPUTE: begin
                    sa_preload_valid <= 1'b0;
                    
                    // Feed A tile values with skew
                    for (i = 0; i < M; i = i + 1) begin
                        a_row = cycle_counter - i;
                        if ((a_row >= 0) && (a_row < k1) && (i < k2)) begin
                            sa_in_left[i] <= A_tile[a_row * M + i];
                        end else begin
                            sa_in_left[i] <= `FP_ZERO;
                        end
                    end
                    
                    // Capture output values (accumulate with fixed-point addition)
                    for (j = 0; j < N; j = j + 1) begin
                        r_out = cycle_counter - M - j;
                        if ((r_out >= 0) && (r_out < k1) && (j < k3)) begin
                            // Fixed-point addition (no $bitstoreal needed)
                            C_tile[r_out * M + j] <= C_tile[r_out * M + j] + sa_out_bottom[j];
                        end
                    end
                    
                    cycle_counter <= cycle_counter + 1;
                end
                
                WS_DONE: begin
                    done <= 1'b1;
                end
                
                OS_RESET: begin
                    sa_reset      <= 1'b1;
                    cycle_counter <= 16'd0;
                end
                
                OS_ACCUMULATE: begin
                    sa_reset         <= 1'b0;
                    sa_preload_valid <= 1'b0;
                    
                    // Feed A values with skew
                    for (i = 0; i < M; i = i + 1) begin
                        k_val = cycle_counter - i;
                        if ((k_val >= 0) && (k_val < k2) && (i < k1)) begin
                            sa_in_left[i] <= A_tile[i * M + k_val];
                        end else begin
                            sa_in_left[i] <= `FP_ZERO;
                        end
                    end
                    
                    // Feed W values with skew
                    for (j = 0; j < N; j = j + 1) begin
                        k_val = cycle_counter - j;
                        if ((k_val >= 0) && (k_val < k2) && (j < k3)) begin
                            sa_in_top[j] <= W_tile[k_val * M + j];
                        end else begin
                            sa_in_top[j] <= `FP_ZERO;
                        end
                    end
                    
                    cycle_counter <= cycle_counter + 1;
                end
                
                OS_DRAIN: begin
                    sa_preload_valid <= 1'b1;
                    
                    // Clear inputs during drain
                    for (j = 0; j < N; j = j + 1) begin
                        sa_in_top[j] <= `FP_ZERO;
                    end
                    for (i = 0; i < M; i = i + 1) begin
                        sa_in_left[i] <= `FP_ZERO;
                    end
                    
                    // Capture draining outputs
                    for (j = 0; j < N; j = j + 1) begin
                        k_idx = M - 1 - cycle_counter;
                        if ((k_idx >= 0) && (k_idx < k1) && (j < k3)) begin
                            // Fixed-point addition
                            C_tile[k_idx * M + j] <= C_tile[k_idx * M + j] + sa_out_bottom[j];
                        end
                    end
                    
                    cycle_counter <= cycle_counter + 1;
                end
                
                OS_DONE: begin
                    done             <= 1'b1;
                    sa_preload_valid <= 1'b0;
                end
                
                default: begin
                    done             <= 1'b0;
                    sa_reset         <= 1'b0;
                    sa_preload_valid <= 1'b0;
                end
            endcase
        end
    end

endmodule
