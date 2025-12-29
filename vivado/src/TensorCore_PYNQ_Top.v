`include "system_defs.vh"
`include "fixed_point_pkg.vh"

/**
 * @module TensorCore_PYNQ_Top
 * @brief Top-Level FPGA Module for PYNQ-Z1 with AXI4-Lite Interface.
 *
 * This module provides the complete integration of TensorCore accelerator
 * with an AXI4-Lite slave interface for PS (ARM) control on Zynq-7000.
 *
 * Features:
 * - AXI4-Lite slave for register-based control
 * - Synthesizable TensorCore with Systolic Array and VPU
 * - Performance counters accessible via AXI
 * - Clock domain: Single clock from FCLK_CLK0 (100 MHz typical)
 *
 * Integration:
 * - Connect to Zynq PS AXI GP0 master port
 * - Base address: 0x43C00000 (typical for AXI GP0)
 */
module TensorCore_PYNQ_Top #(
    // AXI Parameters
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 8,
    // TensorCore Parameters
    parameter M           = `SA_ROWS,
    parameter ADDR_WIDTH  = `ADDR_WIDTH,
    parameter MEM_SIZE    = `MEM_SIZE,
    parameter VECTOR_SIZE = `VPU_VECTOR_SIZE
)(
    // AXI4-Lite Slave Interface
    input  wire                              S_AXI_ACLK,
    input  wire                              S_AXI_ARESETN,
    
    // Write Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     S_AXI_AWADDR,
    input  wire                              S_AXI_AWVALID,
    output wire                              S_AXI_AWREADY,
    
    // Write Data Channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_WDATA,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0]   S_AXI_WSTRB,
    input  wire                              S_AXI_WVALID,
    output wire                              S_AXI_WREADY,
    
    // Write Response Channel
    output wire [1:0]                        S_AXI_BRESP,
    output wire                              S_AXI_BVALID,
    input  wire                              S_AXI_BREADY,
    
    // Read Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     S_AXI_ARADDR,
    input  wire                              S_AXI_ARVALID,
    output wire                              S_AXI_ARREADY,
    
    // Read Data Channel
    output wire [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_RDATA,
    output wire [1:0]                        S_AXI_RRESP,
    output wire                              S_AXI_RVALID,
    input  wire                              S_AXI_RREADY,
    
    // Debug LEDs (directly to board LEDs)
    output wire        led_done,
    output wire        led_busy,
    output wire [1:0]  led_state
);

    // =========================================================================
    // Internal Signals
    // =========================================================================
    
    // Clock and reset
    wire clk   = S_AXI_ACLK;
    wire rst_n = S_AXI_ARESETN;
    wire reset = ~rst_n;
    
    // Signals FROM AXI wrapper (control outputs)
    wire        axi_accel_start;
    wire        axi_accel_reset;
    wire        axi_accel_vpu_enable;
    wire        axi_accel_mode;
    wire [7:0]  axi_accel_k1;
    wire [7:0]  axi_accel_k2;
    wire [7:0]  axi_accel_k3;
    wire [15:0] axi_accel_a_base;
    wire [15:0] axi_accel_w_base;
    wire [15:0] axi_accel_c_base;
    wire [7:0]  axi_accel_vpu_op;
    
    // Signals FROM TensorCore (status outputs)
    wire        tc_done;
    wire        tc_busy;
    wire [3:0]  tc_state;
    wire [31:0] tc_perf_cycles;
    wire [31:0] tc_perf_mem_rd;
    wire [31:0] tc_perf_mem_wr;
    
    // Combined reset: hardware reset OR software reset
    wire accel_reset_combined = reset | axi_accel_reset;
    
    // =========================================================================
    // AXI4-Lite Wrapper Instance
    // =========================================================================
    
    TensorCore_AXI_Wrapper #(
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) axi_wrapper_inst (
        // AXI Interface
        .S_AXI_ACLK(S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),
        .S_AXI_AWADDR(S_AXI_AWADDR),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WSTRB(S_AXI_WSTRB),
        .S_AXI_WVALID(S_AXI_WVALID),
        .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_BRESP(S_AXI_BRESP),
        .S_AXI_BVALID(S_AXI_BVALID),
        .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_ARADDR(S_AXI_ARADDR),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RRESP(S_AXI_RRESP),
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_RREADY(S_AXI_RREADY),
        
        // Control outputs (to TensorCore)
        .accel_start(axi_accel_start),
        .accel_reset(axi_accel_reset),
        .accel_vpu_enable(axi_accel_vpu_enable),
        .accel_mode(axi_accel_mode),
        .accel_k1(axi_accel_k1),
        .accel_k2(axi_accel_k2),
        .accel_k3(axi_accel_k3),
        .accel_a_base(axi_accel_a_base),
        .accel_w_base(axi_accel_w_base),
        .accel_c_base(axi_accel_c_base),
        .accel_vpu_op(axi_accel_vpu_op),
        
        // Status inputs (from TensorCore)
        .accel_done(tc_done),
        .accel_busy(tc_busy),
        .accel_state(tc_state),
        
        // Performance counter inputs (from TensorCore)
        .perf_cycles(tc_perf_cycles),
        .perf_mem_rd(tc_perf_mem_rd),
        .perf_mem_wr(tc_perf_mem_wr)
    );
    
    // =========================================================================
    // TensorCore Synthesizable Instance
    // =========================================================================
    
    TensorCore_Synth #(
        .M(M),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_SIZE(MEM_SIZE),
        .VECTOR_SIZE(VECTOR_SIZE)
    ) tensorcore_inst (
        .clk(clk),
        .reset(accel_reset_combined),
        
        // Control inputs (from AXI wrapper)
        .start(axi_accel_start),
        .K1(axi_accel_k1),
        .K2(axi_accel_k2),
        .K3(axi_accel_k3),
        .A_base_addr(axi_accel_a_base),
        .W_base_addr(axi_accel_w_base),
        .C_base_addr(axi_accel_c_base),
        .output_stationary(axi_accel_mode),
        .vpu_enable(axi_accel_vpu_enable),
        .vpu_op_sel(axi_accel_vpu_op[0]),
        
        // Status outputs (to AXI wrapper)
        .done(tc_done),
        .busy(tc_busy),
        .state_out(tc_state),
        
        // Performance counter outputs (to AXI wrapper)
        .perf_cycles(tc_perf_cycles),
        .perf_mem_rd(tc_perf_mem_rd),
        .perf_mem_wr(tc_perf_mem_wr)
    );
    
    // =========================================================================
    // Debug LED Assignments
    // =========================================================================
    
    assign led_done  = tc_done;
    assign led_busy  = tc_busy;
    assign led_state = tc_state[1:0];

endmodule

