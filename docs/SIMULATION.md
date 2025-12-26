# Simulation Guide

This document covers all simulation options available in TensorCore-FPGA.

---

## RTL Simulation (Cocotb)

Cocotb provides Python-based verification for the TinyTapeout design.

### Setup

```bash
pip install cocotb pytest
```

### Run Tests

```bash
cd test
make clean && make
```

### Test Cases

| Test | Description |
|------|-------------|
| `test_reset` | Verify reset behavior |
| `test_clear_accumulators` | Test accumulator clearing |
| `test_weight_loading` | Verify weight preload |
| `test_simple_mac` | Single MAC operation |
| `test_systolic_flow` | Data flow through array |
| `test_overflow_detection` | Saturation and overflow |

### View Waveforms

```bash
gtkwave test/tb.vcd
```

---

## SystemC Simulation

High-level behavioral modeling for architecture exploration.

### Setup

```bash
sudo apt install libsystemc-dev
```

### Compile & Run

```bash
cd model/systemc/sa_model
g++ -std=c++17 testbench.cpp -o testbench -lsystemc
./testbench
```

### Output

```
SystemC 2.3.3-Accellera
PE Grid Size: 32x32
TEST 1: 5x5 Matrix Multiplication (WS Mode)
```

---

## SPICE Simulation

Circuit-level SRAM cell characterization.

### Setup

```bash
sudo apt install ngspice
```

### Run Simulations

```bash
cd model/spice

# Batch mode with PNG output
ngspice -b sram_6t_read_svg.cir

# Interactive mode
ngspice sram_6t_read.cir
```

### Available Circuits

| File | Description |
|------|-------------|
| `sram_6t_read.cir` | 6T SRAM read operation |
| `sram_6t_write.cir` | 6T SRAM write operation |
| `sram_8t_read.cir` | 8T SRAM read operation |
| `sram_8t_write.cir` | 8T SRAM write operation |

### Convert to PNG

```bash
gs -dBATCH -dNOPAUSE -sDEVICE=png16m -r150 \
   -sOutputFile=waveform.png waveform.ps
```

---

## Verilator Linting

Static analysis for RTL code.

### Run Lint

```bash
bash scripts/verilator_lint.sh
```

### Expected Warnings

The core RTL has some expected warnings for behavioral code:
- `$bitstoreal` usage for debug
- Unused signal bits

---

## Yosys Synthesis Check

Verify synthesizability without PDK.

### Run Check

```bash
yosys scripts/synth_check.ys
```

### Expected Output

```
Number of cells: 2,591
  $_DFF_P_: 199
  $_AND_: 419
  ...
```
