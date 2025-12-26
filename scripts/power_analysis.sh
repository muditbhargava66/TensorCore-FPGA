#!/bin/bash
# Power Analysis Script using OpenSTA
# Estimates power consumption from synthesis results

set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PDK_ROOT="${PDK_ROOT:-$HOME/.volare}"

echo "========================================"
echo "  Power Analysis - TensorCore TT"
echo "========================================"

# Check for OpenSTA
if ! command -v sta &> /dev/null; then
    echo "OpenSTA not found. Install with: pip install opensta"
    echo ""
    echo "Alternative: Use Yosys for rough estimate"
    echo ""
    
    cd "$PROJECT_ROOT"
    yosys -p "
        read_verilog -sv src/tt/*.v
        hierarchy -top tt_um_tensorcore
        proc; opt; techmap
        stat
    " 2>&1 | grep -E "(cells|wires|Area|Number)"
    
    echo ""
    echo "Power estimation (rough):"
    echo "  - Dynamic: ~50-80 uW @ 50MHz (typical digital)"
    echo "  - Leakage: ~5-10 uW (sky130)"
    echo "  - Total:   ~60-90 uW"
    exit 0
fi

# Create STA script
cat > /tmp/power_sta.tcl << 'STA_EOF'
# OpenSTA Power Analysis
read_liberty $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog runs/wokwi/final/nl/tt_um_tensorcore_pe.nl.v
link_design tt_um_tensorcore_pe
read_sdc scripts/timing_constraints.sdc
report_power
exit
STA_EOF

sta -f /tmp/power_sta.tcl

echo "========================================"
echo "  Power Analysis Complete"
echo "========================================"
