# TensorCore TinyTapeout Timing Constraints
# Target: 50 MHz (20ns period) with margin for 100 MHz upgrade path

# Clock definition
create_clock -name clk -period 20.0 [get_ports clk]

# Clock uncertainty (for timing margin)
set_clock_uncertainty -setup 0.5 [get_clocks clk]
set_clock_uncertainty -hold 0.1 [get_clocks clk]

# Input delays (assume 25% of clock period)
set_input_delay -clock clk -max 5.0 [all_inputs]
set_input_delay -clock clk -min 1.0 [all_inputs]

# Output delays
set_output_delay -clock clk -max 5.0 [all_outputs]
set_output_delay -clock clk -min 1.0 [all_outputs]

# Reset is async - treat as false path for timing
set_false_path -from [get_ports rst_n]
set_false_path -from [get_ports ena]

# Max fanout constraint
set_max_fanout 8 [current_design]

# Max transition time
set_max_transition 1.5 [current_design]

# Load for outputs (typical pad load)
set_load 0.05 [all_outputs]

# Driving cell for inputs
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_2 [all_inputs]
