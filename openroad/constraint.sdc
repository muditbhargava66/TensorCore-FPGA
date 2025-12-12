# =============================================================================
# HAI Processor - SDC Timing Constraints
# For OpenROAD ASIC Flow
# =============================================================================

# Clock definition
# Target: 100 MHz (10ns period)
create_clock -name clk -period 10.0 [get_ports clk]

# Clock uncertainty
set_clock_uncertainty 0.5 [get_clocks clk]

# Clock latency
set_clock_latency -source 0.5 [get_clocks clk]

# =============================================================================
# Input Constraints
# =============================================================================

# All inputs except clock
set_input_delay -clock clk -max 2.0 [get_ports -filter {NAME !~ clk}]
set_input_delay -clock clk -min 0.5 [get_ports -filter {NAME !~ clk}]

# Reset is asynchronous
set_false_path -from [get_ports reset]

# =============================================================================
# Output Constraints
# =============================================================================

set_output_delay -clock clk -max 2.0 [all_outputs]
set_output_delay -clock clk -min 0.5 [all_outputs]

# =============================================================================
# Design Rule Constraints
# =============================================================================

# Maximum fanout
set_max_fanout 20 [current_design]

# Maximum transition
set_max_transition 0.5 [current_design]

# Maximum capacitance
set_max_capacitance 0.5 [current_design]

# =============================================================================
# Multicycle Paths (if any)
# =============================================================================

# Memory read typically takes 2 cycles
# set_multicycle_path 2 -setup -from [get_pins *memory_inst*] -to [get_pins *_tile*]

# =============================================================================
# False Paths
# =============================================================================

# Performance counters are read asynchronously by software
set_false_path -to [get_ports perf_*]

# =============================================================================
# Area / Power Targets (optional hints)
# =============================================================================

# Target utilization for placement
# set_utilization 0.70
