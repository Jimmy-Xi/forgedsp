# Verification strategy

## Bit-exact scoreboards

The Python models duplicate arithmetic rules, not RTL source structure. Cocotb sends integer samples into the RTL and compares every accepted output to the reference sequence. FFT tests additionally check output index and final-bin marker.

## Backpressure

Mixer and FFT tests randomize `m_ready`. The source advances only when `s_ready` is high. This detects the common class of bugs where internal phase, sample history or frame index advances during a downstream stall.

## Formal proof

`axis_skid_buffer.sby` treats input valid/data and output ready as arbitrary. At a bounded proof depth it asserts:

- readiness is equivalent to having free space or simultaneously draining the stored item;
- once output is valid and stalled, valid remains asserted;
- stalled output data is stable.

The RTL blocks contain the same local stalled-output assertions under the `FORMAL` define. The skid buffer is the first full proof target; deeper end-to-end conservation proofs are a roadmap item.

## Synthesis

CI synthesizes every module independently with Yosys. This catches non-synthesizable constructs and produces generic cell statistics. Generic synthesis is not a substitute for vendor place-and-route: no Fmax, power, LUT or DSP-slice claim is made in v0.1.

## Coverage boundary

Current tests cover default parameters. Parameter sweeps, coefficient changes under load, two's-complement minimum negation policy and multi-frame continuous FFT traffic should be expanded before production reuse.

