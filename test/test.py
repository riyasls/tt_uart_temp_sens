# -----------------------------------------------------------------------------
# @   Copyright (c) 2025, System Level Solutions (India) Pvt. Ltd.
# @                     All rights reserved.
#
# -----------------------------------------------------------------------------
# - F I L E  D E T A I L S ----------------------------------------------------
# Description  : Cocotb testbench for tt_um_pwm_to_uart_tx_wrapper.
#                This module converts the PWM digital serial signal
#                into a parallel value and transmits it over UART TX
#                using a 115200 baud rate.
# -----------------------------------------------------------------------------

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def pwm_to_uart_tx_test(dut):
    """Testbench equivalent tt_um_uart_temp_sens"""

    # Create 50 MHz clock (period = 20 ns)
    cocotb.start_soon(Clock(dut.clk, 20, units="ns").start())

    # Initialize signals
    dut.reset_n.value = 0
    dut.pwm_in_data_i.value = 0
    dut._log.info("Resetting DUT...")

    # Wait for a few clock cycles
    for _ in range(5):
        await RisingEdge(dut.clk)

    # Release reset
    dut.reset_n.value = 1
    dut._log.info("Released reset.")

    # Drive PWM input
    await RisingEdge(dut.clk)
    dut.pwm_in_data_i.value = 1

    # Wait for a few more cycles
    for _ in range(5):
        await RisingEdge(dut.clk)

    # Main loop (equivalent to 'for (i = 0; i < 1000; i++)')
    for i in range(1000):

        # Random number of low cycles (equivalent to 'no_of_clks = $random')
        no_of_clks = random.randint(0, 2047)  # 11-bit like in Verilog
        dut._log.debug(f"Iteration {i}, Low period = {no_of_clks} cycles")

        # Keep PWM low for 'no_of_clks' cycles
        for _ in range(no_of_clks):
            dut.pwm_in_data_i.value = 0
            await RisingEdge(dut.clk)

        # Make PWM high for 25 cycles
        dut.pwm_in_data_i.value = 1
        for _ in range(25):
            await RisingEdge(dut.clk)

    # Simulation end delay
    await Timer(100_000, units="ns")
    dut._log.info("Simulation complete.")
