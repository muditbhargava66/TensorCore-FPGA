# Architecture Overview

This document describes the TensorCore-FPGA hardware architecture.

## System Block Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                        TensorCore                            │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────┐    ┌─────────────────┐    ┌────────────┐     │
│  │  Control   │───▶│   Systolic      │───▶│    VPU     │     │
│  │  (Tiling)  │    │   Array (MxN)   │    │ (Softmax)  │     │
│  └────────────┘    └─────────────────┘    └────────────┘     │
│        │                   │                    │            │
│        ▼                   ▼                    ▼            │
│  ┌──────────────────────────────────────────────────────┐    │
│  │                    Memory Subsystem                  │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│  ┌─────────────┐                      ┌──────────────────┐   │
│  │ PerfMonitor │                      │  AXI4-Lite (PS)  │   │
│  └─────────────┘                      └──────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

---

## Component Details

### 1. Control Unit (`Control.v`)

The control unit manages tile-based matrix multiplication:

- **Tile Loading**: Reads tiles from memory
- **Dataflow Control**: Weight Stationary (WS) or Output Stationary (OS)
- **Synchronization**: Coordinates SA and VPU operations

### 2. Systolic Array (`SA_MxN.v`)

Configurable MxN grid of Processing Elements:

```
         Weight W[0]    W[1]    W[2]    W[3]
              ↓         ↓       ↓       ↓
Data A[0] → [PE] ──→ [PE] ──→ [PE] ──→ [PE] → Partial
     A[1] → [PE] ──→ [PE] ──→ [PE] ──→ [PE] → Sums
     A[2] → [PE] ──→ [PE] ──→ [PE] ──→ [PE] →
     A[3] → [PE] ──→ [PE] ──→ [PE] ──→ [PE] →
              ↓         ↓       ↓       ↓
           Result    Result  Result  Result
```

### 3. Processing Element (`PE.v`)

Each PE performs:

```verilog
accumulator += activation × weight
```

Features:
- **Q16.16 Fixed-Point**: 32-bit arithmetic
- **Saturation**: Prevents overflow
- **Pipelining**: 1-cycle MAC operation

### 4. Vector Processing Unit (`VPU.v`)

Handles non-linear operations:

| Operation | Description |
|-----------|-------------|
| L2 Norm | Layer normalization |
| Softmax | FlashAttention-style online computation |

### 5. Performance Monitor (`PerfMonitor.v`)

Tracks execution metrics:

- Cycle count
- Memory read/write operations
- Compute utilization
- Stall cycles

---

## Memory Interface

### AXI4-Lite Register Map

| Offset | Name | Access | Description |
|--------|------|--------|-------------|
| 0x00 | CTRL | R/W | Control (start/reset/mode) |
| 0x04 | STATUS | R | Status (done/busy/state) |
| 0x08-0x10 | DIMS | R/W | Matrix dimensions (K1/K2/K3) |
| 0x14-0x1C | ADDR | R/W | Base addresses |
| 0x20-0x28 | PERF | R | Performance counters |

---

## Dataflow Modes

### Weight Stationary (WS)

- Weights preloaded into PE registers
- Activations stream through array
- Best for large weight matrices

### Output Stationary (OS)

- Partial sums accumulate in PEs
- Results drain at end
- Best for small tile sizes

---

## Target Platforms

| Platform | Clock | Resources |
|----------|-------|-----------|
| PYNQ-Z1 | 125 MHz | Zynq-7020 |
| TinyTapeout | 50 MHz | 2,872 cells |
| SKY130 ASIC | Variable | OpenROAD flow |
