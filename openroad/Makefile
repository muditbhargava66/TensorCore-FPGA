# =============================================================================
# HAI Processor - OpenROAD ASIC Synthesis Flow
# Target: SKY130 PDK
# =============================================================================

# Design settings
export DESIGN_NAME = HAI_Processor
export DESIGN_TOP  = HAI_Processor

# Technology
export PLATFORM    = sky130hd
export TECH_LEF    = $(PLATFORM)/lef/sky130_fd_sc_hd.tlef
export SC_LEF      = $(PLATFORM)/lef/sky130_fd_sc_hd_merged.lef

# Clock
export CLOCK_PERIOD = 10.0
export CLOCK_PORT   = clk

# Directories
export VERILOG_DIR  = ../rtl/core
export INCLUDE_DIR  = ../rtl/include
export RESULTS_DIR  = results
export REPORTS_DIR  = reports
export LOG_DIR      = logs

# Source files
VERILOG_FILES = \
    $(VERILOG_DIR)/MAC.v \
    $(VERILOG_DIR)/PE_Synth.v \
    $(VERILOG_DIR)/SA_MxN_Synth.v \
    $(VERILOG_DIR)/VPU_Synth.v \
    $(VERILOG_DIR)/PerfMonitor.v \
    $(VERILOG_DIR)/Memory.v \
    $(VERILOG_DIR)/MatMul_Controller.v \
    $(VERILOG_DIR)/Control.v \
    $(VERILOG_DIR)/HAI_Processor.v

# =============================================================================
# Main Targets
# =============================================================================

.PHONY: all synth floorplan place cts route finish report clean

all: report

# Create directories
$(RESULTS_DIR) $(REPORTS_DIR) $(LOG_DIR):
	mkdir -p $@

# =============================================================================
# Synthesis (Yosys)
# =============================================================================

synth: $(RESULTS_DIR) $(LOG_DIR)
	@echo "=== Running Synthesis ==="
	yosys -c scripts/synth.tcl 2>&1 | tee $(LOG_DIR)/synth.log

# =============================================================================
# Floorplan (OpenROAD)
# =============================================================================

floorplan: synth $(RESULTS_DIR)
	@echo "=== Running Floorplan ==="
	openroad -no_init scripts/floorplan.tcl 2>&1 | tee $(LOG_DIR)/floorplan.log

# =============================================================================
# Placement (OpenROAD)
# =============================================================================

place: floorplan
	@echo "=== Running Placement ==="
	openroad -no_init scripts/place.tcl 2>&1 | tee $(LOG_DIR)/place.log

# =============================================================================
# Clock Tree Synthesis (OpenROAD)
# =============================================================================

cts: place
	@echo "=== Running CTS ==="
	openroad -no_init scripts/cts.tcl 2>&1 | tee $(LOG_DIR)/cts.log

# =============================================================================
# Routing (OpenROAD)
# =============================================================================

route: cts
	@echo "=== Running Routing ==="
	openroad -no_init scripts/route.tcl 2>&1 | tee $(LOG_DIR)/route.log

# =============================================================================
# Final (OpenROAD)
# =============================================================================

finish: route
	@echo "=== Running Final ==="
	openroad -no_init scripts/finish.tcl 2>&1 | tee $(LOG_DIR)/finish.log

# =============================================================================
# Reports
# =============================================================================

report: finish $(REPORTS_DIR)
	@echo "=== Generating Reports ==="
	openroad -no_init scripts/report.tcl 2>&1 | tee $(LOG_DIR)/report.log
	@echo ""
	@echo "=============================================="
	@echo "Reports generated in $(REPORTS_DIR)/"
	@echo "=============================================="
	@cat $(REPORTS_DIR)/area.rpt
	@cat $(REPORTS_DIR)/power.rpt

# Quick synthesis-only report (faster)
synth_report: synth $(REPORTS_DIR)
	@echo "=== Quick Synthesis Report ==="
	yosys -c scripts/synth_stats.tcl 2>&1 | tee $(REPORTS_DIR)/synth_stats.txt

# =============================================================================
# Clean
# =============================================================================

clean:
	rm -rf $(RESULTS_DIR) $(REPORTS_DIR) $(LOG_DIR)
	rm -f *.log *.rpt

# =============================================================================
# Help
# =============================================================================

help:
	@echo "HAI Processor OpenROAD Flow"
	@echo ""
	@echo "Targets:"
	@echo "  synth        - Run Yosys synthesis"
	@echo "  floorplan    - Create floorplan"
	@echo "  place        - Run placement"
	@echo "  cts          - Clock tree synthesis"
	@echo "  route        - Global and detailed routing"
	@echo "  finish       - Final optimization"
	@echo "  report       - Generate area/power reports"
	@echo "  synth_report - Quick synthesis statistics"
	@echo "  clean        - Remove generated files"
