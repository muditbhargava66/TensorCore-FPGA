# =============================================================================
# HAI Processor - Vivado Synthesis Script
# Called by build_vivado.bat
# =============================================================================

# Open existing project
set project_dir "../build"
set project_name "hai_processor"

open_project $project_dir/$project_name.xpr

# =============================================================================
# Run Synthesis
# =============================================================================

puts ""
puts "=============================================="
puts "  Running Synthesis..."
puts "=============================================="
puts ""

reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check synthesis status
set synth_status [get_property STATUS [get_runs synth_1]]
puts "Synthesis status: $synth_status"

if {$synth_status != "synth_design Complete!"} {
    puts "WARNING: Synthesis may not have completed successfully"
}

# =============================================================================
# Generate Synthesis Reports
# =============================================================================

open_run synth_1

file mkdir $project_dir/reports

report_utilization -file $project_dir/reports/utilization_synth.rpt
report_timing_summary -file $project_dir/reports/timing_synth.rpt

puts ""
puts "=============================================="
puts "  Synthesis Reports Generated"
puts "=============================================="
puts ""
puts "  - $project_dir/reports/utilization_synth.rpt"
puts "  - $project_dir/reports/timing_synth.rpt"
puts ""

# Print quick summary
puts "=== Resource Utilization Summary ==="
report_utilization -hierarchical -hierarchical_depth 2

close_project
