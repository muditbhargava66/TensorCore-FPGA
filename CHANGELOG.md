# Changelog

All notable changes to TensorCore-FPGA are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.3.0] - 2024-12-27

### Added
- **24-bit Accumulator** - Extended precision prevents overflow in deep networks
- **Weight Double-Buffering** - Overlap weight loading with computation
- **INT8 Quantization** - Proper saturation arithmetic

### Changed
- ProcessingElement.v enhanced with all high-priority features
- Updated synthesis metrics: 199 cells (2x2), 628 cells (4x4)

### Verified
- All 6 cocotb tests passing
- Yosys synthesis successful
- SPICE simulations working

---

## [1.2.0] - 2024-12-26

### Added
- **4x4 Systolic Array** (`SystolicArray4x4.v`) - 16 MACs for FPGA
- **Formal Verification** - SymbiYosys scripts
- **Power Analysis** - Estimation script
- **Timing Constraints** - SDC for 50MHz
- **Gate-Level Simulation** - `make GATES=yes`
- **Coverage Analysis** - `make COVERAGE=yes`

### Changed
- CI workflow with TinyTapeout hardening
- Test Makefile with GL sim support

---

## [1.1.0] - 2024-12-26

### Added
- **TinyTapeout Integration** - Complete hardening flow
- **2x2 Systolic Array** - Fits TinyTapeout tile
- **Cocotb Testbench** - 6 comprehensive tests
- **EDA Scripts** - Magic DRC, Netgen LVS, etc.
- **SPICE Models** - 6T/8T SRAM simulations
- **Documentation** - Wiki-style docs folder

### Changed
- Reorganized: `rtl/` → `src/core/`, `src/tt/`
- Removed redundant directories

---

## [1.0.0] - 2024-12-13

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
| 1.3.0 | 2024-12-27 | 24-bit accumulator, double-buffering |
| 1.2.0 | 2024-12-26 | 4x4 array, formal verification |
| 1.1.0 | 2024-12-26 | TinyTapeout integration |
| 1.0.0 | 2024-12-25 | Initial release |
