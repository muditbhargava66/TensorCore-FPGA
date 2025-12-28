#!/usr/bin/env python3
"""
OpenRAM Configuration for TinyTapeout SRAM
256x8 single-port SRAM for weight buffer
"""

word_size = 8        # 8-bit data width
num_words = 256      # 256 entries = 2KB
num_banks = 1
words_per_row = 1

# Technology
tech_name = "sky130"
process_corners = ["TT"]
supply_voltages = [1.8]
temperatures = [25]

# Output
output_name = "sram_256x8"
output_path = "runs/openram/"

# Timing
nominal_corner_only = True

# Ports
num_rw_ports = 1
num_r_ports = 0
num_w_ports = 0

print(f"""
OpenRAM TinyTapeout SRAM Configuration
======================================
Size: {num_words} x {word_size} bits = {num_words * word_size / 8} bytes
Technology: {tech_name}
Voltage: {supply_voltages[0]}V
Output: {output_name}

To generate:
  openram -c scripts/openram_tt.py

Note: Requires OpenRAM and SKY130 PDK installed.
""")
