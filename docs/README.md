# TensorCore-FPGA Documentation

## Contents

| Document | Description |
|----------|-------------|
| [Installation](INSTALL.md) | Setup guide |
| [Architecture](ARCHITECTURE.md) | System design |
| [**PYNQ Deployment**](PYNQ_DEPLOYMENT.md) | PYNQ-Z1 guide with verified results |
| [TinyTapeout](TINYTAPEOUT.md) | ASIC guide |
| [Simulation](SIMULATION.md) | Running tests |
| [Benchmarks](BENCHMARKS.md) | Performance metrics |
| [Power](POWER_MEASUREMENT.md) | Power analysis |
| [GTKWave](GTKWAVE_WALKTHROUGH.md) | Waveform guide |
| [Comparison](COMPARISON.md) | GPU/TPU comparison |
| [References](REFERENCES.md) | Research papers |

---

## v1.5.0 Status (Latest)

### PYNQ-Z1 Hardware Verified ✅

| Matrix Size | Cycles | Time @ 70MHz |
|-------------|--------|--------------|
| 2×2 | 72 | 1.03 µs |
| 4×4 | 488 | 6.97 µs |
| 8×8 | 1,684 | 24.06 µs |
| 16×16 | 12,520 | 178.86 µs |

### Resource Utilization
- **LUTs**: 2.08% (1,104 / 53,200)
- **Registers**: 0.83% (879 / 106,400)
- **Timing**: Met @ 70 MHz (WNS = +0.284 ns)

### Modules
| Module | Cells | Description |
|--------|-------|-------------|
| TensorCore_Synth | ~600 | Full accelerator |
| VPU_Synth | ~200 | Vector processing |
| Control_Synth | ~150 | FSM controller |
| Memory_Synth | ~100 | BRAM interface |

### Verification
| Tool | Result |
|------|--------|
| Cocotb | 6/6 pass |
| PYNQ-Z1 | ✅ Hardware verified |
| Yosys | 199 cells (2x2) |
| SPICE | 2,134 rows |

---

## Quick Commands
```bash
cd test && make                    # Run tests
cd vivado && vivado -mode batch -source tcl/build_all.tcl  # Build for PYNQ
```

---

[← Back to Main README](../README.md)
