import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

@cocotb.test()
async def tb_test(dut):
    """Test for tt_um_uart_temp_sens module without warnings."""
    
    # Start a 50 MHz clock (period = 20 ns)
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

    # Initialize inputs
    dut.rst_n.value = 0
    dut.ena.value = 0
    #dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Reset
    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1

    # Toggle first bit after reset
    await RisingEdge(dut.clk)
    #dut.ui_in.value = 1

    for _ in range(5):
        await RisingEdge(dut.clk)

    # Main test loop (1000 iterations)
    for _ in range(100):
        no_of_clks_py = random.randint(0, 1023)  # match 11-bit register behavior

        for _ in range(no_of_clks_py):
            await RisingEdge(dut.clk)
            #dut.ui_in.value = 0

        await RisingEdge(dut.clk)
        #dut.ui_in.value = 1

        for _ in range(25):
            await RisingEdge(dut.clk)

        await RisingEdge(dut.clk)
        #dut.ui_in.value = 0

    # Wait a bit at the end
    await Timer(1000, unit="ns")
