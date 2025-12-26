# TinyTapeout ASIC Design Guide

This document describes the TinyTapeout-compatible TensorCore design.

## Overview

The TinyTapeout design is a **2x2 Systolic Array** implementing 4 MAC units for neural network acceleration.

### Specifications

| Specification | Value |
|---------------|-------|
| **Design Name** | `tt_um_tensorcore` |
| **Clock Frequency** | 50 MHz |
| **Data Width** | 8-bit signed (INT8) |
| **MAC Units** | 4 (2x2 array) |
| **Accumulator** | 24-bit internal |
| **Cell Count** | 199 (pre-mapping) |

---

## Key Features

### 1. 24-bit Accumulator
Extended precision prevents overflow during deep network inference:
```verilog
reg signed [23:0] accumulator;  // 24-bit for many accumulations
```

### 2. Weight Double-Buffering
Overlap weight loading with computation:
```verilog
reg signed [7:0] weight_active;  // In use
reg signed [7:0] weight_shadow;  // Preloading next tile
```

### 3. INT8 Saturation
Output clamped to valid INT8 range:
```verilog
assign saturated = (accumulator > 127) ? 127 :
                   (accumulator < -128) ? -128 : accumulator[7:0];
```

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

---

## Pin Mapping

### Input Pins (`ui_in`)

| Pin | Function |
|-----|----------|
| `ui_in[5:0]` | Data (6-bit, sign-extended) |
| `ui_in[6]` | Row select |
| `ui_in[7]` | Mode[1] |

### Control Modes

| Mode | `ui_in[7:6]` | Function |
|------|--------------|----------|
| NOP | `00` | Idle |
| CLEAR | `01` | Clear accumulators |
| LOAD | `10` | Load weights |
| COMPUTE | `11` | MAC operation |

---

## Quick Start

```bash
# Run tests
cd test && make

# Synthesize
yosys scripts/synth_check.ys
```

---

## Files

| File | Description |
|------|-------------|
| `ProcessingElement.v` | Enhanced PE (24-bit acc) |
| `SystolicArray2x2.v` | 2x2 array (4 MACs) |
| `SystolicArray4x4.v` | 4x4 array (16 MACs) |
| `tt_um_tensorcore.v` | Top module |