`include "fixed_point_pkg.vh"

/**
 * @module TensorCore_AXI_Wrapper
 * @brief AXI4-Lite slave wrapper for TensorCore accelerator.
 *
 * Provides PS (ARM) interface to control the accelerator.
 * Register map:
 *   0x00: CTRL_REG   - [0]=start, [1]=reset, [2]=vpu_enable, [3]=mode
 *   0x04: STATUS_REG - [0]=done, [1]=busy, [7:4]=state
 *   0x08: K1_REG     - Matrix dimension K1
 *   0x0C: K2_REG     - Matrix dimension K2
 *   0x10: K3_REG     - Matrix dimension K3
 *   0x14: A_BASE     - Matrix A base address
 *   0x18: W_BASE     - Matrix W base address
 *   0x1C: C_BASE     - Matrix C base address
 *   0x20: PERF_CYCLES  - Read-only cycle counter
 *   0x24: PERF_MEM_RD  - Read-only memory read counter
 *   0x28: PERF_MEM_WR  - Read-only memory write counter
 *   0x2C: VPU_OP       - VPU operation select
 */
module TensorCore_AXI_Wrapper #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 8
)(
    // AXI4-Lite Slave Interface
    input  wire                              S_AXI_ACLK,
    input  wire                              S_AXI_ARESETN,
    
    // Write Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     S_AXI_AWADDR,
    input  wire                              S_AXI_AWVALID,
    output reg                               S_AXI_AWREADY,
    
    // Write Data Channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_WDATA,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0]   S_AXI_WSTRB,
    input  wire                              S_AXI_WVALID,
    output reg                               S_AXI_WREADY,
    
    // Write Response Channel
    output reg  [1:0]                        S_AXI_BRESP,
    output reg                               S_AXI_BVALID,
    input  wire                              S_AXI_BREADY,
    
    // Read Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     S_AXI_ARADDR,
    input  wire                              S_AXI_ARVALID,
    output reg                               S_AXI_ARREADY,
    
    // Read Data Channel
    output reg  [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_RDATA,
    output reg  [1:0]                        S_AXI_RRESP,
    output reg                               S_AXI_RVALID,
    input  wire                              S_AXI_RREADY,
    
    // Accelerator Interface (to TensorCore)
    output reg                               accel_start,
    output reg                               accel_reset,
    output reg                               accel_vpu_enable,
    output reg                               accel_mode,
    input  wire                              accel_done,
    input  wire                              accel_busy,
    input  wire [3:0]                        accel_state,
    output reg  [7:0]                        accel_k1,
    output reg  [7:0]                        accel_k2,
    output reg  [7:0]                        accel_k3,
    output reg  [15:0]                       accel_a_base,
    output reg  [15:0]                       accel_w_base,
    output reg  [15:0]                       accel_c_base,
    output reg  [7:0]                        accel_vpu_op,
    
    // Performance counters (from PerfMonitor)
    input  wire [31:0]                       perf_cycles,
    input  wire [31:0]                       perf_mem_rd,
    input  wire [31:0]                       perf_mem_wr
);

    // Register addresses
    localparam ADDR_CTRL     = 8'h00;
    localparam ADDR_STATUS   = 8'h04;
    localparam ADDR_K1       = 8'h08;
    localparam ADDR_K2       = 8'h0C;
    localparam ADDR_K3       = 8'h10;
    localparam ADDR_A_BASE   = 8'h14;
    localparam ADDR_W_BASE   = 8'h18;
    localparam ADDR_C_BASE   = 8'h1C;
    localparam ADDR_PERF_CYC = 8'h20;
    localparam ADDR_PERF_RD  = 8'h24;
    localparam ADDR_PERF_WR  = 8'h28;
    localparam ADDR_VPU_OP   = 8'h2C;
    
    // Internal signals
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    
    // AXI Write FSM
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY  <= 1'b0;
            S_AXI_BVALID  <= 1'b0;
            S_AXI_BRESP   <= 2'b00;
            axi_awaddr    <= 0;
            
            // Reset registers
            accel_start      <= 1'b0;
            accel_reset      <= 1'b0;
            accel_vpu_enable <= 1'b0;
            accel_mode       <= 1'b0;
            accel_k1         <= 8'd0;
            accel_k2         <= 8'd0;
            accel_k3         <= 8'd0;
            accel_a_base     <= 16'd0;
            accel_w_base     <= 16'd0;
            accel_c_base     <= 16'd0;
            accel_vpu_op     <= 8'd0;
        end else begin
            // Default: clear start pulse
            accel_start <= 1'b0;
            
            // Address phase
            if (S_AXI_AWVALID && !S_AXI_AWREADY) begin
                S_AXI_AWREADY <= 1'b1;
                axi_awaddr    <= S_AXI_AWADDR;
            end else begin
                S_AXI_AWREADY <= 1'b0;
            end
            
            // Data phase
            if (S_AXI_WVALID && !S_AXI_WREADY && S_AXI_AWREADY) begin
                S_AXI_WREADY <= 1'b1;
                
                // Register write
                case (axi_awaddr[7:0])
                    ADDR_CTRL: begin
                        accel_start      <= S_AXI_WDATA[0];
                        accel_reset      <= S_AXI_WDATA[1];
                        accel_vpu_enable <= S_AXI_WDATA[2];
                        accel_mode       <= S_AXI_WDATA[3];
                    end
                    ADDR_K1:     accel_k1     <= S_AXI_WDATA[7:0];
                    ADDR_K2:     accel_k2     <= S_AXI_WDATA[7:0];
                    ADDR_K3:     accel_k3     <= S_AXI_WDATA[7:0];
                    ADDR_A_BASE: accel_a_base <= S_AXI_WDATA[15:0];
                    ADDR_W_BASE: accel_w_base <= S_AXI_WDATA[15:0];
                    ADDR_C_BASE: accel_c_base <= S_AXI_WDATA[15:0];
                    ADDR_VPU_OP: accel_vpu_op <= S_AXI_WDATA[7:0];
                endcase
            end else begin
                S_AXI_WREADY <= 1'b0;
            end
            
            // Response phase
            if (S_AXI_WREADY && !S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b1;
                S_AXI_BRESP  <= 2'b00;  // OKAY
            end else if (S_AXI_BREADY && S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b0;
            end
        end
    end
    
    // AXI Read FSM
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY <= 1'b0;
            S_AXI_RVALID  <= 1'b0;
            S_AXI_RRESP   <= 2'b00;
            S_AXI_RDATA   <= 0;
            axi_araddr    <= 0;
        end else begin
            // Address phase
            if (S_AXI_ARVALID && !S_AXI_ARREADY) begin
                S_AXI_ARREADY <= 1'b1;
                axi_araddr    <= S_AXI_ARADDR;
            end else begin
                S_AXI_ARREADY <= 1'b0;
            end
            
            // Data phase
            if (S_AXI_ARREADY && !S_AXI_RVALID) begin
                S_AXI_RVALID <= 1'b1;
                S_AXI_RRESP  <= 2'b00;
                
                // Register read
                case (axi_araddr[7:0])
                    ADDR_CTRL:     S_AXI_RDATA <= {28'b0, accel_mode, accel_vpu_enable, accel_reset, accel_start};
                    ADDR_STATUS:   S_AXI_RDATA <= {24'b0, accel_state, 2'b0, accel_busy, accel_done};
                    ADDR_K1:       S_AXI_RDATA <= {24'b0, accel_k1};
                    ADDR_K2:       S_AXI_RDATA <= {24'b0, accel_k2};
                    ADDR_K3:       S_AXI_RDATA <= {24'b0, accel_k3};
                    ADDR_A_BASE:   S_AXI_RDATA <= {16'b0, accel_a_base};
                    ADDR_W_BASE:   S_AXI_RDATA <= {16'b0, accel_w_base};
                    ADDR_C_BASE:   S_AXI_RDATA <= {16'b0, accel_c_base};
                    ADDR_PERF_CYC: S_AXI_RDATA <= perf_cycles;
                    ADDR_PERF_RD:  S_AXI_RDATA <= perf_mem_rd;
                    ADDR_PERF_WR:  S_AXI_RDATA <= perf_mem_wr;
                    ADDR_VPU_OP:   S_AXI_RDATA <= {24'b0, accel_vpu_op};
                    default:       S_AXI_RDATA <= 32'hDEADBEEF;
                endcase
            end else if (S_AXI_RREADY && S_AXI_RVALID) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end

endmodule
