# =============================================================================
# Yosys Synthesis Script for HAI Processor
# Target: SKY130 PDK
# =============================================================================

# Read Liberty file for timing
read_liberty -lib $::env(PLATFORM)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Read Verilog sources
read_verilog -I $::env(INCLUDE_DIR) $::env(VERILOG_DIR)/MAC.v
read_verilog -I $::env(INCLUDE_DIR) $::env(VERILOG_DIR)/PE_Synth.v
read_verilog -I $::env(INCLUDE_DIR) $::env(VERILOG_DIR)/SA_MxN_Synth.v
read_verilog -I $::env(INCLUDE_DIR) $::env(VERILOG_DIR)/VPU_Synth.v
read_verilog -I $::env(INCLUDE_DIR) $::env(VERILOG_DIR)/PerfMonitor.v
read_verilog -I $::env(INCLUDE_DIR) $::env(VERILOG_DIR)/Memory.v
read_verilog -I $::env(INCLUDE_DIR) $::env(VERILOG_DIR)/MatMul_Controller.v
read_verilog -I $::env(INCLUDE_DIR) $::env(VERILOG_DIR)/Control.v
read_verilog -I $::env(INCLUDE_DIR) $::env(VERILOG_DIR)/HAI_Processor.v

# Elaborate hierarchy
hierarchy -check -top $::env(DESIGN_TOP)

# High-level synthesis
proc

# Flatten design (optional, for better optimization)
# flatten

# Technology mapping
techmap

# Optimize
opt -full

# Map to standard cells
abc -liberty $::env(PLATFORM)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Clean up
opt_clean

# Statistics
stat -liberty $::env(PLATFORM)/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Write outputs
write_verilog $::env(RESULTS_DIR)/synth.v
write_json $::env(RESULTS_DIR)/synth.json

puts "=== Synthesis Complete ==="
