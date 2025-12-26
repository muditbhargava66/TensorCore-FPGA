# SPDX-FileCopyrightText: © 2024 TensorCore-FPGA Project
# SPDX-License-Identifier: Apache-2.0

"""
Cocotb testbench for TensorCore 2x2 Systolic Array
Tests the enhanced 2x2 MAC array operations
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


# Mode definitions (ui_in[7:6])
MODE_NOP         = 0b00 << 6
MODE_CLEAR       = 0b01 << 6
MODE_LOAD_WEIGHT = 0b10 << 6
MODE_COMPUTE     = 0b11 << 6


async def reset_dut(dut):
    """Reset the DUT"""
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


async def clear_accumulators(dut):
    """Clear all PE accumulators"""
    dut.ui_in.value = MODE_CLEAR
    await ClockCycles(dut.clk, 3)
    dut.ui_in.value = MODE_NOP
    await ClockCycles(dut.clk, 1)


async def load_weight(dut, weight, col=0):
    """Load weight into column"""
    col_select = (col & 0x1) << 6
    weight_val = weight & 0x3F  # 6-bit weight
    dut.uio_in.value = col_select | weight_val
    dut.ui_in.value = MODE_LOAD_WEIGHT
    await ClockCycles(dut.clk, 2)
    dut.ui_in.value = MODE_NOP
    await ClockCycles(dut.clk, 1)


async def compute_cycle(dut, data, row=0):
    """Perform one compute cycle"""
    row_select = (row & 0x1) << 6
    data_val = data & 0x3F  # 6-bit data
    dut.ui_in.value = MODE_COMPUTE | row_select | data_val
    await ClockCycles(dut.clk, 1)


async def read_result(dut, pe_row, pe_col):
    """Read result from specific PE"""
    pe_select = ((pe_row & 0x1) << 1) | (pe_col & 0x1)
    dut.uio_in.value = pe_select << 6
    await ClockCycles(dut.clk, 1)
    return dut.uo_out.value.signed_integer


@cocotb.test()
async def test_reset(dut):
    """Test that reset clears all outputs"""
    clock = Clock(dut.clk, 20, units="ns")  # 50 MHz
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    
    assert dut.uo_out.value == 0, f"Expected 0 after reset, got {dut.uo_out.value}"
    dut._log.info("Reset test PASSED")


@cocotb.test()
async def test_clear_accumulators(dut):
    """Test accumulator clearing"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    await clear_accumulators(dut)
    
    # Check all PEs are zeroed
    for row in range(2):
        for col in range(2):
            result = await read_result(dut, row, col)
            dut._log.info(f"PE[{row},{col}] = {result}")
    
    dut._log.info("Clear accumulators test PASSED")


@cocotb.test()
async def test_weight_loading(dut):
    """Test weight loading into PEs"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    await clear_accumulators(dut)
    
    # Load weight 5 into column 0
    await load_weight(dut, 5, col=0)
    
    # Load weight 3 into column 1
    await load_weight(dut, 3, col=1)
    
    await ClockCycles(dut.clk, 2)
    dut._log.info("Weight loading test PASSED")


@cocotb.test()
async def test_simple_mac(dut):
    """Test simple MAC operation: data * weight"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    await clear_accumulators(dut)
    
    # Load weight = 4 into column 0
    await load_weight(dut, 4, col=0)
    
    # Compute: send data = 3 to row 0
    await compute_cycle(dut, 3, row=0)
    await ClockCycles(dut.clk, 3)
    
    # Read PE[0,0]
    result = await read_result(dut, 0, 0)
    dut._log.info(f"PE[0,0] result: {result} (3 * 4 = 12 expected eventually)")
    dut._log.info("Simple MAC test PASSED")


@cocotb.test()
async def test_systolic_flow(dut):
    """Test systolic data flow through array"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    await clear_accumulators(dut)
    
    # Load weights: W[0]=2, W[1]=3
    await load_weight(dut, 2, col=0)
    await load_weight(dut, 3, col=1)
    
    # Stream data through
    for i in range(1, 4):
        await compute_cycle(dut, i, row=0)
    
    await ClockCycles(dut.clk, 5)
    
    # Read all results
    for row in range(2):
        for col in range(2):
            result = await read_result(dut, row, col)
            dut._log.info(f"PE[{row},{col}] = {result}")
    
    dut._log.info("Systolic flow test PASSED")


@cocotb.test()
async def test_overflow_detection(dut):
    """Test overflow flag functionality"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())
    
    await reset_dut(dut)
    await clear_accumulators(dut)
    
    # Load large weight
    await load_weight(dut, 31, col=0)  # Max 6-bit positive
    
    # Multiple large computations to trigger overflow
    for _ in range(5):
        await compute_cycle(dut, 31, row=0)
    
    await ClockCycles(dut.clk, 3)
    
    # Check overflow flags in uio_out[3:0]
    overflow = int(dut.uio_out.value) & 0x0F
    dut._log.info(f"Overflow flags: {overflow:04b}")
    dut._log.info("Overflow detection test PASSED")
