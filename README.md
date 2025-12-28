<div align="center">

# TensorCore-FPGA

> A high-performance LLM accelerator featuring Systolic Arrays and Vector Processing Units for FPGA and ASIC targets.

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![FPGA](https://img.shields.io/badge/FPGA-Zynq--7020-blue.svg)](https://www.xilinx.com/products/silicon-devices/soc/zynq-7000.html)
[![TinyTapeout](https://img.shields.io/badge/TinyTapeout-Ready-green.svg)](https://tinytapeout.com)
[![Tests](https://img.shields.io/badge/Tests-6%2F6_Passing-brightgreen.svg)](#verification)
[![PDK](https://img.shields.io/badge/PDK-SKY130-orange.svg)](https://skywater-pdk.readthedocs.io/)
[![Yosys](https://img.shields.io/badge/Yosys-Synthesizable-purple.svg)](https://yosyshq.net/yosys/)
[![CI](https://github.com/muditbhargava66/TensorCore-FPGA/actions/workflows/ci.yml/badge.svg)](https://github.com/muditbhargava66/TensorCore-FPGA/actions)

</div>

---

## Features

| Feature | Description |
|---------|-------------|
| **Systolic Arrays** | 2x2 (TinyTapeout) and 4x4 (FPGA) configurations |
| **24-bit Accumulator** | Extended precision for many accumulations |
| **Weight Double-Buffering** | Overlap weight loading with computation |
| **INT8 Quantization** | 8-bit signed arithmetic with saturation |
| **VPU** | L2 Normalization + FlashAttention Softmax |
| **Multi-Target** | FPGA (PYNQ-Z1) + ASIC (TinyTapeout/SKY130) |
| **AXI4-Lite** | PS-PL control interface |

---

## Design Metrics

| Configuration | MACs | Cells | Wires | Target |
|---------------|------|-------|-------|--------|
| **2x2 Array** | 4 | 199 | 265 | TinyTapeout |
| **4x4 Array** | 16 | 628 | 796 | FPGA |

### Processing Element Features
- **24-bit accumulator** - Prevents overflow in deep networks
- **Weight double-buffering** - Load next tile while computing
- **INT8 saturation** - Clamps output to [-128, 127]

### Verification Status

| Check | Status |
|-------|--------|
| Cocotb Tests | ✅ 6/6 Passing |
| Yosys Synthesis | ✅ 199 cells (2x2) |
| Verilator Lint | ✅ Clean |
| SPICE Simulation | ✅ 2,134 rows |

---

## ASIC Layout (TinyTapeout)

The design has been hardened for TinyTapeout using the SKY130 PDK:

![TensorCore GDS Layout](docs/images/gds_render.png)

**Layout Specifications:**
- **Die Size:** 196.2 µm × 201.5 µm
- **Cell Count:** 88 standard cells
- **Layers:** 40 metal/via layers
- **PDK:** Skywater SKY130

---

## SPICE Simulation

6T SRAM cell characterization using ngspice (TSMC 180nm):

![SRAM Read Waveform](docs/images/sram_6t_read_waveform.png)

**Waveform Analysis:**
- **BL/BL_bar:** Bit lines start pre-charged, develop differential on read
- **WL:** Word line activates to enable cell access
- **Q/Qbar:** Storage nodes maintain stable voltage (~1.7V)
- **Sense Amp:** Amplifies differential to rail-to-rail output

---

## Quick Start

### Prerequisites

```bash
# Ubuntu 22.04+
sudo apt install iverilog verilator yosys ngspice

# Python packages
pip install cocotb pytest
```

### Run Tests

```bash
cd test && make clean && make
```

### Synthesize

```bash
yosys scripts/synth_check.ys
```

---

## Project Structure

```
TensorCore-FPGA/
├── src/
│   ├── core/           # Full TensorCore (12 modules)
│   ├── tt/             # TinyTapeout designs
│   │   ├── ProcessingElement.v   # Enhanced PE (24-bit acc)
│   │   ├── SystolicArray2x2.v    # 4 MACs (TT target)
│   │   ├── SystolicArray4x4.v    # 16 MACs (FPGA)
│   │   └── tt_um_tensorcore.v    # Top module
│   └── include/        # Verilog headers
├── test/               # Cocotb testbench
├── scripts/            # EDA tool scripts
├── model/              # SPICE & SystemC models
├── vivado/             # Xilinx FPGA flow
├── pynq/               # Python drivers
└── docs/               # Documentation
```

---

## EDA Tools

| Tool | Purpose | Status |
|------|---------|--------|
| **Yosys** | Synthesis | ✅ |
| **Verilator** | Linting | ✅ |
| **Icarus Verilog** | Simulation | ✅ |
| **Cocotb** | Python testbench | ✅ |
| **ngspice** | SPICE simulation | ✅ |
| **Magic** | DRC | ✅ |
| **Netgen** | LVS | ✅ |
| **KLayout** | GDS viewer | ✅ |

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        TensorCore                            │
├──────────────────────────────────────────────────────────────┤
│  ┌────────────┐    ┌─────────────────┐    ┌────────────┐     │
│  │  Control   │───▶│   Systolic      │───▶│    VPU     │     │
│  │  (Tiling)  │    │   Array (MxN)   │    │ (Softmax)  │     │
│  └────────────┘    └─────────────────┘    └────────────┘     │
│        │                   │                    │            │
│        ▼                   ▼                    ▼            │
│  ┌──────────────────────────────────────────────────────┐    │
│  │                    Memory Subsystem                  │    │
│  └──────────────────────────────────────────────────────┘    │
├──────────────────────────────────────────────────────────────┤
│  ┌─────────────┐                      ┌──────────────────┐   │
│  │ PerfMonitor │                      │  AXI4-Lite (PS)  │   │
│  └─────────────┘                      └──────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Installation](docs/INSTALL.md) | Setup guide |
| [Architecture](docs/ARCHITECTURE.md) | System design |
| [TinyTapeout](docs/TINYTAPEOUT.md) | ASIC guide |
| [Simulation](docs/SIMULATION.md) | Running tests |
| [Changelog](CHANGELOG.md) | Version history |

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests: `cd test && make`
4. Submit a pull request

---

## License

Apache License 2.0 - See [LICENSE](LICENSE)

---

## Acknowledgments

- [TinyTapeout](https://tinytapeout.com) - ASIC platform
- [Skywater PDK](https://skywater-pdk.readthedocs.io/) - Open PDK
- [Cocotb](https://www.cocotb.org/) - Python testbench