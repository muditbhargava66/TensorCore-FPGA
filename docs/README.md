# TensorCore-FPGA Documentation

Welcome to the TensorCore-FPGA documentation.

## Contents

| Document | Description |
|----------|-------------|
| [Installation](INSTALL.md) | Setup guide for all platforms |
| [Architecture](ARCHITECTURE.md) | Hardware architecture overview |
| [TinyTapeout](TINYTAPEOUT.md) | ASIC design for TinyTapeout |
| [Simulation](SIMULATION.md) | Running tests and simulations |

---

## Quick Links

- [GitHub Repository](https://github.com/muditbhargava66/TensorCore-FPGA)
- [TinyTapeout](https://tinytapeout.com)
- [OpenROAD](https://openroad.readthedocs.io)

---

## Project Overview

TensorCore-FPGA is a hardware accelerator for Large Language Model inference:

- **Systolic Array**: Configurable MxN tile-based matrix multiplication
- **Vector Processing**: FlashAttention-style Softmax
- **Multi-Platform**: FPGA (PYNQ-Z1) and ASIC (TinyTapeout/SKY130)

---

## Getting Started

1. Clone the repository
2. Follow [Installation Guide](INSTALL.md)
3. Run tests: `cd test && make`
4. Build for TinyTapeout: `python3 tt/tt_tool.py --harden`
