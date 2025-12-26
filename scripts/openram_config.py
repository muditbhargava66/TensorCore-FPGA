# OpenRAM Configuration for TensorCore Memory
# Generates small SRAM for weight/activation storage

# Technology
tech_name = "sky130"

# Word size (8-bit for TinyTapeout compatibility)
word_size = 8

# Number of words (32 words = small buffer)
num_words = 32

# Number of banks
num_banks = 1

# Number of read/write ports
num_rw_ports = 1
num_r_ports = 0
num_w_ports = 0

# Output directory
output_path = "openram_output"
output_name = "tensorcore_sram_32x8"

# Timing (in ns)
# nominal_corner_only = True

# Area optimization
# check_lvsdrc = True
