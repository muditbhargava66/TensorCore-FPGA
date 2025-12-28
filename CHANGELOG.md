# Changelog

All notable changes to TensorCore-FPGA are documented in this file.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---

## [1.4.0] - 2024-12-28

### Added
- **FIFO Buffer** (`FIFO.v`) - 8x8 sync FIFO, 36 cells
- **SPI Slave** (`SPI_Slave.v`) - Mode 0 weight loading, 32 cells
- **Softmax Unit** (`SoftmaxUnit.v`) - INT8 softmax with LUT, 92 cells
- **VPU Mini** (`VPU_Mini.v`) - L2 Norm, ReLU, PassThru, 102 cells
- **OpenRAM Config** (`openram_tt.py`) - 256x8 SRAM configuration
- **BENCHMARKS.md** - GEMM throughput measurements
- **POWER_MEASUREMENT.md** - INA219 power guide
- **GTKWAVE_WALKTHROUGH.md** - Waveform viewing guide
- **COMPARISON.md** - GPU/TPU comparison report
- **01_tensorcore_demo.ipynb** - PYNQ demo notebook

### Fixed
- `.gitignore` blocking pattern removed
- README emoji cleanup

---

## [1.3.0] - 2024-12-27

### Added
- **24-bit Accumulator** - Extended precision
- **Weight Double-Buffering** - Overlapped loading
- **INT8 Quantization** - Saturation arithmetic
- **4x4 Systolic Array** - 16 MACs for FPGA
- GDS layout and SPICE waveform images in README

### Verified
- Cocotb: 6/6 tests passing
- Yosys: 199 cells (2x2), 628 cells (4x4)

---

## [1.2.0] - 2024-12-26

### Added
- Formal verification scripts
- Power analysis script
- Timing constraints (50MHz)
- Gate-level simulation support
- Coverage analysis support

---

## [1.1.0] - 2024-12-26

### Added
- TinyTapeout integration
- 2x2 Systolic Array
- Cocotb testbench
- EDA scripts (Magic DRC, Netgen LVS)
- SPICE models

---

## [1.0.0] - 2024-12-25

### Added
- Initial TensorCore architecture
- Systolic Array (SA_MxN)
- Vector Processing Unit (VPU)
- AXI4-Lite wrapper
- Vivado/PYNQ support

---

## Summary

| Version | Date | Highlights |
|---------|------|------------|
| 1.4.0 | 2024-12-28 | FIFO, SPI, Softmax, VPU Mini, Docs |
| 1.3.0 | 2024-12-27 | 24-bit acc, double-buffering |
| 1.2.0 | 2024-12-26 | Formal, power, timing |
| 1.1.0 | 2024-12-26 | TinyTapeout integration |
| 1.0.0 | 2024-12-25 | Initial release |
