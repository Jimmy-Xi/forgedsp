import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

from forgedsp_model import fir_complex


async def reset(dut):
    dut.rst_n.value = 0
    dut.s_axis_valid.value = 0
    dut.m_axis_ready.value = 0
    dut.cfg_valid.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1


async def load_coefficients(dut, coefficients):
    for index, coefficient in enumerate(coefficients):
        dut.cfg_valid.value = 1
        dut.cfg_index.value = index
        dut.cfg_coefficient.value = coefficient
        await RisingEdge(dut.clk)
    dut.cfg_valid.value = 0


@cocotb.test()
async def impulse_response_matches_bit_exact_model(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    coefficients = [16384, 8192, 8192, 0]
    await load_coefficients(dut, coefficients)
    samples_i = [1000, 0, 0, 0, 30000, 30000, -30000, -30000]
    samples_q = [500, 0, 0, 0, -20000, 20000, 20000, -20000]
    expected_i, expected_q = fir_complex(samples_i, samples_q, coefficients)

    dut.m_axis_ready.value = 1
    received = []
    for sample_i, sample_q in zip(samples_i, samples_q):
        dut.s_axis_valid.value = 1
        dut.s_axis_i.value = sample_i
        dut.s_axis_q.value = sample_q
        await RisingEdge(dut.clk)
        await Timer(1, units="ns")
        if int(dut.m_axis_valid.value):
            received.append((dut.m_axis_i.value.signed_integer, dut.m_axis_q.value.signed_integer))
    dut.s_axis_valid.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")
    if int(dut.m_axis_valid.value):
        received.append((dut.m_axis_i.value.signed_integer, dut.m_axis_q.value.signed_integer))

    assert received == list(zip(expected_i.tolist(), expected_q.tolist()))

