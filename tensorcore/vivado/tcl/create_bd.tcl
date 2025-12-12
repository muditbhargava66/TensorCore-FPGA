# =============================================================================
# TensorCore-FPGA - Zynq PS Block Design
# Target: PYNQ-Z1 (Zynq-7020)
# =============================================================================
# This script creates a block design with:
# - Zynq PS configured for PYNQ-Z1
# - AXI interconnect for TensorCore
# - TensorCore_AXI_Wrapper as custom IP
# =============================================================================

# Open project
set project_dir "../build"
set project_name "tensorcore"
open_project $project_dir/$project_name.xpr

# =============================================================================
# Create Block Design
# =============================================================================

set bd_name "tensorcore_system"

# Delete existing block design if present
if {[get_bd_designs -quiet $bd_name] != ""} {
    delete_bd_objs [get_bd_designs $bd_name]
}

create_bd_design $bd_name

# =============================================================================
# Add Zynq PS
# =============================================================================

# Add Zynq Processing System
set zynq_ps [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0]

# Apply PYNQ-Z1 preset (if available) or configure manually
# Try to apply board preset
catch {
    apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
        -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable"} \
        [get_bd_cells processing_system7_0]
}

# Configure PS for PYNQ-Z1
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {0} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
    CONFIG.PCW_FCLK0_PERIPHERAL_CLKSRC {ARM PLL} \
    CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
    CONFIG.PCW_IRQ_F2P_INTR {1} \
    CONFIG.PCW_PRESET_BANK0_VOLTAGE {LVCMOS 3.3V} \
    CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
    CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41K256M16 RE-125} \
    CONFIG.PCW_UIPARAM_DDR_FREQ_MHZ {525} \
] $zynq_ps

# =============================================================================
# Add AXI Interconnect
# =============================================================================

set axi_interconnect [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0]
set_property -dict [list CONFIG.NUM_MI {1}] $axi_interconnect

# =============================================================================
# Add TensorCore as RTL Module
# =============================================================================

# Create hierarchy for TensorCore
create_bd_cell -type module -reference TensorCore_AXI_Wrapper tensorcore_0

# =============================================================================
# Connect Clocks and Resets
# =============================================================================

# Create clock port
set fclk0 [get_bd_pins processing_system7_0/FCLK_CLK0]

# Connect clocks
connect_bd_net $fclk0 [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net $fclk0 [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net $fclk0 [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net $fclk0 [get_bd_pins tensorcore_0/S_AXI_ACLK]

# Create reset infrastructure
set proc_sys_reset [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0]
connect_bd_net $fclk0 [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins proc_sys_reset_0/ext_reset_in]

# Connect resets
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins tensorcore_0/S_AXI_ARESETN]

# =============================================================================
# Connect AXI Interfaces
# =============================================================================

# PS GP0 -> Interconnect S00
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
    [get_bd_intf_pins axi_interconnect_0/S00_AXI]

# Interconnect M00 -> TensorCore
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] \
    [get_bd_intf_pins tensorcore_0/S_AXI]

# =============================================================================
# Address Mapping
# =============================================================================

# Assign address for TensorCore (base: 0x43C00000, size: 4KB)
assign_bd_address -target_address_space /processing_system7_0/Data \
    [get_bd_addr_segs tensorcore_0/S_AXI/reg0] \
    -range 4K -offset 0x43C00000

# =============================================================================
# Make External Connections
# =============================================================================

# DDR and Fixed IO
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR"} \
    [get_bd_cells processing_system7_0]

# =============================================================================
# Validate and Save
# =============================================================================

validate_bd_design
save_bd_design

# Generate wrapper
make_wrapper -files [get_files $project_dir/$project_name.srcs/sources_1/bd/$bd_name/$bd_name.bd] -top
add_files -norecurse $project_dir/$project_name.gen/sources_1/bd/$bd_name/hdl/${bd_name}_wrapper.v
update_compile_order -fileset sources_1

# Set wrapper as top
set_property top ${bd_name}_wrapper [current_fileset]

puts ""
puts "=============================================="
puts "  Block Design Created: $bd_name"
puts "=============================================="
puts "  TensorCore mapped at: 0x43C00000"
puts "  Size: 4KB"
puts "=============================================="

close_project
