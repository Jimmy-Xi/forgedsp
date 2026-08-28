import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

from forgedsp_model import cordic_vector


async def reset(dut):
    dut.rst_n.value = 0
    dut.s_axis_valid.value = 0
    dut.m_axis_ready.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1


@cocotb.test()
async def all_quadrants_match_bit_exact_model(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    dut.m_axis_ready.value = 1
    vectors = [(1000, 500), (-1000, 500), (-1000, -500), (1000, -500), (300, 1200)]
    for real, imag in vectors:
        expected_magnitude, expected_phase = cordic_vector(real, imag)
        while not int(dut.s_axis_ready.value):
            await RisingEdge(dut.clk)
        dut.s_axis_valid.value = 1
        dut.s_axis_i.value = real
        dut.s_axis_q.value = imag
        await RisingEdge(dut.clk)
        dut.s_axis_valid.value = 0
        while not int(dut.m_axis_valid.value):
            await RisingEdge(dut.clk)
        await Timer(1, units="ns")
        assert int(dut.m_axis_magnitude.value) == expected_magnitude
        assert dut.m_axis_phase.value.signed_integer == expected_phase
        await RisingEdge(dut.clk)

