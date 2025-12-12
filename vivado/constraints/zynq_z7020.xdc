## =============================================================================
## HAI Processor - Xilinx Zynq-7020 Constraints (PYNQ-Z2 Board)
## =============================================================================

## Clock - 125 MHz from PS
create_clock -period 8.000 -name clk_125mhz [get_ports clk]

## Reset - Active High
set_property IOSTANDARD LVCMOS33 [get_ports reset]
set_property PACKAGE_PIN D19 [get_ports reset]

## LED Outputs (for debug)
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN R14 [get_ports {led[0]}]
set_property PACKAGE_PIN P14 [get_ports {led[1]}]
set_property PACKAGE_PIN N16 [get_ports {led[2]}]
set_property PACKAGE_PIN M14 [get_ports {led[3]}]

## Button Inputs
set_property IOSTANDARD LVCMOS33 [get_ports {btn[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[1]}]
set_property PACKAGE_PIN D19 [get_ports {btn[0]}]
set_property PACKAGE_PIN D20 [get_ports {btn[1]}]

## =============================================================================
## Timing Constraints
## =============================================================================

## Clock uncertainty
set_clock_uncertainty 0.100 [get_clocks clk_125mhz]

## Input delay (from PS to PL)
set_input_delay -clock clk_125mhz -max 2.0 [get_ports {s_axi_*}]
set_input_delay -clock clk_125mhz -min 0.5 [get_ports {s_axi_*}]

## Output delay (from PL to PS)
set_output_delay -clock clk_125mhz -max 2.0 [get_ports {s_axi_*}]
set_output_delay -clock clk_125mhz -min 0.5 [get_ports {s_axi_*}]

## =============================================================================
## Area Constraints (Optional - for placement guidance)
## =============================================================================

## Create pblock for systolic array
# create_pblock pblock_sa
# resize_pblock pblock_sa -add {SLICE_X0Y0:SLICE_X50Y50}
# add_cells_to_pblock pblock_sa [get_cells -hierarchical -filter {NAME =~ *sa_inst*}]

## =============================================================================
## Power Optimization
## =============================================================================

## Enable clock gating for low power
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk]

## Mark false paths for async resets
set_false_path -from [get_ports reset]
