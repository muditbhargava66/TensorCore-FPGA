# =============================================================================
# TensorCore-FPGA - Vivado Block Design Creation Script
# Target Board: PYNQ-Z1 (Digilent/TUL)
# FPGA: Zynq-7020 (XC7Z020-1CLG400C)
# =============================================================================
# This script creates a complete block design with:
# - ZYNQ7 Processing System (PS)
# - TensorCore accelerator as AXI peripheral
# - Proper clock and reset management
# =============================================================================
# Usage (on Windows with Vivado):
#   cd tensorcore/vivado/tcl
#   vivado -mode batch -source create_block_design.tcl
# =============================================================================

# Load project (must run create_project.tcl first)
set project_dir  "../build"
set project_name "tensorcore"

# Check if project exists
if {![file exists $project_dir/$project_name.xpr]} {
    puts "ERROR: Project not found. Run create_project.tcl first."
    exit 1
}

open_project $project_dir/$project_name.xpr

# =============================================================================
# Create Block Design
# =============================================================================

set bd_name "tensorcore_system"

# Delete existing block design if present
if {[get_bd_designs -quiet $bd_name] != ""} {
    close_bd_design [get_bd_designs $bd_name]
    delete_bd_objs -quiet [get_bd_designs $bd_name]
}

create_bd_design $bd_name

# =============================================================================
# Add ZYNQ7 Processing System
# =============================================================================

puts "Adding ZYNQ7 Processing System..."

# Create and configure the Zynq PS
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

# Apply PYNQ-Z1 preset (if board files installed)
# This configures DDR, clocks, and peripherals for PYNQ-Z1
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {0} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
] [get_bd_cells processing_system7_0]

# PYNQ-Z1 DDR Configuration (DDR3 512MB)
set_property -dict [list \
    CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41K256M16 RE-125} \
    CONFIG.PCW_UIPARAM_DDR_DEVICE_CAPACITY {4096 MBits} \
    CONFIG.PCW_UIPARAM_DDR_DRAM_WIDTH {16 Bits} \
] [get_bd_cells processing_system7_0]

# UART Configuration (for console output)
set_property -dict [list \
    CONFIG.PCW_UART0_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_UART0_UART0_IO {MIO 14 .. 15} \
] [get_bd_cells processing_system7_0]

# =============================================================================
# Add TensorCore IP
# =============================================================================

puts "Adding TensorCore accelerator..."

# Package and add TensorCore as an IP
# First, we need to add it as an RTL module to the block design
create_bd_cell -type module -reference TensorCore_PYNQ_Top tensorcore_0

# =============================================================================
# Add Processor System Reset
# =============================================================================

puts "Adding Processor System Reset..."
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0

# =============================================================================
# Create Connections
# =============================================================================

puts "Creating connections..."

# Clock connections
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins tensorcore_0/S_AXI_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins proc_sys_reset_0/slowest_sync_clk]

# Reset connections
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
               [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
               [get_bd_pins tensorcore_0/S_AXI_ARESETN]

# AXI Interconnect for GP0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property CONFIG.NUM_MI {1} [get_bd_cells axi_interconnect_0]

# Connect AXI interconnect clocks and resets
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins axi_interconnect_0/M00_ACLK]

connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] \
               [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
               [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
               [get_bd_pins axi_interconnect_0/M00_ARESETN]

# Connect PS to interconnect
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
                    [get_bd_intf_pins axi_interconnect_0/S00_AXI]

# Connect interconnect to TensorCore
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] \
                    [get_bd_intf_pins tensorcore_0/S_AXI]

# =============================================================================
# Create External LED Ports
# =============================================================================

puts "Creating external ports..."

# LED outputs
create_bd_port -dir O led_done
create_bd_port -dir O led_busy
create_bd_port -dir O -from 1 -to 0 led_state

connect_bd_net [get_bd_pins tensorcore_0/led_done] [get_bd_ports led_done]
connect_bd_net [get_bd_pins tensorcore_0/led_busy] [get_bd_ports led_busy]
connect_bd_net [get_bd_pins tensorcore_0/led_state] [get_bd_ports led_state]

# =============================================================================
# Address Assignment
# =============================================================================

puts "Assigning addresses..."

# Assign address to TensorCore (0x43C00000 range for AXI GP0)
assign_bd_address -target_address_space /processing_system7_0/Data \
                  -offset 0x43C00000 \
                  -range 256 \
                  [get_bd_addr_segs tensorcore_0/S_AXI/reg0]

# =============================================================================
# Validate and Save Design
# =============================================================================

puts "Validating block design..."
validate_bd_design

# Regenerate layout
regenerate_bd_layout

# Save block design
save_bd_design

# =============================================================================
# Generate HDL Wrapper
# =============================================================================

puts "Generating HDL wrapper..."

set wrapper_file [make_wrapper -files [get_files $bd_name.bd] -top]
add_files -norecurse $wrapper_file
set_property top ${bd_name}_wrapper [current_fileset]

# =============================================================================
# Update Compile Order
# =============================================================================

update_compile_order -fileset sources_1

# =============================================================================
# Print Summary
# =============================================================================

puts ""
puts "=============================================="
puts "  Block Design Created Successfully"
puts "=============================================="
puts ""
puts "  Design Name:  $bd_name"
puts "  Top Module:   ${bd_name}_wrapper"
puts "  PS Clock:     100 MHz (FCLK_CLK0)"
puts "  TensorCore:   0x43C00000 - 0x43C000FF"
puts ""
puts "  Next Steps:"
puts "  1. vivado -mode batch -source run_synth.tcl"
puts "  2. Or open project in GUI: vivado $project_dir/$project_name.xpr"
puts ""
puts "=============================================="

close_project
