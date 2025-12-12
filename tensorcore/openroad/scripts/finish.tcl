# =============================================================================
# OpenROAD Finish Script
# TensorCore-FPGA - SKY130 PDK
# =============================================================================

# Read database from routing
read_db $::env(RESULTS_DIR)/route.odb

# Read timing constraints
read_sdc ../constraint.sdc

# =============================================================================
# Metal Fill
# =============================================================================

puts "=== Adding Metal Fill ==="

# Density fill for manufacturing
density_fill \
    -rules $::env(PDK_ROOT)/sky130A/libs.tech/openlane/rules.lydrc

# =============================================================================
# Final Timing Analysis
# =============================================================================

puts "=== Final Timing Analysis ==="

# Read parasitics (if SPEF available)
# read_spef $::env(RESULTS_DIR)/finish.spef

# Estimate parasitics
estimate_parasitics -global_routing

# Report timing
report_worst_slack -max
report_worst_slack -min
report_tns
report_wns

# =============================================================================
# Final Reports
# =============================================================================

puts "=== Generating Final Reports ==="

report_design_area > $::env(REPORTS_DIR)/final_area.rpt
report_power > $::env(REPORTS_DIR)/final_power.rpt
report_checks -path_delay max -format full > $::env(REPORTS_DIR)/final_timing.rpt

# =============================================================================
# Write Final Outputs
# =============================================================================

write_def $::env(RESULTS_DIR)/finish.def
write_db $::env(RESULTS_DIR)/finish.odb
write_verilog $::env(RESULTS_DIR)/finish.v

# Write GDS (if KLayout available)
# write_gds $::env(RESULTS_DIR)/finish.gds

puts ""
puts "=============================================="
puts "  ASIC Flow Complete!"
puts "=============================================="
puts ""
puts "  Final outputs in: $::env(RESULTS_DIR)/"
puts "  Reports in: $::env(REPORTS_DIR)/"
puts ""
puts "=============================================="
