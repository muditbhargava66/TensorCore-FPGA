#!/bin/bash
# =============================================================================
# Magic DRC Script for TinyTapeout GDS
# Runs Design Rule Check using sky130 PDK
# =============================================================================

set -e

# Configuration
PDK_ROOT="${PDK_ROOT:-$HOME/.volare}"
PDK="${PDK:-sky130A}"
MAGIC_RC="$PDK_ROOT/$PDK/libs.tech/magic/${PDK}.magicrc"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GDS_FILE="$PROJECT_ROOT/runs/wokwi/final/gds/tt_um_tensorcore_pe.gds"
REPORT_DIR="$PROJECT_ROOT/scripts/reports"

mkdir -p "$REPORT_DIR"

echo "========================================"
echo "  Magic DRC - TensorCore TinyTapeout"
echo "========================================"
echo "PDK_ROOT: $PDK_ROOT"
echo "PDK: $PDK"
echo ""

# Check Magic RC file
if [ ! -f "$MAGIC_RC" ]; then
    echo "ERROR: Magic RC file not found at $MAGIC_RC"
    echo "Set PDK_ROOT environment variable to your PDK location"
    echo "Example: export PDK_ROOT=$HOME/.volare"
    exit 1
fi

# Check GDS file
if [ ! -f "$GDS_FILE" ]; then
    echo "ERROR: GDS file not found at $GDS_FILE"
    echo "Run 'python3 tt/tt_tool.py --harden' first"
    exit 1
fi

echo "GDS File: $GDS_FILE"
echo "Magic RC: $MAGIC_RC"
echo ""
echo "Running Magic DRC..."

# Create Magic script
cat > "$REPORT_DIR/drc_script.tcl" << EOF
# Load sky130 tech
source $MAGIC_RC

# Read GDS
gds read $GDS_FILE

# Select top cell
load tt_um_tensorcore_pe

# Run DRC
select top cell
drc check
drc catchup

# Count errors
set drc_count [drc count]
puts "DRC Error Count: \$drc_count"

# Generate report
drc why > $REPORT_DIR/drc_report.txt

puts ""
puts "DRC Complete. Report: $REPORT_DIR/drc_report.txt"
quit
EOF

# Run Magic
magic -dnull -noconsole -rcfile "$MAGIC_RC" "$REPORT_DIR/drc_script.tcl" 2>&1 | tee "$REPORT_DIR/magic_output.log"

echo ""
echo "========================================"
if [ -f "$REPORT_DIR/drc_report.txt" ]; then
    echo "DRC Report Preview:"
    head -20 "$REPORT_DIR/drc_report.txt"
fi
echo "========================================"
echo "  DRC Complete"
echo "========================================"
