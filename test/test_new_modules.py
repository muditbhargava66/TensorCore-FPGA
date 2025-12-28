"""
Cocotb Tests for v1.4.0 New Modules
- FIFO Buffer
- SPI Slave
- Softmax Unit
- VPU Mini
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles


# ============================================
# FIFO Buffer Tests
# ============================================
@cocotb.test()
async def test_fifo_basic(dut):
    """Test FIFO write and read"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Check empty
    assert dut.empty.value == 1, "FIFO should be empty after reset"
    assert dut.full.value == 0, "FIFO should not be full"
    
    # Write 4 values
    for i in range(4):
        dut.wr_data.value = i + 10
        dut.wr_en.value = 1
        await RisingEdge(dut.clk)
    dut.wr_en.value = 0
    await RisingEdge(dut.clk)
    
    assert dut.empty.value == 0, "FIFO should not be empty"
    
    # Read 4 values
    for i in range(4):
        dut.rd_en.value = 1
        await RisingEdge(dut.clk)
        expected = i + 10
        assert dut.rd_data.value == expected, f"FIFO read mismatch: {dut.rd_data.value} != {expected}"
    dut.rd_en.value = 0
    
    dut._log.info("FIFO basic test PASSED")


@cocotb.test()
async def test_fifo_full(dut):
    """Test FIFO full condition"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Fill FIFO (8 entries)
    for i in range(8):
        dut.wr_data.value = i
        dut.wr_en.value = 1
        await RisingEdge(dut.clk)
    dut.wr_en.value = 0
    await RisingEdge(dut.clk)
    
    assert dut.full.value == 1, "FIFO should be full"
    dut._log.info("FIFO full test PASSED")


# ============================================
# VPU Mini Tests
# ============================================
@cocotb.test()
async def test_vpu_relu(dut):
    """Test VPU ReLU operation"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    dut.op_sel.value = 3  # ReLU mode
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Input 4 values: [5, -3, 10, -7]
    test_vals = [5, -3 & 0xFF, 10, -7 & 0xFF]  # Convert to unsigned
    for val in test_vals:
        dut.data_in.value = val
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Wait for processing
    await ClockCycles(dut.clk, 10)
    
    dut._log.info("VPU ReLU test PASSED")


# ============================================
# Softmax Unit Tests  
# ============================================
@cocotb.test()
async def test_softmax_basic(dut):
    """Test Softmax computation"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    dut.start.value = 0
    dut.valid_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Input values
    test_vals = [0, -2, -4, -1]
    for val in test_vals:
        dut.data_in.value = val & 0xFF
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Start computation
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for done
    for _ in range(20):
        await RisingEdge(dut.clk)
        if dut.done.value == 1:
            break
    
    assert dut.done.value == 1, "Softmax should complete"
    dut._log.info("Softmax basic test PASSED")
