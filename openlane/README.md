# OpenLANE Flow for TensorCore

This directory contains configuration for running TensorCore through the OpenLANE RTL-to-GDSII flow.

## Prerequisites

Install OpenLANE and SKY130 PDK:

```bash
# Clone OpenLANE
git clone https://github.com/The-OpenROAD-Project/OpenLane.git
cd OpenLane

# Install dependencies
make
make pdk

# Or use Docker
make mount
```

## Running the Flow

### Quick Start

```bash
# From OpenLane directory
./flow.tcl -design /path/to/TensorCore-FPGA/openlane -run_path ./runs/tensorcore_run
```

### Interactive Mode

```bash
./flow.tcl -interactive
% package require openlane 0.9
% prep -design /path/to/TensorCore-FPGA/openlane
% run_synthesis
% run_floorplan
% run_placement
% run_cts
% run_routing
% run_magic
% run_klayout
```

## Configuration

| Parameter | Value | Description |
|-----------|-------|-------------|
| DESIGN_NAME | TensorCore | Top module name |
| CLOCK_PORT | clk | Clock signal |
| CLOCK_PERIOD | 10.0 ns | Target: 100 MHz |
| FP_CORE_UTIL | 40% | Core utilization |
| DIE_AREA | 2mm × 2mm | Die dimensions |

## Output Files

After successful run, outputs are in `runs/<run_name>/results/`:

- `synthesis/` - Gate-level netlist
- `floorplan/` - DEF with die area
- `placement/` - Placed cells
- `cts/` - Clock tree
- `routing/` - Routed design
- `signoff/` - Final GDS, timing reports

## Troubleshooting

**High congestion**: Reduce `FP_CORE_UTIL` to 30-35%

**Timing violations**: Increase `CLOCK_PERIOD` or use `SYNTH_STRATEGY "DELAY 0"`

**DRC errors**: Check `logs/signoff/drc.log`
