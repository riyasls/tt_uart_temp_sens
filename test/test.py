# -----------------------------------------------------------------------------
# @   Copyright (c) 2025, System Level Solutions (India) Pvt. Ltd.
# @                     All rights reserved.
#
# -----------------------------------------------------------------------------
# - F I L E  D E T A I L S ----------------------------------------------------
# Description  : Cocotb testbench equivalent of the Verilog tb.v
#                This testbench drives the UART temperature sensor design
#                (tt_um_uart_temp_sens) with a simulated PWM input signal.
#                The module measures PWM low periods and transmits the result
#                via UART TX at 115200 baud, using a 50 MHz clock.
# -----------------------------------------------------------------------------

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def tb_test(dut):
    """Cocotb testbench equivalent of Verilog tb module."""

    # -------------------------------------------------------------------------
    # Initialize signals
    # -------------------------------------------------------------------------
    dut._log.info("Initializing testbench signals...")

    # Set all input signals to default values
    dut.clk.value = 0
    dut.rst_n.value = 0
    dut.ena.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Optional power pins (ignored in RTL sim)
    if hasattr(dut, "VPWR"):
        dut.VPWR.value = 1
    if hasattr(dut, "VGND"):
        dut.VGND.value = 0

    # -------------------------------------------------------------------------
    # Start clock: 50 MHz -> 20 ns period
    # -------------------------------------------------------------------------
    cocotb.start_soon(Clock(dut.clk, 20, units="ns").start())
    dut._log.info("50 MHz clock started.")

    # -------------------------------------------------------------------------
    # Reset sequence
    # -------------------------------------------------------------------------
    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    dut._log.info("Reset released.")

    # Enable design after reset
    dut.ena.value = 1
    await RisingEdge(dut.clk)

    # -------------------------------------------------------------------------
    # PWM Input simulation
    # -------------------------------------------------------------------------
    # We'll assume pwm_in_data_i is mapped to one of the input pins
    # For example: ui_in[0] = pwm input
    # Modify this line if your DUT connects it differently.
    pwm_bit_index = 0

    # Make PWM high initially
    dut.ui_in.value = dut.ui_in.value | (1 << pwm_bit_index)

    # Wait a few cycles before starting
    for _ in range(5):
        await RisingEdge(dut.clk)

    # Main loop (equivalent to Verilog for(i = 0; i < 1000; i++))
    for i in range(1000):
        no_of_clks = random.randint(0, 2047)  # Equivalent to $random & 0x7FF
        dut._log.debug(f"[{i}] PWM LOW for {no_of_clks} cycles")

        # Drive PWM low for 'no_of_clks' cycles
        for _ in range(no_of_clks):
            dut.ui_in.value = dut.ui_in.value & ~(1 << pwm_bit_index)  # set bit low
            await RisingEdge(dut.clk)

        # Drive PWM high for 25 cycles
        dut.ui_in.value = dut.ui_in.value | (1 << pwm_bit_index)
        for _ in range(25):
            await RisingEdge(dut.clk)

    # -------------------------------------------------------------------------
    # End of simulation
    # -------------------------------------------------------------------------
    await Timer(1000, units="ns")
    dut._log.info("Simulation complete.")
