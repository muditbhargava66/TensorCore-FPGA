# TinyTapeout ASIC Design Guide

This document describes how to build and verify the TinyTapeout-compatible TensorCore design.

## Overview

The TinyTapeout design is a **2x2 Systolic Array** implementing 4 MAC (Multiply-Accumulate) units for neural network acceleration.

### Specifications

| Specification | Value |
|---------------|-------|
| **Design Name** | `tt_um_tensorcore` |
| **Clock Frequency** | 50 MHz |
| **Data Width** | 8-bit signed |
| **MAC Units** | 4 (2x2 array) |
| **Cell Count** | 2,872 |
| **Area** | 42,826 μm² |
| **Utilization** | 49.4% |

---

## Architecture

```
        Weight     Weight
         Col0       Col1
           │          │
           ▼          ▼
Data ─▶ [PE(0,0)] ─▶ [PE(0,1)] ─▶
Row0       │          │
           ▼          ▼
Data ─▶ [PE(1,0)] ─▶ [PE(1,1)] ─▶
Row1       │          │
           ▼          ▼
        Result     Result
```

### Processing Element (PE)

Each PE performs:
- **MAC**: `accumulator += activation × weight`
- **Saturation**: 8-bit output with overflow detection
- **Systolic flow**: Data passes to neighbors

---

## Pin Mapping

### Input Pins (`ui_in`)

| Pin | Function |
|-----|----------|
| `ui_in[5:0]` | Data (6-bit, sign-extended) |
| `ui_in[6]` | Row select |
| `ui_in[7]` | Mode[1] |

### Output Pins (`uo_out`)

| Pin | Function |
|-----|----------|
| `uo_out[7:0]` | Selected PE result |

### Bidirectional Pins (`uio`)

| Pin | Input | Output |
|-----|-------|--------|
| `uio[5:0]` | Weight data | - |
| `uio[6]` | Column select | - |
| `uio[7]` | - | State[1] |
| `uio[3:0]` | - | Overflow flags |

---

## Control Modes

| Mode | `ui_in[7:6]` | Function |
|------|--------------|----------|
| NOP | `00` | Idle |
| CLEAR | `01` | Clear accumulators |
| LOAD | `10` | Load weights |
| COMPUTE | `11` | MAC operation |

---

## Quick Start

### Prerequisites

```bash
pip install librelane volare cocotb
volare enable sky130 --pdk-root ~/.volare
```

### Run Tests

```bash
cd test
make clean && make
```

### Harden Design

```bash
python3 tt/tt_tool.py --create-user-config
python3 tt/tt_tool.py --harden
python3 tt/tt_tool.py --create-png
```

---

## Verification Results

| Check | Status |
|-------|--------|
| DRC | ✅ Passed |
| LVS | ✅ Passed |
| Antenna | ✅ Passed |
| Setup Timing | ✅ 2.34ns slack |
| Hold Timing | ✅ 0.108ns slack |

---

## Files

| File | Description |
|------|-------------|
| [`src/tt/tt_um_tensorcore.v`](../src/tt/tt_um_tensorcore.v) | Top module |
| [`src/tt/ProcessingElement.v`](../src/tt/ProcessingElement.v) | PE with MAC |
| [`src/tt/SystolicArray2x2.v`](../src/tt/SystolicArray2x2.v) | 2x2 array |
| [`src/tt/config.json`](../src/tt/config.json) | OpenLane config |

---

## References

- [TinyTapeout Documentation](https://tinytapeout.com/specs/)
- [Skywater PDK](https://skywater-pdk.readthedocs.io/)
- [OpenLane2 Documentation](https://openlane2.readthedocs.io/)