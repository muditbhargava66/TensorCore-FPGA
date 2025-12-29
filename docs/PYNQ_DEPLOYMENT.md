# PYNQ-Z1 Deployment Guide

This document provides instructions for deploying TensorCore-FPGA to the PYNQ-Z1 board.

## Requirements

- **Hardware**: PYNQ-Z1 board (Xilinx Zynq-7020)
- **Software**: Vivado 2022.2, PYNQ 3.0+
- **Network**: PYNQ accessible at `http://<PYNQ_IP>:9090`

## Zynq Architecture Overview

The PYNQ-Z1 uses a Xilinx Zynq-7020 SoC which contains two parts:

```
┌─────────────────────────────────────────────────────────────┐
│                      PYNQ-Z1 Board                          │
├─────────────────────────────────────────────────────────────┤
│  ┌────────────────────┐      ┌────────────────────────────┐ │
│  │         PS         │      │            PL              │ │
│  │    (ARM Cortex-A9) │◄────►│      (TensorCore)          │ │
│  │                    │ AXI  │                            │ │
│  │  processing_       │      │  tensorcore_0              │ │
│  │  system7_0         │      │  @ 0x43C00000              │ │
│  │                    │      │                            │ │
│  │  Runs Linux/Python │      │  Your accelerator logic    │ │
│  └────────────────────┘      └────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### IP Address Mapping

| IP Name | What it is | AXI Address |
|---------|------------|-------------|
| `tensorcore_0` | Your accelerator (PL) | `0x43C00000` |
| `processing_system7_0` | ARM CPU (PS) | None - it's the processor |

> **Note**: When loading the overlay, `processing_system7_0: @ Unknown` is **expected**. 
> The PS is the CPU running your Python code - it doesn't have a memory address because 
> it IS the thing doing the addressing!

## Build Bitstream

### One-Click Build (Windows)

```batch
cd vivado
build_pynq.bat
```

### Manual Build

```tcl
cd vivado
vivado -mode batch -source tcl/build_all.tcl
```

### Build Outputs

| File | Location | Description |
|------|----------|-------------|
| `tensorcore.bit` | `vivado/build/output/` | FPGA bitstream |
| `tensorcore.hwh` | `vivado/build/output/` | Hardware handoff |
| `tensorcore.xsa` | `vivado/build/output/` | Vitis platform |

## Deployment

### 1. Copy Files to PYNQ

```bash
scp vivado/build/output/tensorcore.bit xilinx@<PYNQ_IP>:/home/xilinx/jupyter_notebooks/
scp vivado/build/output/tensorcore.hwh xilinx@<PYNQ_IP>:/home/xilinx/jupyter_notebooks/
scp -r pynq/tensorcore xilinx@<PYNQ_IP>:/home/xilinx/jupyter_notebooks/
```

Default password: `xilinx`

### 2. Access Jupyter

Open browser: `http://<PYNQ_IP>:9090`

### 3. Run Demo Notebook

Open `01_tensorcore_demo.ipynb` and run all cells.

## Hardware Verification Results

**Tested on**: PYNQ-Z1, December 29, 2025

### Benchmark Results

| Matrix Size | Cycles | Time @ 70MHz |
|-------------|--------|--------------|
| 2×2 | 72 | 1.03 µs |
| 4×4 | 488 | 6.97 µs |
| 8×8 | 1,684 | 24.06 µs |
| 16×16 | 12,520 | 178.86 µs |

### Performance Counters (4×4 MatMul)

| Metric | Value |
|--------|-------|
| Cycles | 488 |
| Memory Reads | 96 |
| Memory Writes | 16 |

### VPU Operations

| Operation | Status | Cycles |
|-----------|--------|--------|
| L2 Normalization | `PASS` | 556 |
| Softmax | `PASS` | 523 |

## Resource Utilization

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| Slice LUTs | 1,104 | 53,200 | 2.08% |
| Slice Registers | 879 | 106,400 | 0.83% |
| Block RAM | 1 | 140 | 0.71% |
| DSP48E1 | 0 | 220 | 0.00% |

## Timing

- **Target Clock**: 70 MHz (14.286 ns period)
- **WNS**: +0.284 ns
- **All timing constraints met**

## Register Map

| Offset | Name | Description |
|--------|------|-------------|
| 0x00 | CTRL | Control: [0]=start, [1]=reset, [2]=vpu_en, [3]=mode |
| 0x04 | STATUS | Status: [0]=done, [1]=busy, [7:4]=state |
| 0x08 | K1 | Matrix rows of A |
| 0x0C | K2 | Matrix cols of A / rows of W |
| 0x10 | K3 | Matrix cols of W |
| 0x14 | A_BASE | Matrix A base address |
| 0x18 | W_BASE | Matrix W base address |
| 0x1C | C_BASE | Matrix C base address |
| 0x20 | PERF_CYC | Performance: cycle count |
| 0x24 | PERF_RD | Performance: memory reads |
| 0x28 | PERF_WR | Performance: memory writes |
| 0x2C | VPU_OP | VPU operation select |

## LED Indicators

| LED | Signal | Description |
|-----|--------|-------------|
| LD0 | done | Computation complete |
| LD1 | busy | Accelerator processing |
| LD2-3 | state | FSM state indicator |

## Python Driver Usage

```python
from pynq import Overlay
from tensorcore import TensorCoreDriver

# Load overlay
ol = Overlay("tensorcore.bit")
tc = TensorCoreDriver(ol)

# Run benchmark
results = tc.benchmark([2, 4, 8, 16])
for size, cycles in results.items():
    print(f"{size}x{size}: {cycles} cycles")

# Matrix multiplication
import numpy as np
A = np.random.randn(4, 4).astype(np.float32)
W = np.random.randn(4, 4).astype(np.float32)
C, perf = tc.matmul(A, W)
```

## Troubleshooting

### Overlay fails to load

1. Ensure `.bit` and `.hwh` have the same base name
2. Check that files are in the notebook directory
3. Restart the Jupyter kernel

### Done signal not detected

The done signal is latched in hardware (v1.5.0+). If using older bitstream, rebuild with:

```bash
cd vivado && vivado -mode batch -source tcl/build_all.tcl
```

### Timing violations

Clock is set to 70 MHz in v1.5.0. For 100 MHz operation, pipelining modifications are required.
