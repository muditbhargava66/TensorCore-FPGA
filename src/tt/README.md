# TinyTapeout RTL Sources

This directory contains RTL designs for TinyTapeout ASIC submission.

## Available Designs

### 1. SystolicArray2x2 (Default - TinyTapeout)
- **4 MAC units** (2x2 grid)
- **~2,900 cells**, 49% utilization
- **Fits TinyTapeout** ✅

### 2. SystolicArray4x4 (Optional - FPGA)
- **16 MAC units** (4x4 grid)
- **~10,000+ cells** (estimated)
- **For FPGA only** - may not fit TinyTapeout

## Files

| File | Description |
|------|-------------|
| `tt_um_tensorcore.v` | Top module (uses 2x2) |
| `ProcessingElement.v` | Single PE with MAC |
| `SystolicArray2x2.v` | 2x2 array (4 MACs) |
| `SystolicArray4x4.v` | 4x4 array (16 MACs) |
| `config.json` | OpenLane configuration |

## Switching to 4x4

For FPGA use, modify `tt_um_tensorcore.v` to instantiate `systolic_4x4` instead of `systolic_2x2`.

**Note**: 4x4 will likely NOT fit in TinyTapeout tile.
