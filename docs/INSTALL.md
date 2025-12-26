# TinyTapeout Local Development Setup

This guide covers setting up a local development environment for TinyTapeout projects on Linux.

## Prerequisites

### 1. System Packages

```bash
sudo apt update && sudo apt install -y \
    python3 python3-pip python3-venv \
    iverilog gtkwave klayout \
    git make build-essential \
    docker.io librsvg2-bin pngquant

# Add user to docker group (for LibreLane)
sudo usermod -aG docker $USER
# Log out and back in for group change to take effect
```

### 2. Python Virtual Environment

```bash
mkdir -p ~/ttsetup
python3 -m venv ~/ttsetup/venv
source ~/ttsetup/venv/bin/activate
```

### 3. Install PDK via Volare

```bash
pip install volare
volare fetch --pdk sky130
volare enable --pdk sky130 $(volare ls-remote --pdk sky130 | head -1)
```

### 4. Install LibreLane & Dependencies

```bash
pip install librelane==2.4.2
pip install matplotlib gitpython chevron cairosvg gdstk \
    python-frontmatter mistune cocotb pytest
```

### 5. Clone tt-support-tools

```bash
cd /path/to/TensorCore-FPGA
git clone https://github.com/TinyTapeout/tt-support-tools tt
```

### 6. Environment Variables

Add to `~/.bashrc`:

```bash
export PDK_ROOT=~/.volare
export PDK=sky130A
export LIBRELANE_TAG=2.4.2

# Activation alias
alias tt-activate='source ~/ttsetup/venv/bin/activate && export PDK_ROOT=~/.volare PDK=sky130A LIBRELANE_TAG=2.4.2'
```

Then reload: `source ~/.bashrc`

---

## Quick Test Commands

```bash
# Activate environment
tt-activate

# RTL Simulation
cd test && make -B

# View waveforms
gtkwave tb.vcd &
```

---

## Hardening (Optional)

To generate GDS layout locally:

```bash
# Activate environment
tt-activate

# Create user config
./tt/tt_tool.py --create-user-config

# Run hardening
./tt/tt_tool.py --harden

# Generate PNG preview
./tt/tt_tool.py --create-png

# View in KLayout
./tt/tt_tool.py --open-in-klayout
```

---

## Gate-Level Simulation

After hardening, run gate-level simulation:

```bash
cd test
cp ../runs/wokwi/final/pnl/*.pnl.v gate_level_netlist.v
PDK_ROOT=~/.volare make -B GATES=yes
```

---

## Project Structure

```
TensorCore-FPGA/
├── info.yaml          # TinyTapeout project info
├── src/
│   ├── project.v      # Include file
│   ├── tt_um_tensorcore_pe.v  # TT top module
│   └── pe_mini.v      # Minimal PE implementation
├── test/
│   ├── Makefile       # Simulation makefile
│   ├── test.py        # cocotb testbench
│   ├── tb.v           # Verilog testbench wrapper
│   └── requirements.txt
└── tt/                # tt-support-tools (cloned)
```

---

## Troubleshooting

### Power Pin Error in Gate-Level Sim

The `tb.v` already includes power pin definitions:

```verilog
`ifdef GL_TEST
    wire VPWR = 1'b1;
    wire VGND = 1'b0;
`endif
```

### Docker Permission Denied

```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### Missing PDK

```bash
volare fetch --pdk sky130
volare enable --pdk sky130 $(volare ls-remote --pdk sky130 | head -1)
```

---

## Resources

- [TinyTapeout Docs](https://tinytapeout.com/)
- [Local Hardening Guide](https://tinytapeout.com/guides/local-hardening/)
- [tt-support-tools](https://github.com/TinyTapeout/tt-support-tools)
- [LibreLane Docs](https://librelane.readthedocs.io/)
