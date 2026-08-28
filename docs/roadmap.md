# Roadmap

## v0.2 — Control and composition

- AXI-Lite register bank with shadow coefficients and atomic commit.
- Reusable multi-entry AXI-Stream FIFO with occupancy telemetry.
- A top-level DDC → FIR → FFT → CORDIC pipeline with explicit rate matching.
- Machine-readable latency and frame-size metadata.

## v0.3 — Arithmetic exploration

- Selectable truncate, round-to-nearest-even and stochastic rounding.
- Overflow counters and saturation event stream.
- Parameter sweeps that generate Pareto fronts for EVM, cell count and latency.
- Formal equivalence between selected Python-generated constants and RTL parameters.

## v0.4 — Scalable transforms

- Parameterized 16/64/256-point streaming FFT with RAM inference.
- Windowing and overlap support.
- Configurable CORDIC iteration/precision pipeline.
- Continuous multi-frame randomized verification.

## v1.0 — Hardware and software integration

- Open-source place-and-route on a named FPGA target.
- Verifiable Fmax, LUT, register, block-RAM and DSP-slice reports.
- Linux UIO or kernel driver integration with PulseForge.
- Bit-exact acceleration of selected WavePilot OFDM receiver blocks.

