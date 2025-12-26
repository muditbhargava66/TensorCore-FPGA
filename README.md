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

## 🚀 Features

| Feature | Description |
|---------|-------------|
| **Systolic Arrays** | 2x2 (TinyTapeout) and 4x4 (FPGA) configurations |
| **Weight Stationary** | Optimized dataflow for inference |
| **8-bit Signed MAC** | Multiply-accumulate with saturation |
| **VPU** | L2 Normalization + FlashAttention Softmax |
| **Multi-Target** | FPGA (PYNQ-Z1) + ASIC (TinyTapeout/SKY130) |
| **AXI4-Lite** | PS-PL control interface |
| **Performance Monitor** | Cycle counters and memory tracking |

---

## 📊 TinyTapeout ASIC Results

| Metric | 2x2 Array | 4x4 Array |
|--------|-----------|-----------|
| **MACs** | 4 | 16 |
| **Cells** | 2,872 | ~10,000 |
| **Utilization** | 49.4% | ~85% |
| **Clock** | 50 MHz | 50 MHz |
| **Throughput** | 200 MMAC/s | 800 MMAC/s |

### Verification Status

| Check | Status |
|-------|--------|
| DRC | ✅ Passed |
| LVS | ✅ Passed |
| Antenna | ✅ Passed |
| Timing | ✅ 2.34ns slack |
| Cocotb | ✅ 6/6 tests |

---

## 🛠️ Quick Start

### Prerequisites

```bash
# Ubuntu 22.04+
sudo apt install iverilog verilator yosys ngspice

# Python packages
pip install cocotb pytest librelane volare
```

### Run Tests

```bash
cd test && make clean && make
```

### Synthesize

```bash
yosys scripts/synth_check.ys
```

### TinyTapeout Hardening

```bash
pip install librelane volare
volare enable sky130 --pdk-root ~/.volare
python3 tt/tt_tool.py --harden
```

---

## 📁 Project Structure

```
TensorCore-FPGA/
├── src/
│   ├── core/           # Full TensorCore (12 modules)
│   ├── tt/             # TinyTapeout designs
│   │   ├── ProcessingElement.v
│   │   ├── SystolicArray2x2.v  (TT target)
│   │   ├── SystolicArray4x4.v  (FPGA target)
│   │   └── tt_um_tensorcore.v
│   └── include/        # Verilog headers
├── test/               # Cocotb testbench
├── scripts/            # EDA tool scripts
├── model/
│   ├── spice/          # SRAM simulations
│   └── systemc/        # Behavioral models
├── vivado/             # Xilinx FPGA flow
├── pynq/               # Python drivers
└── docs/               # Documentation
```

---

## 🔧 EDA Tools

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
| **LibreLane** | TT hardening | ✅ |

---

## 📈 Verification Scripts

```bash
# Cocotb tests
cd test && make

# Gate-level simulation
make GATES=yes

# Coverage collection
make COVERAGE=yes

# Verilator lint
bash scripts/verilator_lint.sh

# SPICE simulation
cd model/spice && ngspice -b sram_6t_read_svg.cir

# Power analysis
bash scripts/power_analysis.sh
```

---

## 🏗️ Architecture

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

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [Installation](docs/INSTALL.md) | Setup guide |
| [Architecture](docs/ARCHITECTURE.md) | System design |
| [TinyTapeout](docs/TINYTAPEOUT.md) | ASIC guide |
| [Simulation](docs/SIMULATION.md) | Running tests |
| [References](docs/REFERENCES.md) | Research papers |
| [Changelog](CHANGELOG.md) | Version history |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests: `cd test && make`
4. Submit a pull request

---

## 📄 License

Apache License 2.0 - See [LICENSE](LICENSE)

---

## 🙏 Acknowledgments

- [TinyTapeout](https://tinytapeout.com) - ASIC platform
- [Skywater PDK](https://skywater-pdk.readthedocs.io/) - Open PDK
- [OpenROAD](https://openroad.readthedocs.io/) - ASIC flow
- [Cocotb](https://www.cocotb.org/) - Python testbench