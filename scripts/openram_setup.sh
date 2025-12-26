#!/bin/bash
# =============================================================================
# OpenRAM SRAM Generator Configuration
# Creates SRAM macros for TensorCore memory blocks
# =============================================================================

set -e

echo "========================================"
echo "  OpenRAM SRAM Generator"
echo "========================================"

# Check OpenRAM installation
OPENRAM_HOME="${OPENRAM_HOME:-}"

if [ -z "$OPENRAM_HOME" ] || [ ! -d "$OPENRAM_HOME" ]; then
    echo ""
    echo "OpenRAM is not installed or OPENRAM_HOME is not set."
    echo ""
    echo "To install OpenRAM:"
    echo "  1. git clone https://github.com/VLSIDA/OpenRAM.git"
    echo "  2. export OPENRAM_HOME=/path/to/OpenRAM"
    echo "  3. export PYTHONPATH=\$OPENRAM_HOME"
    echo "  4. pip install -r \$OPENRAM_HOME/requirements.txt"
    echo ""
    echo "For sky130 PDK support:"
    echo "  export OPENRAM_TECH=\$OPENRAM_HOME/technology/sky130"
    echo ""
    echo "========================================"
    echo "OpenRAM Configuration (for when installed)"
    echo "========================================"
    
    # Create sample configuration file
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    CONFIG_FILE="$PROJECT_ROOT/scripts/openram_config.py"
    
    cat > "$CONFIG_FILE" << 'EOF'
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
EOF

    echo "Sample config created: $CONFIG_FILE"
    echo ""
    echo "When OpenRAM is installed, run:"
    echo "  python3 \$OPENRAM_HOME/openram.py scripts/openram_config.py"
    exit 0
fi

# If OpenRAM is installed, show usage
echo "OpenRAM found at: $OPENRAM_HOME"
echo ""
echo "To generate SRAM:"
echo "  python3 \$OPENRAM_HOME/openram.py scripts/openram_config.py"
