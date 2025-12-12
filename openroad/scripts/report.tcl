# =============================================================================
# OpenROAD Report Generation Script
# Generates area and power estimates
# =============================================================================

# Read design database
read_db $::env(RESULTS_DIR)/finish.odb

# =============================================================================
# Area Report
# =============================================================================

puts "=============================================="
puts "AREA REPORT"
puts "=============================================="

report_design_area > $::env(REPORTS_DIR)/area.rpt

# Detailed cell count
set fp [open "$::env(REPORTS_DIR)/area.rpt" a]
puts $fp ""
puts $fp "=== Detailed Cell Statistics ==="
puts $fp ""
close $fp

report_cell_usage >> $::env(REPORTS_DIR)/area.rpt

# =============================================================================
# Power Report
# =============================================================================

puts "=============================================="
puts "POWER REPORT"
puts "=============================================="

# Read activity file if available
# read_sdc $::env(SDC_FILE)
# read_spef $::env(RESULTS_DIR)/finish.spef

# Estimate power (without activity, uses default switching)
report_power > $::env(REPORTS_DIR)/power.rpt

# =============================================================================
# Timing Report
# =============================================================================

puts "=============================================="
puts "TIMING REPORT"
puts "=============================================="

report_worst_slack -max > $::env(REPORTS_DIR)/timing.rpt
report_tns >> $::env(REPORTS_DIR)/timing.rpt
report_wns >> $::env(REPORTS_DIR)/timing.rpt

# Critical path
report_checks -path_delay max -format full >> $::env(REPORTS_DIR)/timing.rpt

# =============================================================================
# DRC Report
# =============================================================================

puts "=============================================="
puts "DRC REPORT"
puts "=============================================="

report_drc > $::env(REPORTS_DIR)/drc.rpt

# =============================================================================
# Summary
# =============================================================================

puts ""
puts "=============================================="
puts "REPORT SUMMARY"
puts "=============================================="
puts ""
puts "Reports generated:"
puts "  - $::env(REPORTS_DIR)/area.rpt"
puts "  - $::env(REPORTS_DIR)/power.rpt"
puts "  - $::env(REPORTS_DIR)/timing.rpt"
puts "  - $::env(REPORTS_DIR)/drc.rpt"
puts ""
puts "=============================================="

exit
