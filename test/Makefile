# TinyTapeout Simulation Makefile
# Supports RTL, gate-level simulation, and coverage

SIM ?= icarus
TOPLEVEL_LANG ?= verilog
TOPLEVEL = tb
MODULE = test

# Source files - TinyTapeout Systolic Array
VERILOG_SOURCES += $(PWD)/tb.v
VERILOG_SOURCES += $(PWD)/../src/tt/ProcessingElement.v
VERILOG_SOURCES += $(PWD)/../src/tt/SystolicArray2x2.v
VERILOG_SOURCES += $(PWD)/../src/tt/tt_um_tensorcore.v

# Include paths
COMPILE_ARGS += -I$(PWD)/../src/tt

# Gate-level simulation support
ifeq ($(GATES),yes)
  COMPILE_ARGS += -DGL_TEST -DFUNCTIONAL -DSIM -DUSE_POWER_PINS
  VERILOG_SOURCES = $(PWD)/tb.v
  VERILOG_SOURCES += $(PWD)/gate_level_netlist.v
  ifdef PDK_ROOT
    VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
    VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v
  endif
else
  COMPILE_ARGS += -DRTL_SIM
endif

# Coverage support
ifeq ($(COVERAGE),yes)
  export COVERAGE=1
  EXTRA_ARGS += --coverage
endif

# Cocotb configuration
export COCOTB_REDUCED_LOG_FMT=1
export COCOTB_RESULTS_FILE=results.xml

include $(shell cocotb-config --makefiles)/Makefile.sim

# Phony targets
.PHONY: clean waves coverage gl-sim

# Clean
clean::
	rm -rf __pycache__ results.xml *.vcd sim_build/ htmlcov/ .coverage*

# Waveform viewer
waves: tb.vcd
	gtkwave $< &

# Gate-level simulation
gl-sim:
	$(MAKE) GATES=yes

# Coverage report
coverage:
	$(MAKE) COVERAGE=yes
	@echo "Coverage data collected"
