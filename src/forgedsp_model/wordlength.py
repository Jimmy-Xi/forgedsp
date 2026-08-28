"""Search fixed-point FIR widths under an EVM constraint."""

from __future__ import annotations

import argparse
import json

import numpy as np

from .fixed import fir_complex


def _reference_signal(count: int = 4096) -> np.ndarray:
    time = np.arange(count)
    return (
        0.48 * np.exp(2j * np.pi * 0.031 * time)
        + 0.27 * np.exp(2j * np.pi * 0.087 * time + 0.4j)
        + 0.08 * np.exp(2j * np.pi * 0.19 * time - 0.8j)
    )


def search_wordlengths(
    *,
    max_evm: float = 0.01,
    widths: range = range(8, 19, 2),
    taps: int = 8,
) -> list[dict[str, float | int | bool]]:
    if max_evm <= 0 or taps < 2:
        raise ValueError("max_evm and taps must be positive")
    signal = _reference_signal()
    coefficients = np.hamming(taps)
    coefficients /= coefficients.sum()
    reference = np.convolve(signal, coefficients)[: signal.size]
    results: list[dict[str, float | int | bool]] = []

    for data_width in widths:
        for coefficient_width in widths:
            data_fraction = data_width - 2
            coefficient_fraction = coefficient_width - 1
            data_scale = 1 << data_fraction
            coefficient_scale = 1 << coefficient_fraction
            maximum_data = (1 << (data_width - 1)) - 1
            quantized_i = np.clip(np.round(signal.real * data_scale), -maximum_data - 1, maximum_data).astype(int)
            quantized_q = np.clip(np.round(signal.imag * data_scale), -maximum_data - 1, maximum_data).astype(int)
            quantized_coefficients = np.clip(
                np.round(coefficients * coefficient_scale),
                -(1 << (coefficient_width - 1)),
                (1 << (coefficient_width - 1)) - 1,
            ).astype(int)
            output_i, output_q = fir_complex(
                quantized_i,
                quantized_q,
                quantized_coefficients,
                data_width=data_width,
                coefficient_fraction=coefficient_fraction,
            )
            output = (output_i + 1j * output_q) / data_scale
            evm = float(np.sqrt(np.mean(np.abs(output - reference) ** 2) / np.mean(np.abs(reference) ** 2)))
            accumulator_width = data_width + coefficient_width + int(np.ceil(np.log2(taps)))
            cost = taps * data_width * coefficient_width + taps * accumulator_width
            results.append({
                "data_width": data_width,
                "coefficient_width": coefficient_width,
                "accumulator_width": accumulator_width,
                "evm_rms": evm,
                "cost_proxy": cost,
                "meets_constraint": evm <= max_evm,
            })
    return sorted(results, key=lambda row: (not row["meets_constraint"], row["cost_proxy"], row["evm_rms"]))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Search ForgeDSP FIR fixed-point widths")
    parser.add_argument("--max-evm", type=float, default=0.01)
    parser.add_argument("--top", type=int, default=10)
    parser.add_argument("--output")
    args = parser.parse_args(argv)
    results = search_wordlengths(max_evm=args.max_evm)
    report = {
        "max_evm": args.max_evm,
        "feasible_configurations": sum(bool(row["meets_constraint"]) for row in results),
        "best": next((row for row in results if row["meets_constraint"]), None),
        "top": results[: args.top],
    }
    serialized = json.dumps(report, indent=2, sort_keys=True)
    if args.output:
        with open(args.output, "w", encoding="utf-8", newline="\n") as stream:
            stream.write(serialized + "\n")
    print(serialized)
    return 0 if report["best"] is not None else 1


if __name__ == "__main__":
    raise SystemExit(main())

