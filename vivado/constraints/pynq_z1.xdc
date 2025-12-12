# =============================================================================
# HAI Processor - Xilinx Design Constraints (XDC)
# Target Board: PYNQ-Z1 (Digilent/TUL)
# FPGA: Zynq-7020 (XC7Z020-1CLG400C)
# =============================================================================
# Reference: PYNQ-Z1 Master XDC from Digilent
# https://github.com/Digilent/digilent-xdc/blob/master/Pynq-Z1-Master.xdc
# =============================================================================

# =============================================================================
# CLOCK - 125 MHz System Clock
# =============================================================================
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }]

# =============================================================================
# RESET - Active High (directly from PS or button)
# =============================================================================
# BTN0 - Active High Reset
set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { reset }]

# =============================================================================
# BUTTONS (directly on board)
# =============================================================================
# BTN0 = D19 (used as reset above)
# BTN1 = D20
# BTN2 = L20
# BTN3 = L19
set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33 } [get_ports { start }]
# set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS33 } [get_ports { btn2 }]
# set_property -dict { PACKAGE_PIN L19   IOSTANDARD LVCMOS33 } [get_ports { btn3 }]

# =============================================================================
# SWITCHES
# =============================================================================
set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS33 } [get_ports { vpu_enable }]
set_property -dict { PACKAGE_PIN M19   IOSTANDARD LVCMOS33 } [get_ports { vpu_op_sel }]
# set_property -dict { PACKAGE_PIN L19   IOSTANDARD LVCMOS33 } [get_ports { sw2 }]
# set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS33 } [get_ports { sw3 }]

# =============================================================================
# LEDS
# =============================================================================
set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { done }]
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { busy }]
set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { state_out[0] }]
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { state_out[1] }]

# RGB LED 4 (accent LED)
# set_property -dict { PACKAGE_PIN L15   IOSTANDARD LVCMOS33 } [get_ports { led4_b }]
# set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { led4_g }]
# set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { led4_r }]

# RGB LED 5
# set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led5_b }]
# set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { led5_g }]
# set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led5_r }]

# =============================================================================
# PMOD CONNECTORS - For Debug/External Interface
# =============================================================================
# PMOD A (directly from PL, directly usable)
# set_property -dict { PACKAGE_PIN Y18  IOSTANDARD LVCMOS33 } [get_ports { pmoda[0] }]
# set_property -dict { PACKAGE_PIN Y19  IOSTANDARD LVCMOS33 } [get_ports { pmoda[1] }]
# set_property -dict { PACKAGE_PIN Y16  IOSTANDARD LVCMOS33 } [get_ports { pmoda[2] }]
# set_property -dict { PACKAGE_PIN Y17  IOSTANDARD LVCMOS33 } [get_ports { pmoda[3] }]
# set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports { pmoda[4] }]
# set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports { pmoda[5] }]
# set_property -dict { PACKAGE_PIN W18  IOSTANDARD LVCMOS33 } [get_ports { pmoda[6] }]
# set_property -dict { PACKAGE_PIN W19  IOSTANDARD LVCMOS33 } [get_ports { pmoda[7] }]

# PMOD B (directly from PL)
# set_property -dict { PACKAGE_PIN W14  IOSTANDARD LVCMOS33 } [get_ports { pmodb[0] }]
# set_property -dict { PACKAGE_PIN Y14  IOSTANDARD LVCMOS33 } [get_ports { pmodb[1] }]
# set_property -dict { PACKAGE_PIN T11  IOSTANDARD LVCMOS33 } [get_ports { pmodb[2] }]
# set_property -dict { PACKAGE_PIN T10  IOSTANDARD LVCMOS33 } [get_ports { pmodb[3] }]
# set_property -dict { PACKAGE_PIN V16  IOSTANDARD LVCMOS33 } [get_ports { pmodb[4] }]
# set_property -dict { PACKAGE_PIN W16  IOSTANDARD LVCMOS33 } [get_ports { pmodb[5] }]
# set_property -dict { PACKAGE_PIN V12  IOSTANDARD LVCMOS33 } [get_ports { pmodb[6] }]
# set_property -dict { PACKAGE_PIN W13  IOSTANDARD LVCMOS33 } [get_ports { pmodb[7] }]

# =============================================================================
# TIMING CONSTRAINTS
# =============================================================================

# Input delay (from PS AXI or external buttons)
set_input_delay -clock sys_clk_pin -max 2.0 [get_ports { start reset vpu_enable vpu_op_sel }]
set_input_delay -clock sys_clk_pin -min 0.5 [get_ports { start reset vpu_enable vpu_op_sel }]

# Output delay (to LEDs - relaxed)
set_output_delay -clock sys_clk_pin -max 5.0 [get_ports { done busy state_out* }]

# Asynchronous reset
set_false_path -from [get_ports { reset }]

# =============================================================================
# CONFIGURATION
# =============================================================================
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# =============================================================================
# BITSTREAM OPTIONS
# =============================================================================
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
