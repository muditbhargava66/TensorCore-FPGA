`include "system_defs.vh"
`include "fixed_point_pkg.vh"

/**
 * @module TensorCore_Synth
 * @brief Fully Synthesizable Top-Level TensorCore Accelerator.
 *
 * Combines:
 * - Synthesizable Matrix Multiplication Unit (MatMul_Controller_Synth + SA_MxN_Synth)
 * - Synthesizable Vector Processing Unit (VPU_Synth)
 * - Performance Monitor (PerfMonitor)
 *
 * Uses Q16.16 fixed-point arithmetic throughout.
 * All non-synthesizable constructs ($display, real types) have been removed.
 *
 * Data Flow:
 * 1. Matrix multiplication: A × W = C
 * 2. (Optional) VPU post-processing on C (Norm/Softmax)
 * 3. Write result back to memory
 */
module TensorCore_Synth #(
    parameter M           = `SA_ROWS,
    parameter ADDR_WIDTH  = `ADDR_WIDTH,
    parameter MEM_SIZE    = `MEM_SIZE,
    parameter VECTOR_SIZE = `VPU_VECTOR_SIZE
)(
    input  wire                    clk,
    input  wire                    reset,
    
    // Control Interface
    input  wire                    start,
    output wire                    done,
    output wire                    busy,
    output wire [3:0]              state_out,
    
    // Matrix Configuration
    input  wire [7:0]              K1,
    input  wire [7:0]              K2,
    input  wire [7:0]              K3,
    input  wire [ADDR_WIDTH-1:0]   A_base_addr,
    input  wire [ADDR_WIDTH-1:0]   W_base_addr,
    input  wire [ADDR_WIDTH-1:0]   C_base_addr,
    input  wire                    output_stationary,
    
    // VPU Configuration
    input  wire                    vpu_enable,
    input  wire                    vpu_op_sel,  // 0: Norm, 1: Softmax
    
    // Performance Counters (exposed for readout)
    output wire [31:0]             perf_cycles,
    output wire [31:0]             perf_mem_rd,
    output wire [31:0]             perf_mem_wr
);

    // =========================================================================
    // Internal Signals
    // =========================================================================
    
    // MMU signals
    wire        mmu_done;
    wire        mmu_busy;
    wire [3:0]  mmu_state;
    
    // VPU signals
    reg         vpu_start;
    wire        vpu_done;
    
    // Performance monitor signals
    wire        perf_enable;
    wire        mem_read_event;
    wire        mem_write_event;
    wire        compute_active;
    wire        stall_event;
    wire [31:0] perf_compute_cyc;
    wire [31:0] perf_stall_cyc;
    
    // State machine for VPU integration
    localparam IDLE        = 3'd0;
    localparam RUN_MMU     = 3'd1;
    localparam RUN_VPU     = 3'd2;
    localparam FINISH      = 3'd3;
    
    reg [2:0]  proc_state;
    reg        proc_done;
    
    // =========================================================================
    // MMU (Matrix Multiplication Unit) - Synthesizable Version
    // =========================================================================
    
    Control_Synth #(
        .M(M),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_SIZE(MEM_SIZE)
    ) mmu_inst (
        .clk(clk),
        .reset(reset),
        .start(proc_state == RUN_MMU && !mmu_done),
        .done(mmu_done),
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .A_base_addr(A_base_addr),
        .W_base_addr(W_base_addr),
        .C_base_addr(C_base_addr),
        .output_stationary(output_stationary),
        // Memory interface signals for perf monitor
        .mem_read_event(mem_read_event),
        .mem_write_event(mem_write_event)
    );
    
    // =========================================================================
    // VPU (Vector Processing Unit) - Synthesizable Version
    // =========================================================================
    
    // VPU input/output buffers
    wire [`FP_WIDTH*VECTOR_SIZE-1:0] vpu_scores_flat;
    wire [`FP_WIDTH*VECTOR_SIZE-1:0] vpu_values_flat;
    wire [`FP_WIDTH*VECTOR_SIZE-1:0] vpu_norm_flat;
    wire [`FP_WIDTH-1:0]             vpu_softmax_out;
    
    // Tie VPU inputs to zero for now (to be connected to memory in full integration)
    assign vpu_scores_flat = {(`FP_WIDTH*VECTOR_SIZE){1'b0}};
    assign vpu_values_flat = {(`FP_WIDTH*VECTOR_SIZE){1'b0}};
    
    VPU_Synth #(
        .VECTOR_SIZE(VECTOR_SIZE)
    ) vpu_inst (
        .clk(clk),
        .reset(reset),
        .start(vpu_start),
        .done(vpu_done),
        .op_sel(vpu_op_sel),
        .vec_in_scores_flat(vpu_scores_flat),
        .vec_in_values_flat(vpu_values_flat),
        .vec_out_norm_flat(vpu_norm_flat),
        .scalar_out_softmax(vpu_softmax_out)
    );
    
    // =========================================================================
    // Performance Monitor
    // =========================================================================
    
    assign perf_enable    = (proc_state != IDLE);
    assign compute_active = (proc_state == RUN_MMU) || (proc_state == RUN_VPU);
    assign stall_event    = 1'b0;  // TODO: Connect to memory stall signals
    
    PerfMonitor perf_mon (
        .clk(clk),
        .reset(reset),
        .enable(perf_enable),
        .clear(start),  // Clear on new operation
        .mem_read(mem_read_event),
        .mem_write(mem_write_event),
        .compute_active(compute_active),
        .stall(stall_event),
        .cycles(perf_cycles),
        .mem_rd_count(perf_mem_rd),
        .mem_wr_count(perf_mem_wr),
        .compute_cyc(perf_compute_cyc),
        .stall_cyc(perf_stall_cyc)
    );
    
    // =========================================================================
    // Top-Level State Machine
    // =========================================================================
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            proc_state <= IDLE;
            proc_done  <= 1'b0;
            vpu_start  <= 1'b0;
        end else begin
            vpu_start <= 1'b0;  // Default
            
            case (proc_state)
                IDLE: begin
                    // Only clear done when starting a new operation
                    // This keeps done latched until next start
                    if (start) begin
                        proc_done  <= 1'b0;  // Clear done on new start
                        proc_state <= RUN_MMU;
                    end
                end
                
                RUN_MMU: begin
                    if (mmu_done) begin
                        if (vpu_enable) begin
                            proc_state <= RUN_VPU;
                            vpu_start  <= 1'b1;
                        end else begin
                            proc_state <= FINISH;
                        end
                    end
                end
                
                RUN_VPU: begin
                    if (vpu_done) begin
                        proc_state <= FINISH;
                    end
                end
                
                FINISH: begin
                    proc_done  <= 1'b1;  // Latch done high
                    proc_state <= IDLE;
                end
                
                default: proc_state <= IDLE;
            endcase
        end
    end
    
    // =========================================================================

    // Output Assignments
    // =========================================================================
    
    assign done      = proc_done;
    assign busy      = (proc_state != IDLE);
    assign state_out = {1'b0, proc_state};

endmodule
