<div align="center">

# TensorCore-FPGA

> A high-performance LLM accelerator featuring Systolic Arrays and Vector Processing Units, targeting Xilinx Zynq FPGAs.

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![FPGA: Zynq-7020](https://img.shields.io/badge/FPGA-Zynq--7020-blue.svg)](https://www.xilinx.com/products/silicon-devices/soc/zynq-7000.html)
[![Board: PYNQ-Z1](https://img.shields.io/badge/Board-PYNQ--Z1-green.svg)](https://www.tulembedded.com/FPGA/ProductsPYNQ-Z1.html)

</div>

## Overview

TensorCore-FPGA is a hardware accelerator architecture optimized for Large Language Model (LLM) inference. It implements the core computational kernels required for transformer models:

- **Matrix Multiplication**: Systolic Array with configurable tile sizes
- **Attention Processing**: FlashAttention-style Softmax with online normalization
- **Layer Normalization**: L2 normalization for transformer layers

## Features

| Feature | Description |
|---------|-------------|
| **Systolic Array** | Configurable MxN tile-based matrix multiplication |
| **Dual Dataflow** | Weight Stationary (WS) and Output Stationary (OS) modes |
| **Vector Processing Unit** | L2 Normalization + FlashAttention-style Softmax |
| **Performance Monitoring** | Cycle counters, memory bandwidth tracking |
| **Fixed-Point Arithmetic** | Q16.16 format for synthesizable implementation |
| **AXI4-Lite Interface** | PS-PL control for Zynq SoC integration |

## Target Platform

- **FPGA Board**: PYNQ-Z1 (Digilent/TUL)
- **SoC**: Xilinx Zynq-7020 (XC7Z020-1CLG400C)
- **Clock**: 125 MHz system clock
- **ASIC Target**: SKY130 PDK (via OpenROAD)

## Directory Structure

```
tensorcore/
├── rtl/
│   ├── core/                    # Synthesizable RTL
│   │   ├── TensorCore.v         # Top-level integrated processor
│   │   ├── Control.v            # Tiling state machine
│   │   ├── MatMul_Controller.v  # Systolic array scheduler
│   │   ├── SA_MxN.v             # Systolic array (behavioral)
│   │   ├── SA_MxN_Synth.v       # Systolic array (synthesizable)
│   │   ├── PE.v / PE_Synth.v    # Processing elements
│   │   ├── VPU.v / VPU_Synth.v  # Vector processing units
│   │   ├── MAC.v                # Synthesizable MAC IP
│   │   ├── PerfMonitor.v        # Performance counters
│   │   └── Memory.v             # Behavioral memory model
│   └── include/
│       ├── system_defs.vh       # System parameters
│       └── fixed_point_pkg.vh   # Q16.16 fixed-point definitions
├── vivado/                      # Xilinx FPGA targeting
│   ├── constraints/             # XDC pin/timing constraints
│   ├── src/                     # AXI wrapper for PS-PL
│   └── tcl/                     # Project creation scripts
├── openroad/                    # ASIC synthesis flow
│   ├── scripts/                 # Yosys/OpenROAD TCL
│   ├── constraint.sdc           # Timing constraints
│   └── Makefile                 # Synthesis automation
├── model/
│   ├── systemc/                 # Behavioral golden models
│   └── spice/                   # 6T/8T SRAM cells
├── verification/
│   ├── verilator/               # Verilog testbenches
│   └── systemc_tb/              # SystemC tests
└── scripts/                     # Build automation
    ├── verify_macos.sh          # macOS verification
    └── build_vivado.bat         # Windows Vivado build
```

## Quick Start

### Prerequisites

**macOS:**
```bash
brew install icarus-verilog verilator yosys
```

**Windows:**
- Xilinx Vivado 2023.1+ (for FPGA synthesis)

### Run Simulation

```bash
cd tensorcore/verification/verilator
make run
```

**Expected Output:**
```
VPU TEST PASSED
MMU Computation Complete.
```

### FPGA Build Workflow

**Step 1: Verify on macOS**
```bash
cd tensorcore
./scripts/verify_macos.sh
```

**Step 2: Build on Windows (Vivado)**
```batch
cd tensorcore\scripts
build_vivado.bat
```

### ASIC Synthesis (OpenROAD)

```bash
cd tensorcore/openroad
make synth_report  # Quick synthesis stats
make report        # Full flow with area/power
```

## Architecture

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

## AXI Register Map

| Offset | Name | Access | Description |
|--------|------|--------|-------------|
| 0x00 | CTRL | R/W | Control register (start/reset/mode) |
| 0x04 | STATUS | R | Status register (done/busy/state) |
| 0x08-0x10 | K1/K2/K3 | R/W | Matrix dimensions |
| 0x14-0x1C | BASE_ADDR | R/W | Matrix base addresses |
| 0x20-0x28 | PERF | R | Performance counters |

## Performance Counters

The `PerfMonitor` module tracks:
- Total execution cycles
- Memory read/write operations
- Compute cycles (SA active)
- Stall cycles (memory wait)

## Contributing

This is an academic project for the Hardware for AI course. Contributions and feedback are welcome!

## License

Licensed under the Apache License, Version 2.0 - See [LICENSE](LICENSE) for details.

## Acknowledgments

- Xilinx/AMD for Vivado tools
- OpenROAD project for ASIC flow
- PYNQ community for documentation