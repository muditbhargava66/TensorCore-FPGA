# TensorCore-FPGA Documentation

## Contents

| Document | Description |
|----------|-------------|
| [Installation](INSTALL.md) | Setup guide |
| [Architecture](ARCHITECTURE.md) | System design |
| [TinyTapeout](TINYTAPEOUT.md) | ASIC guide |
| [Simulation](SIMULATION.md) | Running tests |
| [Benchmarks](BENCHMARKS.md) | Performance metrics |
| [Power](POWER_MEASUREMENT.md) | Power analysis |
| [GTKWave](GTKWAVE_WALKTHROUGH.md) | Waveform guide |
| [Comparison](COMPARISON.md) | GPU/TPU comparison |
| [References](REFERENCES.md) | Research papers |

---

## v1.4.0 Status

### Modules
| Module | Cells | Description |
|--------|-------|-------------|
| FIFO | 36 | Sync data staging |
| SPI Slave | 32 | Weight loading |
| Softmax | 92 | INT8 softmax |
| VPU Mini | 102 | L2 Norm, ReLU |

### GDS (Regenerated)
- Size: 219.7µm × 223.3µm
- Cells: 107
- File: 6.5 MB

### Verification
| Tool | Result |
|------|--------|
| Cocotb | 6/6 pass |
| Yosys | 199 cells |
| SPICE | 2,134 rows |
| SystemC | 32x32 array |

---

## Quick Commands
```bash
cd test && make        # Run tests
yosys scripts/synth_check.ys  # Synthesize
```

---

[← Back to Main README](../README.md)
