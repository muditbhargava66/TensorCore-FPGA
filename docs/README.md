# TensorCore-FPGA Documentation

Welcome to the TensorCore-FPGA documentation.

---

## 📚 Contents

| Document | Description |
|----------|-------------|
| [Installation](INSTALL.md) | Setup guide for all platforms |
| [Architecture](ARCHITECTURE.md) | System design and components |
| [TinyTapeout](TINYTAPEOUT.md) | ASIC design for TinyTapeout |
| [Simulation](SIMULATION.md) | Running tests and simulations |
| [References](REFERENCES.md) | Research papers and resources |

---

## 🚀 Quick Links

- [GitHub Repository](https://github.com/muditbhargava66/TensorCore-FPGA)
- [TinyTapeout](https://tinytapeout.com)
- [Skywater PDK](https://skywater-pdk.readthedocs.io/)
- [OpenROAD](https://openroad.readthedocs.io/)
- [Cocotb](https://www.cocotb.org/)

---

## 📊 Project Statistics

| Metric | Value |
|--------|-------|
| **RTL Modules** | 15+ |
| **Test Cases** | 6 |
| **EDA Tools** | 9 |
| **Target Platforms** | 2 (FPGA + ASIC) |

---

## 🛠️ Verification Tools

| Tool | Command | Purpose |
|------|---------|---------|
| Cocotb | `cd test && make` | RTL simulation |
| Verilator | `bash scripts/verilator_lint.sh` | Linting |
| Yosys | `yosys scripts/synth_check.ys` | Synthesis |
| ngspice | `ngspice -b sram_6t_read_svg.cir` | SPICE sim |
| SymbiYosys | `sby -f scripts/formal_verify.sby` | Formal |

---

## 📈 Recent Updates (v1.2.0)

- ✅ Added 4x4 systolic array (16 MACs)
- ✅ Added formal verification scripts
- ✅ Added power analysis script
- ✅ Added timing constraints (50MHz)
- ✅ Gate-level simulation support
- ✅ Coverage analysis support

---

## 📖 Getting Started

1. Clone the repository
2. Follow [Installation Guide](INSTALL.md)
3. Run tests: `cd test && make`
4. Build for TinyTapeout: `python3 tt/tt_tool.py --harden`
