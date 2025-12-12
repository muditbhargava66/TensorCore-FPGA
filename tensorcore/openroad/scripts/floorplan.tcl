# =============================================================================
# OpenROAD Floorplan Script
# TensorCore-FPGA - SKY130 PDK
# =============================================================================

# Read synthesized netlist
read_verilog $::env(RESULTS_DIR)/synth.v
link_design $::env(DESIGN_TOP)

# Read timing constraints
read_sdc ../constraint.sdc

# Read technology files
read_lef $::env(TECH_LEF)
read_lef $::env(SC_LEF)

# =============================================================================
# Floorplan Configuration
# =============================================================================

# Die area: 2mm x 2mm for small design
# Core utilization: 50%
set die_area  {0 0 2000 2000}
set core_area {100 100 1900 1900}

initialize_floorplan \
    -die_area $die_area \
    -core_area $core_area \
    -site unithd

# =============================================================================
# Power Distribution Network (PDN)
# =============================================================================

# Add power rails
source $::env(PDK_ROOT)/sky130A/libs.tech/openlane/sky130_fd_sc_hd/tracks.tcl

# Create power grid (simplified for initial testing)
# Full PDN would use pdngen

add_global_connection -net VDD -pin_pattern VPWR -power
add_global_connection -net VSS -pin_pattern VGND -ground
add_global_connection -net VDD -pin_pattern VPB -power
add_global_connection -net VSS -pin_pattern VNB -ground

# =============================================================================
# IO Pin Placement
# =============================================================================

# Place pins on edges
place_pins -hor_layers met3 -ver_layers met2 -random

# =============================================================================
# Macro Placement (if any)
# =============================================================================

# No hard macros in this design currently
# If SRAM macros added later:
# place_macro -name sram_inst -x 500 -y 500

# =============================================================================
# Tap Cells
# =============================================================================

tapcell \
    -distance 14 \
    -tapcell_master sky130_fd_sc_hd__tapvpwrvgnd_1 \
    -endcap_master sky130_fd_sc_hd__decap_4

# =============================================================================
# Write Output
# =============================================================================

write_def $::env(RESULTS_DIR)/floorplan.def
write_db $::env(RESULTS_DIR)/floorplan.odb

puts "=== Floorplan Complete ==="
report_design_area
