# =============================================================================
# TensorCore-FPGA - Vivado Implementation Script
# =============================================================================

# Open project
set project_dir "../build"
set project_name "tensorcore"
open_project $project_dir/$project_name.xpr

# =============================================================================
# Run Implementation
# =============================================================================

puts ""
puts "=============================================="
puts "  Running Implementation..."
puts "=============================================="
puts ""

# Reset implementation run
reset_run impl_1

# Launch implementation
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Check status
set impl_status [get_property STATUS [get_runs impl_1]]
puts "Implementation status: $impl_status"

if {[string match "*ERROR*" $impl_status]} {
    puts "ERROR: Implementation failed!"
    close_project
    exit 1
}

# =============================================================================
# Generate Reports
# =============================================================================

puts ""
puts "=============================================="
puts "  Generating Reports..."
puts "=============================================="
puts ""

open_run impl_1

# Create reports directory
file mkdir $project_dir/reports

# Utilization report
report_utilization -file $project_dir/reports/utilization_impl.rpt
puts "Generated: utilization_impl.rpt"

# Timing report
report_timing_summary -file $project_dir/reports/timing_impl.rpt
puts "Generated: timing_impl.rpt"

# Power report
report_power -file $project_dir/reports/power_impl.rpt
puts "Generated: power_impl.rpt"

# IO report
report_io -file $project_dir/reports/io_impl.rpt
puts "Generated: io_impl.rpt"

# Clock utilization
report_clock_utilization -file $project_dir/reports/clock_impl.rpt
puts "Generated: clock_impl.rpt"

# DRC
report_drc -file $project_dir/reports/drc.rpt
puts "Generated: drc.rpt"

# =============================================================================
# Print Summary
# =============================================================================

puts ""
puts "=============================================="
puts "  Implementation Complete!"
puts "=============================================="
puts ""
puts "  Reports saved to: $project_dir/reports/"
puts ""
puts "  Next: Run run_bitstream.tcl to generate bitstream"
puts ""
puts "=============================================="

close_project
