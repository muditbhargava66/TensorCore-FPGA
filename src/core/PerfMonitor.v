/**
 * @module PerfMonitor
 * @brief Performance Monitoring Unit for HAI Processor.
 *
 * Tracks hardware performance counters:
 * - Total cycles since start
 * - Memory read operations
 * - Memory write operations
 * - Compute cycles (SA active)
 * - Stall cycles (waiting for memory)
 *
 * All counters are 32-bit and wrap around.
 */
module PerfMonitor (
    input  wire        clk,
    input  wire        reset,
    
    // Control
    input  wire        enable,       // Enable counting
    input  wire        clear,        // Clear all counters
    
    // Events to monitor
    input  wire        mem_read,     // Memory read occurred
    input  wire        mem_write,    // Memory write occurred
    input  wire        compute_active, // SA is computing
    input  wire        stall,        // Pipeline stalled
    
    // Counter outputs
    output reg [31:0]  cycles,       // Total cycles
    output reg [31:0]  mem_rd_count, // Memory reads
    output reg [31:0]  mem_wr_count, // Memory writes
    output reg [31:0]  compute_cyc,  // Compute cycles
    output reg [31:0]  stall_cyc     // Stall cycles
);

    always @(posedge clk or posedge reset) begin
        if (reset || clear) begin
            cycles       <= 32'd0;
            mem_rd_count <= 32'd0;
            mem_wr_count <= 32'd0;
            compute_cyc  <= 32'd0;
            stall_cyc    <= 32'd0;
        end else if (enable) begin
            // Cycle counter always increments
            cycles <= cycles + 1;
            
            // Event counters
            if (mem_read)
                mem_rd_count <= mem_rd_count + 1;
            
            if (mem_write)
                mem_wr_count <= mem_wr_count + 1;
            
            if (compute_active)
                compute_cyc <= compute_cyc + 1;
            
            if (stall)
                stall_cyc <= stall_cyc + 1;
        end
    end
    
    // Derived metrics (optional, for software to compute):
    // - Memory bandwidth = (mem_rd_count + mem_wr_count) * DATA_WIDTH / cycles
    // - Compute utilization = compute_cyc / cycles
    // - Stall ratio = stall_cyc / cycles

endmodule
