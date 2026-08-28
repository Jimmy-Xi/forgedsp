import math
import unittest

import numpy as np

from forgedsp_model import (
    cordic_vector,
    fft8_fixed,
    fir_complex,
    quarter_rate_mix,
    saturate,
)


class FixedModelTests(unittest.TestCase):
    def test_saturate(self) -> None:
        self.assertEqual(saturate(1000, 8), 127)
        self.assertEqual(saturate(-1000, 8), -128)
        self.assertEqual(saturate(42, 8), 42)

    def test_quarter_rate_mixer(self) -> None:
        real, imag = quarter_rate_mix([10] * 4, [2] * 4)
        np.testing.assert_array_equal(real, [10, 2, -10, -2])
        np.testing.assert_array_equal(imag, [2, -10, -2, 10])

    def test_complex_fir_impulse(self) -> None:
        coefficients = [16384, 8192, 8192, 0]
        real, imag = fir_complex([1000, 0, 0, 0], [500, 0, 0, 0], coefficients)
        np.testing.assert_array_equal(real, [500, 250, 250, 0])
        np.testing.assert_array_equal(imag, [250, 125, 125, 0])

    def test_fft_matches_numpy_with_quantized_twiddles(self) -> None:
        real = np.array([100, -50, 25, 0, -30, 10, 60, -20])
        imag = np.array([0, 5, -10, 15, 20, -25, 30, -35])
        actual_i, actual_q = fft8_fixed(real, imag)
        expected = np.fft.fft(real + 1j * imag)
        np.testing.assert_allclose(actual_i + 1j * actual_q, expected, atol=5.0)

    def test_cordic_all_quadrants(self) -> None:
        for real, imag in ((1000, 500), (-1000, 500), (-1000, -500), (1000, -500)):
            with self.subTest(real=real, imag=imag):
                magnitude, phase = cordic_vector(real, imag)
                expected_phase = math.atan2(imag, real) / math.pi * 32768
                self.assertAlmostEqual(magnitude, math.hypot(real, imag), delta=5)
                self.assertAlmostEqual(phase, expected_phase, delta=12)


if __name__ == "__main__":
    unittest.main()
