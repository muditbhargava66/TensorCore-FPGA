# TensorCore-FPGA Documentation

Welcome to the TensorCore-FPGA documentation.

---

## 📚 Contents

| Document | Description |
|----------|-------------|
| [Installation](INSTALL.md) | Setup guide for all platforms |
| [Architecture](ARCHITECTURE.md) | System design and components |
| [TinyTapeout](TINYTAPEOUT.md) | ASIC design guide |
| [Simulation](SIMULATION.md) | Running tests and verification |
| [References](REFERENCES.md) | Research papers |

---

## ✅ Verification Status (v1.3.0)

| Tool | Status | Output |
|------|--------|--------|
| **Cocotb** | ✅ Pass | 6/6 tests |
| **Yosys** | ✅ Pass | 199 cells (2x2) |
| **Verilator** | ✅ Pass | TT clean |
| **ngspice** | ✅ Pass | 2,134 rows |
| **SystemC** | ✅ Pass | 32x32 array |
| **GDS** | ✅ Pass | 5.0 MB |

---

## 🆕 Latest Features (v1.3.0)

- **24-bit Accumulator** - Extended precision
- **Weight Double-Buffering** - Overlapped loading
- **INT8 Quantization** - Saturation arithmetic
- **4x4 Systolic Array** - 16 MACs for FPGA

---

## 🛠️ Quick Commands

```bash
# Run all tests
cd test && make

# Synthesize
yosys scripts/synth_check.ys

# SPICE simulation
cd model/spice && ngspice -b sram_6t_read_svg.cir

# SystemC simulation
cd model/systemc/sa_model && ./testbench
```

---

## 📊 Design Metrics

| Configuration | MACs | Cells | Target |
|---------------|------|-------|--------|
| 2x2 Array | 4 | 199 | TinyTapeout |
| 4x4 Array | 16 | 628 | FPGA |

---

## 🔗 Links

- [GitHub Repository](https://github.com/muditbhargava66/TensorCore-FPGA)
- [TinyTapeout](https://tinytapeout.com)
- [Changelog](../CHANGELOG.md)
