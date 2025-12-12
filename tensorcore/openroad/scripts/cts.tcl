# =============================================================================
# OpenROAD Clock Tree Synthesis Script
# TensorCore-FPGA - SKY130 PDK
# =============================================================================

# Read database from placement
read_db $::env(RESULTS_DIR)/place.odb

# Read timing constraints
read_sdc ../constraint.sdc

# =============================================================================
# CTS Configuration
# =============================================================================

puts "=== Running Clock Tree Synthesis ==="

# Set CTS buffer cells
set_wire_rc -clock \
    -layer met3

# Configure clock tree
configure_cts_characterization \
    -max_cap 1.5e-12 \
    -max_slew 0.5e-9

# =============================================================================
# Clock Tree Synthesis
# =============================================================================

clock_tree_synthesis \
    -root_buf sky130_fd_sc_hd__clkbuf_16 \
    -buf_list {sky130_fd_sc_hd__clkbuf_1 sky130_fd_sc_hd__clkbuf_2 sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_8 sky130_fd_sc_hd__clkbuf_16} \
    -sink_clustering_enable \
    -sink_clustering_size 25 \
    -sink_clustering_max_diameter 50

# =============================================================================
# Post-CTS Optimization
# =============================================================================

puts "=== Post-CTS Optimization ==="

# Estimate parasitics with clock tree
estimate_parasitics -placement

# Repair clock nets
repair_clock_nets

# Repair timing
repair_timing

# Legalize after CTS buffer insertion
detailed_placement
check_placement

# =============================================================================
# Report Clock Tree
# =============================================================================

report_clock_skew

# =============================================================================
# Write Output
# =============================================================================

write_def $::env(RESULTS_DIR)/cts.def
write_db $::env(RESULTS_DIR)/cts.odb

puts "=== CTS Complete ==="
