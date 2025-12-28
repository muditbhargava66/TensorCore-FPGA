# GTKWave Waveform Walkthrough

## Viewing Simulation Waveforms

### Generate VCD File
```bash
cd test
make clean && make
# Creates test/sim_build/tb.vcd
```

### Open in GTKWave
```bash
gtkwave test/sim_build/tb.vcd
```

---

## Key Signals to Observe

### Clock and Reset
- `clk` - System clock (50 MHz)
- `rst_n` - Active-low reset

### Control Signals
- `ui_in[7:6]` - Mode: 00=NOP, 01=CLEAR, 10=LOAD, 11=COMPUTE
- `ena` - Enable signal

### Data Path
- `ui_in[5:0]` - Input data (6-bit)
- `uo_out[7:0]` - Output result

### Internal (if exposed)
- `pe_*/accumulator` - PE accumulator values
- `pe_*/weight_active` - Loaded weights

---

## Typical Waveform Sequence

```
Time    Mode     Action
─────   ────     ──────
0ns     RESET    rst_n=0
100ns   CLEAR    Clear accumulators
200ns   LOAD     Load weights [w0,w1,w2,w3]
400ns   COMPUTE  Input activations, observe outputs
800ns   DONE     Results on uo_out
```

---

## Screenshot Guide

1. Add signals: File → Read Save File → select provided .gtkw
2. Zoom to fit: View → Zoom Fit
3. Annotate: Edit → Insert Comment

### Save Configuration
```bash
# Save current view
gtkwave -S signals.gtkw tb.vcd
```

---

## Video Recording (Optional)

```bash
# Using SimpleScreenRecorder
simplescreenrecorder --start-hidden

# Or OBS
obs --startrecording
```
