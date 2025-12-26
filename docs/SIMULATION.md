# Simulation Guide

This document covers all simulation and verification options in TensorCore-FPGA.

---

## Quick Verification

Run all checks with:
```bash
# Cocotb tests
cd test && make

# Yosys synthesis
yosys scripts/synth_check.ys

# Verilator lint
bash scripts/verilator_lint.sh
```

---

## 1. RTL Simulation (Cocotb)

Python-based verification for TinyTapeout design.

### Run Tests
```bash
cd test
make clean && make
```

### Test Cases

| Test | Description | Status |
|------|-------------|--------|
| `test_reset` | Verify reset behavior | ✅ |
| `test_clear_accumulators` | Test accumulator clearing | ✅ |
| `test_weight_loading` | Verify weight preload | ✅ |
| `test_simple_mac` | Single MAC operation | ✅ |
| `test_systolic_flow` | Data flow through array | ✅ |
| `test_overflow_detection` | Saturation and overflow | ✅ |

### Advanced Options
```bash
# Gate-level simulation
make GATES=yes

# Coverage collection
make COVERAGE=yes
```

---

## 2. SPICE Simulation

SRAM cell characterization using ngspice.

### Run
```bash
cd model/spice
ngspice -b sram_6t_read_svg.cir    # Batch with waveform
ngspice sram_6t_read.cir            # Interactive
```

### Available Circuits

| File | Description | Output |
|------|-------------|--------|
| `sram_6t_read.cir` | 6T SRAM read | 2,134 rows |
| `sram_6t_write.cir` | 6T SRAM write | ✅ |
| `sram_8t_read.cir` | 8T SRAM read | 2,050 rows |
| `sram_8t_write.cir` | 8T SRAM write | ✅ |

### Generate Waveform Image
```bash
gs -dBATCH -dNOPAUSE -sDEVICE=png16m -r150 \
   -sOutputFile=waveform.png sram_6t_read_waveform.ps
```

---

## 3. SystemC Simulation

High-level behavioral modeling (32x32 systolic array).

### Compile & Run
```bash
cd model/systemc/sa_model
g++ -std=c++17 testbench.cpp -o testbench -lsystemc
./testbench
```

### Expected Output
```
SystemC 2.3.3-Accellera
PE Grid Size: 32x32
TEST 1: 5x5 Matrix Multiplication (WS Mode)
Input A (5x5): 1.0 2.0 3.0 ...
```

---

## 4. Verilator Lint

Static analysis for RTL code.

### Run
```bash
bash scripts/verilator_lint.sh
```

### Expected Results
- TinyTapeout design: Clean
- Core design: 5 warnings (behavioral code)

---

## 5. Yosys Synthesis

Verify synthesizability.

### Run
```bash
yosys scripts/synth_check.ys
```

### Metrics

| Design | Cells | Status |
|--------|-------|--------|
| 2x2 Array | ~2,800 | ✅ |
| 4x4 Array | ~5,600 | ✅ |

---

## 6. TinyTapeout GDS

Generate ASIC layout.

### Run Hardening
```bash
pip install librelane volare
volare enable --pdk-root ~/.volare
python3 tt/tt_tool.py --harden
python3 tt/tt_tool.py --create-png
```

### GDS Output
- `runs/wokwi/final/gds/tt_um_tensorcore_pe.gds` (5.0 MB)

---

## Tool Status Summary

| Tool | Command | Status |
|------|---------|--------|
| **Cocotb** | `cd test && make` | ✅ 6/6 pass |
| **Verilator** | `bash scripts/verilator_lint.sh` | ✅ Clean |
| **Yosys** | `yosys scripts/synth_check.ys` | ✅ |
| **ngspice** | `ngspice -b sram_6t_read_svg.cir` | ✅ 2,134 rows |
| **SystemC** | `./testbench` | ✅ 32x32 array |
| **GDS** | `tt_tool.py --harden` | ✅ 5.0 MB |
