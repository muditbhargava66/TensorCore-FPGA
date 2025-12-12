# =============================================================================
# OpenROAD Routing Script
# TensorCore-FPGA - SKY130 PDK
# =============================================================================

# Read database from CTS
read_db $::env(RESULTS_DIR)/cts.odb

# Read timing constraints
read_sdc ../constraint.sdc

# =============================================================================
# Global Routing
# =============================================================================

puts "=== Running Global Routing ==="

set_global_routing_layer_adjustment met1 0.8
set_global_routing_layer_adjustment met2 0.7
set_global_routing_layer_adjustment met3 0.7
set_global_routing_layer_adjustment met4 0.5
set_global_routing_layer_adjustment met5 0.5

set_routing_layers -signal met1-met5 -clock met3-met5

global_route \
    -guide_file $::env(RESULTS_DIR)/route.guide \
    -overflow_iterations 100 \
    -allow_congestion \
    -verbose

# =============================================================================
# Detailed Routing
# =============================================================================

puts "=== Running Detailed Routing ==="

set_thread_count [exec nproc]

detailed_route \
    -output_drc $::env(REPORTS_DIR)/route_drc.rpt \
    -output_maze $::env(RESULTS_DIR)/maze.log \
    -bottom_routing_layer met1 \
    -top_routing_layer met5 \
    -save_guide_updates \
    -verbose 1

# =============================================================================
# Post-Route Optimization
# =============================================================================

puts "=== Post-Route Optimization ==="

# Extract parasitics
estimate_parasitics -global_routing

# Repair timing after routing
repair_timing -setup -hold

# =============================================================================
# DRC Check
# =============================================================================

check_routes -report_file $::env(REPORTS_DIR)/drc_check.rpt

# =============================================================================
# Write Output
# =============================================================================

write_def $::env(RESULTS_DIR)/route.def
write_db $::env(RESULTS_DIR)/route.odb

puts "=== Routing Complete ==="
