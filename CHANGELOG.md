# Changelog

All notable changes to TensorCore-FPGA are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.0] - 2024-12-26

### Added
- **4x4 Systolic Array** (`src/tt/SystolicArray4x4.v`) - 16-MAC configuration for FPGA
- **Formal Verification** - SymbiYosys config (`scripts/formal_verify.sby`)
- **SVA Properties** - Formal properties (`scripts/formal_properties.sv`)
- **Power Analysis** - Script for power estimation (`scripts/power_analysis.sh`)
- **Timing Constraints** - SDC for 50MHz target (`scripts/timing_constraints.sdc`)
- **Gate-Level Simulation** - Support via `make GATES=yes`
- **Coverage Analysis** - Support via `make COVERAGE=yes`
- **CI Hardening Job** - TinyTapeout hardening in GitHub Actions

### Changed
- Updated CI workflow with 4x4 synthesis check
- Enhanced test/Makefile with GL sim and coverage support
- Updated .gitignore for cleaner tracking

### Verified
- All 6 cocotb tests passing
- Yosys synthesis: 2,591 cells (2x2), ~10,000 cells (4x4)
- SPICE simulations: 2,134 data rows

---

## [1.1.0] - 2024-12-26

### Added
- **TinyTapeout Integration** - Complete hardening flow
- **2x2 Systolic Array** - Fits TinyTapeout tile (49.4% utilization)
- **Processing Element** - 8-bit signed MAC with saturation
- **Cocotb Testbench** - 6 comprehensive tests
- **EDA Scripts** - Magic DRC, Netgen LVS, Verilator lint, OpenRAM setup
- **SPICE Models** - 6T/8T SRAM read/write simulations
- **Documentation** - Wiki-style docs folder
- **GDS Generation** - Working TinyTapeout layout

### Changed
- Reorganized project structure: `rtl/` → `src/core/`, `src/tt/`
- Removed redundant directories: `openlane/`, `openroad/`, `verification/`
- Updated Vivado TCL scripts for new paths

### Removed
- `Resources/` folder (PDFs) - documented in REFERENCES.md
- Old verification testbenches
- Duplicate configuration files

### Results
- DRC: ✅ Passed
- LVS: ✅ Passed
- Timing: ✅ 2.34ns setup slack
- Cells: 2,872
- Area: 42,826 μm²

---

## [1.0.0] - 2024-12-13

### Added
- Initial TensorCore architecture
- Systolic Array (SA_MxN) with configurable dimensions
- Vector Processing Unit (VPU) with Softmax and L2 Norm
- Control unit with tile-based dataflow
- Performance Monitor (PerfMonitor)
- AXI4-Lite wrapper for PS-PL communication
- Vivado project for PYNQ-Z1
- PYNQ Python drivers
- SystemC behavioral models

### Targets
- FPGA: PYNQ-Z1 (Zynq-7020)
- ASIC: SKY130 PDK

---

## Version History Summary

| Version | Date | Highlights |
|---------|------|------------|
| 1.2.0 | 2024-12-26 | 4x4 array, formal verification, power analysis |
| 1.1.0 | 2024-12-26 | TinyTapeout integration, GDS generation |
| 1.0.0 | 2024-12-25 | Initial release with core architecture |
