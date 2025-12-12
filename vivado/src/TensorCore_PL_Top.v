`include "system_defs.vh"

/**
 * @module TensorCore_PL_Top
 * @brief Simplified FPGA Top Module for PYNQ-Z1 Standalone PL Testing.
 *
 * This module is designed for initial FPGA bring-up without PS integration.
 * Uses board buttons/switches for control and LEDs for status.
 *
 * Control:
 * - BTN0 = reset (directly in constraints)
 * - BTN1 = start
 * - SW0  = vpu_enable  
 * - SW1  = vpu_op_sel
 *
 * Status:
 * - LED0 = done
 * - LED1 = busy
 * - LED2,3 = state[1:0]
 */
module TensorCore_PL_Top (
    // Clock (125 MHz from PL oscillator)
    input  wire        clk,
    input  wire        reset,
    
    // Control (directly from buttons/switches)
    input  wire        start,
    input  wire        vpu_enable,
    input  wire        vpu_op_sel,
    
    // Status (directly to LEDs)
    output wire        done,
    output wire        busy,
    output wire [1:0]  state_out
);

    // =========================================================================
    // Clock Domain Crossing / Debouncing (simplified)
    // =========================================================================
    
    // Synchronize async inputs
    reg [2:0] start_sync;
    reg       start_rising;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            start_sync   <= 3'b0;
            start_rising <= 1'b0;
        end else begin
            start_sync   <= {start_sync[1:0], start};
            start_rising <= start_sync[1] & ~start_sync[2];  // Rising edge detect
        end
    end
    
    // =========================================================================
    // Performance Counters
    // =========================================================================
    
    wire [31:0] perf_cycles;
    wire [31:0] perf_mem_rd;
    wire [31:0] perf_mem_wr;
    
    // =========================================================================
    // Core State Machine
    // =========================================================================
    
    localparam IDLE    = 2'd0;
    localparam COMPUTE = 2'd1;
    localparam DONE_ST = 2'd2;
    
    reg [1:0]  state;
    reg        done_reg;
    reg [15:0] compute_counter;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state           <= IDLE;
            done_reg        <= 1'b0;
            compute_counter <= 16'd0;
        end else begin
            case (state)
                IDLE: begin
                    done_reg <= 1'b0;
                    if (start_rising) begin
                        state           <= COMPUTE;
                        compute_counter <= 16'd0;
                    end
                end
                
                COMPUTE: begin
                    // Simplified compute (placeholder for actual SA/VPU)
                    // In real design, this would instantiate the systolic array
                    compute_counter <= compute_counter + 1;
                    
                    // Simulate ~1000 cycles of compute
                    if (compute_counter >= 16'd1000) begin
                        state <= DONE_ST;
                    end
                end
                
                DONE_ST: begin
                    done_reg <= 1'b1;
                    // Wait for start to release before returning to IDLE
                    if (!start_sync[2]) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // =========================================================================
    // Performance Counter Instance
    // =========================================================================
    
    PerfMonitor perf_mon (
        .clk(clk),
        .reset(reset),
        .enable(state != IDLE),
        .clear(start_rising),
        .mem_read(1'b0),
        .mem_write(1'b0),
        .compute_active(state == COMPUTE),
        .stall(1'b0),
        .cycles(perf_cycles),
        .mem_rd_count(perf_mem_rd),
        .mem_wr_count(perf_mem_wr),
        .compute_cyc(),
        .stall_cyc()
    );
    
    // =========================================================================
    // Output Assignments
    // =========================================================================
    
    assign done      = done_reg;
    assign busy      = (state != IDLE);
    assign state_out = state;

endmodule
