# =============================================================================
# OpenROAD Placement Script
# TensorCore-FPGA - SKY130 PDK
# =============================================================================

# Read database from floorplan
read_db $::env(RESULTS_DIR)/floorplan.odb

# Read timing constraints
read_sdc ../constraint.sdc

# =============================================================================
# Global Placement
# =============================================================================

puts "=== Running Global Placement ==="

global_placement \
    -density 0.6 \
    -pad_left 2 \
    -pad_right 2

# =============================================================================
# IO Placer Refinement
# =============================================================================

# Refine IO placement after global placement
# place_pins -hor_layers met3 -ver_layers met2

# =============================================================================
# Repair Design
# =============================================================================

puts "=== Repairing Design ==="

# Estimate parasitics
estimate_parasitics -placement

# Repair timing
repair_design

# Repair tie fanout
repair_tie_fanout -separation 0

# =============================================================================
# Detailed Placement
# =============================================================================

puts "=== Running Detailed Placement ==="

detailed_placement

# Optimize placement
optimize_mirroring

# =============================================================================
# Legalization Check
# =============================================================================

check_placement -verbose

# =============================================================================
# Write Output
# =============================================================================

write_def $::env(RESULTS_DIR)/place.def
write_db $::env(RESULTS_DIR)/place.odb

puts "=== Placement Complete ==="
report_design_area
