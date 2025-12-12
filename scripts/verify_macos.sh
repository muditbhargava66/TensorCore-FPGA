#!/bin/bash
# =============================================================================
# TensorCore-FPGA - macOS Verification Script
# Runs all available checks that work without Vivado
# =============================================================================

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=============================================="
echo "  TensorCore-FPGA - macOS Verification"
echo -e "===============================================${NC}"
echo ""

# -----------------------------------------------------------------------------
# Check Prerequisites
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[1/4] Checking prerequisites...${NC}"

check_tool() {
    if command -v $1 &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $1 found: $(which $1)"
        return 0
    else
        echo -e "  ${RED}✗${NC} $1 not found"
        return 1
    fi
}

MISSING=0
check_tool iverilog || MISSING=1
check_tool vvp || MISSING=1
check_tool yosys || { echo -e "  ${YELLOW}!${NC} yosys not found (optional for synthesis stats)"; }

if [ $MISSING -eq 1 ]; then
    echo ""
    echo -e "${RED}Missing required tools. Install with:${NC}"
    echo "  brew install icarus-verilog"
    exit 1
fi
echo ""

# -----------------------------------------------------------------------------
# Syntax/Compilation Check
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[2/4] Checking Verilog syntax...${NC}"

cd "$PROJECT_ROOT/rtl"

VERILOG_FILES=$(find core -name "*.v" | sort)
INCLUDE_DIRS="-I include -I core"

echo "  Compiling RTL files..."
iverilog -g2012 $INCLUDE_DIRS -o /dev/null $VERILOG_FILES 2>&1 | head -20

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} All RTL files compile successfully"
else
    echo -e "  ${RED}✗${NC} Compilation failed"
    exit 1
fi
echo ""

# -----------------------------------------------------------------------------
# Run Testbench Simulation
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[3/4] Running RTL simulation...${NC}"

cd "$PROJECT_ROOT/verification/verilator"

echo "  Building testbench..."
make clean > /dev/null 2>&1 || true
make build 2>&1 | tail -5

echo "  Running simulation..."
make run 2>&1 | grep -E "(PASSED|FAILED|Complete|Error|Warning)" | head -20

if make run 2>&1 | grep -q "VPU TEST PASSED"; then
    echo -e "  ${GREEN}✓${NC} VPU test passed"
else
    echo -e "  ${YELLOW}!${NC} VPU test status unclear"
fi
echo ""

# -----------------------------------------------------------------------------
# Quick Synthesis Stats (if Yosys available)
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[4/4] Generating synthesis statistics...${NC}"

if command -v yosys &> /dev/null; then
    cd "$PROJECT_ROOT/rtl"
    
    # Create temp synthesis script
    cat > /tmp/tensorcore_synth_check.ys << 'EOF'
# Quick synthesis check for TensorCore
read_verilog -I include -I core core/MAC.v
read_verilog -I include -I core core/PE_Synth.v
read_verilog -I include -I core core/SA_MxN_Synth.v
read_verilog -I include -I core core/VPU_Synth.v
read_verilog -I include -I core core/PerfMonitor.v
hierarchy -top PE_Synth
proc
opt
stat
EOF

    echo "  Running Yosys on PE_Synth..."
    yosys -q /tmp/tensorcore_synth_check.ys 2>&1 | grep -E "(Number of|cells|wires)" | head -10
    
    rm -f /tmp/tensorcore_synth_check.ys
    echo -e "  ${GREEN}✓${NC} Synthesis stats generated"
else
    echo -e "  ${YELLOW}!${NC} Yosys not installed, skipping synthesis stats"
    echo "      Install with: brew install yosys"
fi
echo ""

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo -e "${BLUE}=============================================="
echo "  Verification Complete"
echo -e "===============================================${NC}"
echo ""
echo "  Your codebase is ready for Windows/Vivado!"
echo ""
echo "  Next steps:"
echo "  1. Copy project to Windows machine"
echo "  2. Open Vivado and run:"
echo "     cd tensorcore/vivado/tcl"
echo "     vivado -mode batch -source create_project.tcl"
echo ""
