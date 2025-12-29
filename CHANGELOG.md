# Changelog

All notable changes to TensorCore-FPGA are documented in this file.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---

## [1.5.0] - 2025-12-29

### Added
- **PYNQ-Z1 Deployment** - Complete deployment to Xilinx Zynq-7020 board
- **Synthesizable Modules** - `TensorCore_Synth.v`, `VPU_Synth.v`, `Control_Synth.v`, `Memory_Synth.v`
- **AXI4-Lite Wrapper** - `TensorCore_AXI_Wrapper.v` for PS-PL interface
- **PYNQ Top Module** - `TensorCore_PYNQ_Top.v` with LED status indicators
- **LED Status Indicators** - LD0 (done), LD1 (busy), LD2-3 (FSM state)
- **One-Click Build Script** - `vivado/tcl/build_all.tcl` for complete Vivado flow
- **PYNQ Python Driver** - `pynq/tensorcore/driver.py` with Q16.16 fixed-point utilities
- **Demo Notebooks** - `01_tensorcore_demo.ipynb` and `demo.ipynb` with verified outputs
- **PYNQ Deployment Guide** - `docs/PYNQ_DEPLOYMENT.md` with Zynq architecture diagram

### Fixed
- **Done Signal Latching** - FSM done signal now stays high until next start (was 1 clock cycle)
- **Timing Violations** - Reduced PL clock from 100MHz to 70MHz (WNS=+0.284ns)
- **HWH File Generation** - Fixed corrupted hardware handoff in build script

### Verified on Hardware
- 2x2 matrix: 72 cycles
- 4x4 matrix: 488 cycles
- 8x8 matrix: 1,684 cycles
- 16x16 matrix: 12,520 cycles
- VPU L2 Norm: 556 cycles
- VPU Softmax: 523 cycles

### Resource Utilization (xc7z020clg400-1)
- LUTs: 2.08% (1,104 / 53,200)
- Registers: 0.83% (879 / 106,400)
- Build Time: ~9 minutes

---

## [1.4.0] - 2025-12-28

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

### GDS Regenerated
- Die Size: 219.7µm × 223.3µm (was 196.2µm × 201.5µm)
- Cell Count: 107 (was 88)
- File Size: 6.5 MB (was 5.0 MB)

---

## [1.3.0] - 2025-12-27

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

## [1.2.0] - 2025-12-26

### Added
- Formal verification scripts
- Power analysis script
- Timing constraints (50MHz)
- Gate-level simulation support
- Coverage analysis support

---

## [1.1.0] - 2025-12-26

### Added
- TinyTapeout integration
- 2x2 Systolic Array
- Cocotb testbench
- EDA scripts (Magic DRC, Netgen LVS)
- SPICE models

---

## [1.0.0] - 2025-11-25

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
| 1.5.0 | 2025-12-29 | PYNQ-Z1 deployment, hardware verified |
| 1.4.0 | 2025-12-28 | FIFO, SPI, Softmax, VPU Mini, Docs |
| 1.3.0 | 2025-12-27 | 24-bit acc, double-buffering |
| 1.2.0 | 2025-12-26 | Formal, power, timing |
| 1.1.0 | 2025-12-26 | TinyTapeout integration |
| 1.0.0 | 2025-11-25 | Initial release |
