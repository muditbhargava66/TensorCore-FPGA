# =============================================================================
# TensorCore-FPGA - Vivado Bitstream Generation Script
# =============================================================================

# Open project
set project_dir "../build"
set project_name "tensorcore"
open_project $project_dir/$project_name.xpr

# =============================================================================
# Generate Bitstream
# =============================================================================

puts ""
puts "=============================================="
puts "  Generating Bitstream..."
puts "=============================================="
puts ""

# Ensure implementation is complete
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "Implementation not complete. Running implementation first..."
    launch_runs impl_1 -jobs 4
    wait_on_run impl_1
}

# Open implementation
open_run impl_1

# Generate bitstream
write_bitstream -force $project_dir/tensorcore.bit
puts "Generated: tensorcore.bit"

# =============================================================================
# Export Hardware for SDK/Vitis
# =============================================================================

puts ""
puts "=============================================="
puts "  Exporting Hardware..."
puts "=============================================="
puts ""

# Export hardware definition (includes bitstream)
write_hw_platform -fixed -include_bit -force $project_dir/tensorcore.xsa
puts "Generated: tensorcore.xsa"

# Also export hwdef for older tools
write_hwdef -force $project_dir/tensorcore.hwdef
puts "Generated: tensorcore.hwdef"

# =============================================================================
# Generate .bin for PYNQ
# =============================================================================

puts ""
puts "=============================================="
puts "  Generating PYNQ Files..."
puts "=============================================="
puts ""

# Generate .bin file (for PYNQ/bootgen)
write_cfgmem -format BIN -interface SMAPx32 -disablebitswap \
    -loadbit "up 0 $project_dir/tensorcore.bit" \
    -force $project_dir/tensorcore.bin
puts "Generated: tensorcore.bin"

# Copy hardware handoff file
file copy -force $project_dir/tensorcore.xsa $project_dir/tensorcore.hwh
puts "Generated: tensorcore.hwh (copy of xsa)"

# =============================================================================
# Print Summary
# =============================================================================

puts ""
puts "=============================================="
puts "  Bitstream Generation Complete!"
puts "=============================================="
puts ""
puts "  Output files:"
puts "    - tensorcore.bit   (Bitstream for Vivado)"
puts "    - tensorcore.bin   (Binary for PYNQ/Bootgen)"
puts "    - tensorcore.xsa   (Hardware platform for Vitis)"
puts "    - tensorcore.hwh   (Hardware handoff for PYNQ)"
puts ""
puts "  For PYNQ:"
puts "    Copy .bit and .hwh to Jupyter notebook directory"
puts "    Rename both to same base name (e.g., overlay.bit, overlay.hwh)"
puts ""
puts "=============================================="

close_project
