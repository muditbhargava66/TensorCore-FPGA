# Verilator Makefile

MODULE_TOP = MatMul_Controller
RTL_DIR = ../../rtl/core
TB = top_tb.v

# Verilator flags
VERILATOR = verilator
V_FLAGS = --binary -j 0 --trace --top-module $(MODULE_TOP)

# Source files (Behavioral)
RTL_SRCS = $(RTL_DIR)/MatMul_Controller.v \
           $(RTL_DIR)/SA_MxN.v \
           $(RTL_DIR)/PE.v \
           $(RTL_DIR)/Control.v \
           $(RTL_DIR)/Memory.v \
           $(RTL_DIR)/VPU.v

# Synthesizable modules (FPGA-ready)
RTL_SYNTH = $(RTL_DIR)/MAC.v \
            $(RTL_DIR)/PE_Synth.v \
            $(RTL_DIR)/SA_MxN_Synth.v \
            $(RTL_DIR)/VPU_Synth.v

# Note: We need a C++ wrapper for Verilator usually, but new Verilator supports --binary for simple testbenches
# However, purely Verilog testbenches with delays are tricky in Verilator.
# For now, we will use Icarus Verilog (iverilog) which is better for "pure Verilog" TBs, 
# OR use Verilator if we write a C++ testbench.

# Given the user has standard Verilog TBs (*_tb.v), 'iverilog' is actually the best "free Mac compatible" tool 
# for preserving the existing testbenches without rewriting them in C++.
# I will output an iverilog target as primary.

IVERILOG = iverilog -g2012 -I $(RTL_DIR) -I ../../rtl/include
VVP = vvp
GTKWAVE = gtkwave

SIM_EXE = sim_result

all: build

build:
	$(IVERILOG) -o $(SIM_EXE) -I $(RTL_DIR) $(TB) $(RTL_SRCS)

run: build
	$(VVP) $(SIM_EXE)

clean:
	rm -f $(SIM_EXE) *.vcd obj_dir/
