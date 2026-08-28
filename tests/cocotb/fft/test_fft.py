import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

from forgedsp_model import fft8_fixed


async def reset(dut):
    dut.rst_n.value = 0
    dut.s_axis_valid.value = 0
    dut.m_axis_ready.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1


@cocotb.test()
async def radix2_frame_matches_bit_exact_model(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    samples_i = [100, -50, 25, 0, -30, 10, 60, -20]
    samples_q = [0, 5, -10, 15, 20, -25, 30, -35]
    expected_i, expected_q = fft8_fixed(samples_i, samples_q)

    dut.m_axis_ready.value = 0
    sent = 0
    while sent < len(samples_i):
        await FallingEdge(dut.clk)
        dut.s_axis_valid.value = 1
        dut.s_axis_i.value = samples_i[sent]
        dut.s_axis_q.value = samples_q[sent]
        await Timer(1, units="ns")
        input_transfer = int(dut.s_axis_ready.value)
        await RisingEdge(dut.clk)
        if input_transfer:
            sent += 1
    await FallingEdge(dut.clk)
    dut.s_axis_valid.value = 0

    rng = random.Random(9)
    received = []
    cycles = 0
    while len(received) < 8:
        cycles += 1
        assert cycles < 1000, "FFT frame did not complete"
        await FallingEdge(dut.clk)
        dut.m_axis_ready.value = rng.random() > 0.4
        await Timer(1, units="ns")
        output_transfer = int(dut.m_axis_valid.value) and int(dut.m_axis_ready.value)
        output_payload = (
                int(dut.m_axis_index.value),
                dut.m_axis_i.value.signed_integer,
                dut.m_axis_q.value.signed_integer,
                int(dut.m_axis_last.value),
        )
        await RisingEdge(dut.clk)
        if output_transfer:
            received.append(output_payload)

    assert [row[0] for row in received] == list(range(8))
    assert [row[1] for row in received] == expected_i.tolist()
    assert [row[2] for row in received] == expected_q.tolist()
    assert [row[3] for row in received] == [0] * 7 + [1]
