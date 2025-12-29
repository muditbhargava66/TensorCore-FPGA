# =============================================================================
# TensorCore-FPGA - Complete Build Script
# Target Board: PYNQ-Z1 (Digilent/TUL)
# FPGA: Zynq-7020 (XC7Z020-1CLG400C)
# =============================================================================
# This script performs a complete build:
# 1. Creates Vivado project
# 2. Creates block design with Zynq PS
# 3. Runs synthesis
# 4. Runs implementation
# 5. Generates bitstream
# 6. Exports hardware handoff (.hwh) file for PYNQ
# =============================================================================
# Usage (on Windows with Vivado):
#   cd tensorcore/vivado
#   vivado -mode batch -source tcl/build_all.tcl
# =============================================================================

# Capture start time
set start_time [clock seconds]

puts ""
puts "=============================================="
puts "  TensorCore-FPGA - PYNQ-Z1 Build"
puts "=============================================="
puts "  Start Time: [clock format $start_time -format {%Y-%m-%d %H:%M:%S}]"
puts "=============================================="
puts ""

# Get absolute path of script directory
set script_dir [file dirname [file normalize [info script]]]
set vivado_dir [file dirname $script_dir]
set project_root [file dirname $vivado_dir]

puts "Script directory: $script_dir"
puts "Vivado directory: $vivado_dir"
puts "Project root: $project_root"

# Project settings
set project_name "tensorcore"
set project_dir  [file join $vivado_dir "build"]
set part         "xc7z020clg400-1"
set num_jobs     4

# Source directories (now absolute)
set rtl_dir      [file join $project_root "src" "core"]
set include_dir  [file join $project_root "src" "include"]
set vivado_src   [file join $vivado_dir "src"]
set constraints_dir [file join $vivado_dir "constraints"]

puts "\nSource directories:"
puts "  RTL:         $rtl_dir"
puts "  Include:     $include_dir"
puts "  Vivado Src:  $vivado_src"
puts "  Constraints: $constraints_dir"

# =============================================================================
# Step 1: Create Project
# =============================================================================

puts "\n=== Step 1: Creating Project ===\n"

# Use a clean build directory - if it exists and is locked, use a new name
set build_suffix ""
if {[file exists $project_dir]} {
    puts "Build directory exists, attempting to clean..."
    if {[catch {file delete -force $project_dir} err]} {
        puts "  Could not delete existing directory: $err"
        set build_suffix "_[clock format [clock seconds] -format %H%M%S]"
        set project_dir "[file join $vivado_dir build${build_suffix}]"
        puts "  Using alternative build directory: $project_dir"
    }
}

# Create project directory
file mkdir $project_dir

create_project $project_name $project_dir -part $part -force

# Try to set board part
catch {set_property board_part digilentinc.com:pynq-z1:part0:1.0 [current_project]}


# =============================================================================
# Step 2: Add Source Files
# =============================================================================

puts "\n=== Step 2: Adding Source Files ===\n"

# Add synthesizable core files
set synth_core_files [list \
    [file join $rtl_dir "PE.v"] \
    [file join $rtl_dir "PE_Synth.v"] \
    [file join $rtl_dir "MAC.v"] \
    [file join $rtl_dir "SA_MxN.v"] \
    [file join $rtl_dir "SA_MxN_Synth.v"] \
    [file join $rtl_dir "PerfMonitor.v"] \
    [file join $rtl_dir "VPU_Synth.v"] \
]

set files_added 0
foreach f $synth_core_files {
    if {[file exists $f]} {
        add_files -norecurse $f
        puts "  Added: [file tail $f]"
        incr files_added
    } else {
        puts "  WARNING: File not found: $f"
    }
}
puts "  Core files added: $files_added"

# Add all Vivado wrapper sources
set vivado_files [glob -nocomplain [file join $vivado_src "*.v"]]
foreach f $vivado_files {
    add_files -norecurse $f
    puts "  Added: [file tail $f]"
}
puts "  Vivado wrapper files added: [llength $vivado_files]"

# Add header files (.vh) as source files - required for RTL modules in block design
puts "  Adding header files..."
set include_files [glob -nocomplain [file join $include_dir "*.vh"]]
foreach f $include_files {
    add_files -norecurse $f
    puts "  Added header: [file tail $f]"
}
puts "  Header files added: [llength $include_files]"

# Add include directories (absolute paths)
set_property include_dirs [list $include_dir $rtl_dir $vivado_src] [current_fileset]
puts "  Include directories set"

# Update compile order to automatic
update_compile_order -fileset sources_1
set_property source_mgmt_mode All [current_project]


# =============================================================================
# Step 3: Add Constraints
# =============================================================================

puts "\n=== Step 3: Adding Constraints ===\n"

# Add PS constraints
set ps_xdc [file join $constraints_dir "pynq_z1_ps.xdc"]
if {[file exists $ps_xdc]} {
    add_files -fileset constrs_1 -norecurse $ps_xdc
    puts "  Added: pynq_z1_ps.xdc"
} else {
    puts "  WARNING: PS constraints not found: $ps_xdc"
}

# =============================================================================
# Step 4: Create Block Design with Zynq PS
# =============================================================================

puts "\n=== Step 4: Creating Block Design ===\n"

# Refresh compile order to pick up all modules
update_compile_order -fileset sources_1

set bd_name "tensorcore_system"

create_bd_design $bd_name

# Add ZYNQ7 Processing System
puts "  Adding Zynq PS..."
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

# Configure PS for PYNQ-Z1
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {70} \
    CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41K256M16 RE-125} \
    CONFIG.PCW_UART0_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_UART0_UART0_IO {MIO 14 .. 15} \
] [get_bd_cells processing_system7_0]

# Apply block automation for DDR/Fixed IO
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" } \
    [get_bd_cells processing_system7_0]

# Add TensorCore as RTL module
puts "  Adding TensorCore RTL module..."
create_bd_cell -type module -reference TensorCore_PYNQ_Top tensorcore_0

# Add Processor System Reset
puts "  Adding Processor System Reset..."
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0

# Add AXI Interconnect
puts "  Adding AXI Interconnect..."
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property CONFIG.NUM_MI {1} [get_bd_cells axi_interconnect_0]

# Connect clocks
puts "  Connecting clocks..."
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins tensorcore_0/S_AXI_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins axi_interconnect_0/M00_ACLK]
# Connect PS GP0 AXI clock (required for Zynq)
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]

# Connect resets
puts "  Connecting resets..."
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
               [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
               [get_bd_pins tensorcore_0/S_AXI_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] \
               [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
               [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
               [get_bd_pins axi_interconnect_0/M00_ARESETN]

# Connect AXI interfaces
puts "  Connecting AXI interfaces..."
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
                    [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] \
                    [get_bd_intf_pins tensorcore_0/S_AXI]

# Create external LED ports
puts "  Creating LED ports..."
create_bd_port -dir O led_done
create_bd_port -dir O led_busy  
create_bd_port -dir O -from 1 -to 0 led_state

connect_bd_net [get_bd_pins tensorcore_0/led_done] [get_bd_ports led_done]
connect_bd_net [get_bd_pins tensorcore_0/led_busy] [get_bd_ports led_busy]
connect_bd_net [get_bd_pins tensorcore_0/led_state] [get_bd_ports led_state]

# Assign address
puts "  Assigning addresses..."
assign_bd_address -offset 0x43C00000 -range 256 \
    [get_bd_addr_segs {tensorcore_0/S_AXI/reg0}]

# Validate and save
puts "  Validating block design..."
validate_bd_design
save_bd_design

# Generate wrapper
puts "  Generating HDL wrapper..."
set wrapper_file [make_wrapper -files [get_files $bd_name.bd] -top]
add_files -norecurse $wrapper_file
set_property top ${bd_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1

puts "  Block design created successfully"

# =============================================================================
# Step 5: Synthesis
# =============================================================================

puts "\n=== Step 5: Running Synthesis ===\n"

set synth_run [get_runs synth_1]
set_property strategy {Vivado Synthesis Defaults} $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE AreaOptimized_medium $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt $synth_run

reset_run synth_1
launch_runs synth_1 -jobs $num_jobs
wait_on_run synth_1

# Check synthesis status
set synth_status [get_property STATUS [get_runs synth_1]]
puts "  Synthesis status: $synth_status"

if {[string match "*ERROR*" $synth_status] || [string match "*FAILED*" $synth_status]} {
    puts "ERROR: Synthesis failed!"
    exit 1
}

# =============================================================================
# Step 6: Implementation  
# =============================================================================

puts "\n=== Step 6: Running Implementation ===\n"

set impl_run [get_runs impl_1]
set_property strategy {Vivado Implementation Defaults} $impl_run

launch_runs impl_1 -jobs $num_jobs
wait_on_run impl_1

# Check implementation status
set impl_status [get_property STATUS [get_runs impl_1]]
puts "  Implementation status: $impl_status"

if {[string match "*ERROR*" $impl_status] || [string match "*FAILED*" $impl_status]} {
    puts "ERROR: Implementation failed!"
    exit 1
}

# =============================================================================
# Step 7: Generate Bitstream
# =============================================================================

puts "\n=== Step 7: Generating Bitstream ===\n"

launch_runs impl_1 -to_step write_bitstream -jobs $num_jobs
wait_on_run impl_1

# Copy bitstream to output directory
set output_dir [file join $project_dir "output"]
file mkdir $output_dir
file copy -force [file join $project_dir "${project_name}.runs" "impl_1" "${bd_name}_wrapper.bit"] \
                 [file join $output_dir "tensorcore.bit"]

puts "  Bitstream generated: [file join $output_dir tensorcore.bit]"

# =============================================================================
# Step 8: Export Hardware for PYNQ
# =============================================================================

puts "\n=== Step 8: Exporting Hardware ===\n"

# Copy the correct HWH file from hw_handoff directory (valid XML format)
# Note: write_hwdef is deprecated and can produce corrupted output
set hwh_source [file join $project_dir "${project_name}.gen" "sources_1" "bd" $bd_name "hw_handoff" "${bd_name}.hwh"]
if {[file exists $hwh_source]} {
    file copy -force $hwh_source [file join $output_dir "tensorcore.hwh"]
    puts "  HWH copied from: $hwh_source"
} else {
    puts "WARNING: HWH file not found at expected location: $hwh_source"
    # Fallback: try open_run and write_hwdef (may be corrupted)
    open_run impl_1
    write_hwdef -force [file join $output_dir "tensorcore.hwh"]
}

# Also create XSA file (for Vitis if needed)
open_run impl_1
write_hw_platform -fixed -force -include_bit [file join $output_dir "tensorcore.xsa"]

puts "  Hardware files exported to: $output_dir"

# =============================================================================
# Step 9: Generate Reports
# =============================================================================

puts "\n=== Step 9: Generating Reports ===\n"

set reports_dir [file join $project_dir "reports"]
file mkdir $reports_dir
report_utilization -file [file join $reports_dir "utilization.rpt"]
report_timing_summary -file [file join $reports_dir "timing_summary.rpt"]
report_power -file [file join $reports_dir "power.rpt"]

puts "  Reports generated in: $reports_dir"

# =============================================================================
# Build Complete
# =============================================================================

set end_time [clock seconds]
set elapsed [expr $end_time - $start_time]
set elapsed_min [expr $elapsed / 60]
set elapsed_sec [expr $elapsed % 60]

puts ""
puts "=============================================="
puts "  BUILD COMPLETE"
puts "=============================================="
puts ""
puts "  Output Files:"
puts "    Bitstream: [file join $output_dir tensorcore.bit]"
puts "    HWH File:  [file join $output_dir tensorcore.hwh]"
puts "    XSA File:  [file join $output_dir tensorcore.xsa]"
puts ""
puts "  Reports:"
puts "    [file join $reports_dir utilization.rpt]"
puts "    [file join $reports_dir timing_summary.rpt]"
puts "    [file join $reports_dir power.rpt]"
puts ""
puts "  Build Time: ${elapsed_min}m ${elapsed_sec}s"
puts ""
puts "  Next Steps:"
puts "    1. Copy tensorcore.bit and tensorcore.hwh to PYNQ board"
puts "    2. Use the PYNQ Overlay() class to load the bitstream"
puts ""
puts "=============================================="

close_project
