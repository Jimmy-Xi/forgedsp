"""Bit-exact reference models for ForgeDSP RTL blocks."""

from .fixed import cordic_vector, fft8_fixed, fir_complex, quarter_rate_mix, saturate


def search_wordlengths(*args, **kwargs):
    from .wordlength import search_wordlengths as _search_wordlengths

    return _search_wordlengths(*args, **kwargs)

__all__ = [
    "cordic_vector",
    "fft8_fixed",
    "fir_complex",
    "quarter_rate_mix",
    "saturate",
    "search_wordlengths",
]

__version__ = "0.1.0"
