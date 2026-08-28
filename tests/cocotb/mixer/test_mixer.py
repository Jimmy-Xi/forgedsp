import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

from forgedsp_model import quarter_rate_mix


async def reset(dut):
    dut.rst_n.value = 0
    dut.s_axis_valid.value = 0
    dut.m_axis_ready.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1


@cocotb.test()
async def randomized_backpressure_matches_model(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    rng = random.Random(7)
    samples_i = [rng.randint(-20000, 20000) for _ in range(40)]
    samples_q = [rng.randint(-20000, 20000) for _ in range(40)]
    expected_i, expected_q = quarter_rate_mix(samples_i, samples_q)

    sent = 0
    received = []
    dut.s_axis_valid.value = 0
    while len(received) < len(samples_i):
        dut.m_axis_ready.value = rng.random() > 0.35
        if sent < len(samples_i) and int(dut.s_axis_ready.value):
            dut.s_axis_valid.value = 1
            dut.s_axis_i.value = samples_i[sent]
            dut.s_axis_q.value = samples_q[sent]
            sent += 1
        else:
            dut.s_axis_valid.value = 0
        await RisingEdge(dut.clk)
        await Timer(1, units="ns")
        if int(dut.m_axis_valid.value) and int(dut.m_axis_ready.value):
            received.append((dut.m_axis_i.value.signed_integer, dut.m_axis_q.value.signed_integer))

    assert received == list(zip(expected_i.tolist(), expected_q.tolist()))

