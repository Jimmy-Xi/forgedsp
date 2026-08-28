"""Integer models matching the SystemVerilog arithmetic and ordering."""

from __future__ import annotations

import math

import numpy as np
from numpy.typing import ArrayLike, NDArray


def saturate(value: int, width: int) -> int:
    minimum = -(1 << (width - 1))
    maximum = (1 << (width - 1)) - 1
    return min(max(int(value), minimum), maximum)


def quarter_rate_mix(
    real: ArrayLike,
    imag: ArrayLike,
) -> tuple[NDArray[np.int64], NDArray[np.int64]]:
    i_values = np.asarray(real, dtype=np.int64).reshape(-1)
    q_values = np.asarray(imag, dtype=np.int64).reshape(-1)
    if i_values.size != q_values.size:
        raise ValueError("real and imag must have the same length")
    out_i = np.empty_like(i_values)
    out_q = np.empty_like(q_values)
    for index, (i_value, q_value) in enumerate(zip(i_values, q_values)):
        phase = index & 3
        if phase == 0:
            out_i[index], out_q[index] = i_value, q_value
        elif phase == 1:
            out_i[index], out_q[index] = q_value, -i_value
        elif phase == 2:
            out_i[index], out_q[index] = -i_value, -q_value
        else:
            out_i[index], out_q[index] = -q_value, i_value
    return out_i, out_q


def fir_complex(
    real: ArrayLike,
    imag: ArrayLike,
    coefficients: ArrayLike,
    *,
    data_width: int = 16,
    coefficient_fraction: int = 15,
) -> tuple[NDArray[np.int64], NDArray[np.int64]]:
    i_values = np.asarray(real, dtype=np.int64).reshape(-1)
    q_values = np.asarray(imag, dtype=np.int64).reshape(-1)
    coeffs = np.asarray(coefficients, dtype=np.int64).reshape(-1)
    if i_values.size != q_values.size:
        raise ValueError("real and imag must have the same length")
    if coeffs.size < 1:
        raise ValueError("at least one FIR coefficient is required")
    delay_i = [0] * (coeffs.size - 1)
    delay_q = [0] * (coeffs.size - 1)
    output_i: list[int] = []
    output_q: list[int] = []
    for sample_i, sample_q in zip(i_values, q_values):
        taps_i = [int(sample_i), *delay_i]
        taps_q = [int(sample_q), *delay_q]
        accumulator_i = sum(value * int(coeff) for value, coeff in zip(taps_i, coeffs))
        accumulator_q = sum(value * int(coeff) for value, coeff in zip(taps_q, coeffs))
        output_i.append(saturate(accumulator_i >> coefficient_fraction, data_width))
        output_q.append(saturate(accumulator_q >> coefficient_fraction, data_width))
        if delay_i:
            delay_i = [int(sample_i), *delay_i[:-1]]
            delay_q = [int(sample_q), *delay_q[:-1]]
    return np.asarray(output_i, dtype=np.int64), np.asarray(output_q, dtype=np.int64)


_FFT_TWIDDLES_Q15 = (
    (32767, 0),
    (23170, -23170),
    (0, -32768),
    (-23170, -23170),
)


def _bit_reverse_3(value: int) -> int:
    return ((value & 1) << 2) | (value & 2) | ((value & 4) >> 2)


def _complex_multiply_q15(real: int, imag: int, twiddle_index: int) -> tuple[int, int]:
    twiddle_real, twiddle_imag = _FFT_TWIDDLES_Q15[twiddle_index]
    return (
        (real * twiddle_real - imag * twiddle_imag) >> 15,
        (real * twiddle_imag + imag * twiddle_real) >> 15,
    )


def fft8_fixed(real: ArrayLike, imag: ArrayLike) -> tuple[NDArray[np.int64], NDArray[np.int64]]:
    input_i = np.asarray(real, dtype=np.int64).reshape(-1)
    input_q = np.asarray(imag, dtype=np.int64).reshape(-1)
    if input_i.size != 8 or input_q.size != 8:
        raise ValueError("fft8_fixed requires exactly eight complex samples")
    memory_i = [0] * 8
    memory_q = [0] * 8
    for index in range(8):
        destination = _bit_reverse_3(index)
        memory_i[destination] = int(input_i[index])
        memory_q[destination] = int(input_q[index])

    stages = (
        ((0, 1, 0), (2, 3, 0), (4, 5, 0), (6, 7, 0)),
        ((0, 2, 0), (1, 3, 2), (4, 6, 0), (5, 7, 2)),
        ((0, 4, 0), (1, 5, 1), (2, 6, 2), (3, 7, 3)),
    )
    for butterflies in stages:
        for first, second, twiddle in butterflies:
            a_i, a_q = memory_i[first], memory_q[first]
            product_i, product_q = _complex_multiply_q15(memory_i[second], memory_q[second], twiddle)
            memory_i[first], memory_q[first] = a_i + product_i, a_q + product_q
            memory_i[second], memory_q[second] = a_i - product_i, a_q - product_q
    return np.asarray(memory_i, dtype=np.int64), np.asarray(memory_q, dtype=np.int64)


def cordic_vector(
    real: int,
    imag: int,
    *,
    iterations: int = 16,
    phase_width: int = 16,
) -> tuple[int, int]:
    if not 1 <= iterations <= 20:
        raise ValueError("iterations must be between 1 and 20")
    phase_scale = 1 << (phase_width - 1)
    atan_table = [round(math.atan(2.0**-index) / math.pi * phase_scale) for index in range(iterations)]
    x_value, y_value = int(real), int(imag)
    phase = 0
    if x_value < 0:
        phase = phase_scale - 1 if y_value >= 0 else -phase_scale
        x_value, y_value = -x_value, -y_value
    for index, angle in enumerate(atan_table):
        old_x = x_value
        if y_value >= 0:
            x_value = x_value + (y_value >> index)
            y_value = y_value - (old_x >> index)
            phase += angle
        else:
            x_value = x_value - (y_value >> index)
            y_value = y_value + (old_x >> index)
            phase -= angle
    magnitude = (x_value * 19898) >> 15
    phase = saturate(phase, phase_width)
    return magnitude, phase

