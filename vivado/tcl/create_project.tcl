# =============================================================================
# TensorCore-FPGA - Vivado Project Creation Script
# Target Board: PYNQ-Z1 (Digilent/TUL)
# FPGA: Zynq-7020 (XC7Z020-1CLG400C)
# =============================================================================
# Usage (on Windows with Vivado):
#   cd tensorcore/vivado/tcl
#   vivado -mode batch -source create_project.tcl
# =============================================================================

# Project settings
set project_name "tensorcore"
set project_dir  "../build"
set part         "xc7z020clg400-1"

# PYNQ-Z1 board part (if board files installed)
# Install from: https://github.com/Digilent/vivado-boards
# set board "www.digilentinc.com:pynq-z1:part0:1.0"

# Source directories (relative to tcl/ directory)
set rtl_dir      "../../rtl/core"
set include_dir  "../../rtl/include"
set vivado_src   "../src"
set constraints  "../constraints"

# =============================================================================
# Create Project
# =============================================================================

# Delete existing project if present
if {[file exists $project_dir]} {
    file delete -force $project_dir
}

create_project $project_name $project_dir -part $part -force

# Try to set board part (may fail if board files not installed)
# catch {set_property board_part www.digilentinc.com:pynq-z1:part0:1.0 [current_project]}

# =============================================================================
# Add Source Files
# =============================================================================

# Add RTL core files
set rtl_files [glob -nocomplain $rtl_dir/*.v]
if {[llength $rtl_files] > 0} {
    add_files -norecurse $rtl_files
    puts "Added [llength $rtl_files] RTL files from $rtl_dir"
}

# Add Vivado wrapper sources
set vivado_files [glob -nocomplain $vivado_src/*.v]
if {[llength $vivado_files] > 0} {
    add_files -norecurse $vivado_files
    puts "Added [llength $vivado_files] wrapper files from $vivado_src"
}

# Add include directories for `include directives
set_property include_dirs [list $include_dir $rtl_dir] [current_fileset]

# =============================================================================
# Add Constraints (PYNQ-Z1)
# =============================================================================

# Use PYNQ-Z1 constraints
add_files -fileset constrs_1 -norecurse $constraints/pynq_z1.xdc
set_property used_in_synthesis true [get_files $constraints/pynq_z1.xdc]
set_property used_in_implementation true [get_files $constraints/pynq_z1.xdc]

# =============================================================================
# Set Top Module and Fileset Properties
# =============================================================================

# For standalone PL testing, use TensorCore_PL_Top (simpler, no PS)
# For full integration, change to TensorCore or TensorCore_AXI_Wrapper
set_property top TensorCore_PL_Top [current_fileset]

# Set Verilog as default HDL
set_property target_language Verilog [current_project]

# =============================================================================
# Synthesis Settings
# =============================================================================

# Default synthesis run
set synth_run [get_runs synth_1]

# Optimize for area (good for initial testing)
set_property strategy {Vivado Synthesis Defaults} $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE AreaOptimized_medium $synth_run

# Flatten hierarchy for better optimization
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt $synth_run

# =============================================================================
# Implementation Settings
# =============================================================================

set impl_run [get_runs impl_1]

# Use balanced strategy
set_property strategy {Vivado Implementation Defaults} $impl_run

# =============================================================================
# Create Reports Directory
# =============================================================================

file mkdir $project_dir/reports

# =============================================================================
# Print Summary
# =============================================================================

puts ""
puts "=============================================="
puts "  TensorCore-FPGA - Vivado Project Created"
puts "=============================================="
puts ""
puts "  Project:     $project_dir/$project_name.xpr"
puts "  Target:      PYNQ-Z1 (XC7Z020-1CLG400C)"
puts "  Top Module:  TensorCore_PL_Top"
puts "  Constraints: pynq_z1.xdc"
puts ""
puts "  Next Steps (on Windows with Vivado):"
puts ""
puts "  1. Open project in Vivado GUI:"
puts "     vivado $project_dir/$project_name.xpr"
puts ""
puts "  2. Run synthesis:"
puts "     launch_runs synth_1 -jobs 4"
puts "     wait_on_run synth_1"
puts ""
puts "  3. Run implementation:"
puts "     launch_runs impl_1 -jobs 4"
puts "     wait_on_run impl_1"
puts ""
puts "  4. Generate bitstream:"
puts "     write_bitstream -force $project_dir/tensorcore.bit"
puts ""
puts "=============================================="
