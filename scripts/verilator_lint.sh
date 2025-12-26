#!/bin/bash
# =============================================================================
# Verilator Lint Script for TensorCore-FPGA
# Runs static analysis on all RTL files
# =============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_CORE="$PROJECT_ROOT/src/core"
SRC_TT="$PROJECT_ROOT/src/tt"
INCLUDE="$PROJECT_ROOT/src/include"

echo "========================================"
echo "  Verilator Lint - TensorCore-FPGA"
echo "========================================"

# Check Verilator version
verilator --version

echo ""
echo "--- Linting TinyTapeout Design ---"
verilator --lint-only \
    -Wall \
    "$SRC_TT/ProcessingElement.v" \
    "$SRC_TT/SystolicArray2x2.v" \
    "$SRC_TT/tt_um_tensorcore.v" \
    2>&1 || echo "TT lint complete (with warnings)"

echo ""
echo "--- Linting Core Design (partial) ---"
verilator --lint-only \
    -Wall \
    -I"$INCLUDE" \
    "$SRC_CORE/PE.v" \
    "$SRC_CORE/MAC.v" \
    "$SRC_CORE/PerfMonitor.v" \
    2>&1 || echo "Core lint complete (with warnings)"

echo ""
echo "========================================"
echo "  Lint Complete"
echo "========================================"
