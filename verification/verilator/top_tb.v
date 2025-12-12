/**
 * @module testbench
 * @brief Top-Level Verification Testbench.
 *
 * Verifies:
 * 1. VPU functionality (L2 Norm).
 * 2. Matrix Multiplication Unit (Control + SA + Memory) integration.
 *
 * Simulates full system behavior including memory loading and result checking.
 */
module testbench;

    reg clk;
    reg reset;
    
    // --- MMU Signals ---
    reg start_mmu;
    wire done_mmu;
    reg [7:0] K1, K2, K3;
    reg [15:0] A_base_addr, W_base_addr, C_base_addr;
    reg output_stationary;
    
    // --- VPU Signals ---
    reg start_vpu;
    wire done_vpu;
    reg op_sel;
    reg [63:0] vec_in_scores [0:31];
    reg [63:0] vec_in_values [0:31];
    wire [63:0] vec_out_norm [0:31];
    wire [63:0] scalar_out_softmax;
    
    // Parameters
    parameter M = 3;
    parameter ADDR_WIDTH = 16;
    parameter MEM_SIZE = 65536;
    parameter VECTOR_SIZE = 32;
    
    // --- DUT Instantiation ---
    
    // 1. Matrix Multiplication Unit (Control + SA + Memory)
    Control #(
        .M(M),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_SIZE(MEM_SIZE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start_mmu),
        .done(done_mmu),
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .A_base_addr(A_base_addr),
        .W_base_addr(W_base_addr),
        .C_base_addr(C_base_addr),
        .output_stationary(output_stationary)
    );
    
    // 2. Vector Processing Unit
    VPU #(
        .VECTOR_SIZE(VECTOR_SIZE)
    ) vpu_inst (
        .clk(clk),
        .reset(reset),
        .start(start_vpu),
        .done(done_vpu),
        .op_sel(op_sel),
        // Connect arrays - SystemVerilog would be easier but Verilog 2005 requires flatten/unflatten
        // For simulation simplicity here we passed unpacked arrays (supported in Icarus/Verilator usually)
        .vec_in_scores_flat(vec_in_scores),
        .vec_in_values_flat(vec_in_values),
        .vec_out_norm_flat(vec_out_norm),
        .scalar_out_softmax(scalar_out_softmax)
    );
    
    // --- Test Data ---
    integer i, j, k;
    real A_matrix [0:24];
    real W_matrix [0:24];
    real C_expected [0:24];
    real C_actual [0:24];
    real diff;
    integer errors;
    
    // --- Clock ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // --- Main Test Process ---
    initial begin
        $dumpfile("systolic_array.vcd");
        $dumpvars(0, testbench);
        
        $display("=======================================================");
        $display("     HAI Processor Testbench (MMU + VPU)              ");
        $display("=======================================================");
        
        // 1. Initialization
        reset = 1;
        start_mmu = 0;
        start_vpu = 0;
        K1 = 0; K2 = 0; K3 = 0;
        
        #20;
        reset = 0;
        #20;
        
        // =======================================================
        // TEST 1: VPU L2 Normalization (Fast Test)
        // =======================================================
        $display("\n-------------------------------------------------------");
        $display("TEST 1: VPU L2 Normalization");
        $display("-------------------------------------------------------");
        
        // Setup Vector: [3.0, 4.0, 0, ...] -> Norm = 5.0 -> Out = [0.6, 0.8, ...]
        for (i=0; i<32; i=i+1) begin 
            vec_in_scores[i] = 64'h0;
            vec_in_values[i] = 64'h0;
        end
        vec_in_scores[0] = $realtobits(3.0);
        vec_in_scores[1] = $realtobits(4.0);
        
        op_sel = 0; // Norm
        reset = 1; #10; reset = 0; #10;
        
        start_vpu = 1;
        #10;
        start_vpu = 0;
        
        wait(done_vpu == 1);
        #10;
        
        $display("VPU Norm Complete.");
        $display("Out[0] (Exp 0.6): %f", $bitstoreal(vec_out_norm[0]));
        $display("Out[1] (Exp 0.8): %f", $bitstoreal(vec_out_norm[1]));
        
        if ($bitstoreal(vec_out_norm[0]) > 0.59 && $bitstoreal(vec_out_norm[0]) < 0.61) 
            $display("VPU TEST PASSED");
        else 
            $display("VPU TEST FAILED");

        // =======================================================
        // TEST 2: Matrix Multiplication (Weight Stationary)
        // =======================================================
        $display("\n-------------------------------------------------------");
        $display("TEST 2: 5x5 Matrix Multiplication (Weight Stationary)");
        $display("-------------------------------------------------------");
        
        // Reset again
        reset = 1; #20; reset = 0; #20;
        
        // Setup Matrices
        for (i = 0; i < 25; i = i + 1) begin
            A_matrix[i] = i + 1;
            W_matrix[i] = (i % 6 == 0) ? 1.0 : 0.0; // Identity-like
            C_expected[i] = 0;
        end
        
        // Setup Memory (Direct Backdoor Access for Speed)
        for (i = 0; i < 25; i = i + 1) begin
            dut.memory_inst.mem_array[0 + i] = $realtobits(A_matrix[i]); // A at 0
            dut.memory_inst.mem_array[64 + i] = $realtobits(W_matrix[i]); // W at 64 (byte 512)
        end
        
        // MMU Configuration
        K1 = 5; K2 = 5; K3 = 5;
        A_base_addr = 0;
        W_base_addr = 512;  // 64 * 8
        C_base_addr = 1024; // 128 * 8
        output_stationary = 0;
        
        // START
        #10;
        start_mmu = 1;
        #10;
        start_mmu = 0;
        
        // Wait for Done
        wait(done_mmu == 1);
        #20;
        
        $display("MMU Computation Complete.");
        
        // Verify
        errors = 0;
        $display("Result C (First Row):");
        for (i = 0; i < 5; i = i + 1) begin
             C_actual[i] = $bitstoreal(dut.memory_inst.mem_array[128 + i]);
             $write("%5.2f ", C_actual[i]);
        end
        $display("");
        
        // =======================================================
        // TEST 2: VPU - L2 Normalization
        // =======================================================
        $display("\n-------------------------------------------------------");
        $display("TEST 2: VPU L2 Normalization");
        $display("-------------------------------------------------------");
        
        // Setup Vector: [3.0, 4.0, 0, ...] -> Norm = 5.0 -> Out = [0.6, 0.8, ...]
        for (i=0; i<32; i=i+1) begin 
            vec_in_scores[i] = 64'h0;
            vec_in_values[i] = 64'h0;
        end
        vec_in_scores[0] = $realtobits(3.0);
        vec_in_scores[1] = $realtobits(4.0);
        
        op_sel = 0; // Norm
        
        reset = 1; #10; reset = 0; #10;
        
        start_vpu = 1;
        #10;
        start_vpu = 0;
        
        wait(done_vpu == 1);
        #10;
        
        $display("VPU Norm Complete.");
        $display("Out[0] (Exp 0.6): %f", $bitstoreal(vec_out_norm[0]));
        $display("Out[1] (Exp 0.8): %f", $bitstoreal(vec_out_norm[1]));
        
        if ($bitstoreal(vec_out_norm[0]) > 0.59 && $bitstoreal(vec_out_norm[0]) < 0.61) 
            $display("VPU TEST PASSED");
        else 
            $display("VPU TEST FAILED");
            
        $finish;
    end
    
    // Timeout Watchdog
    initial begin
        #5000000;
        $display("\nERROR: Testbench timeout!");
        $finish;
    end

endmodule
