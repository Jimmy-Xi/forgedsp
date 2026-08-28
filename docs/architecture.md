# Architecture and arithmetic

## Stream contract

Every data-plane block uses the same transfer rule:

```text
transfer = valid && ready
```

A producer must hold `valid` and payload stable until the consumer raises `ready`. Single-output-register blocks derive input readiness as `!m_valid || m_ready`, allowing one transfer per cycle when unstalled and preventing overwrite under backpressure.

## Quarter-rate mixer

The mixer implements `x[n] × exp(-jπn/2)` with the sequence `1, -j, -1, +j`. This maps to swaps and two's-complement negations instead of multipliers. Phase advances only on an accepted input transfer, so stalls cannot desynchronize the oscillator from sample order.

## Complex FIR

The FIR applies real Q1.15 coefficients to both I and Q channels. The current input is tap zero; registered history supplies the remaining taps. Products accumulate in a widened signed word, then arithmetic-shift by the coefficient fraction and saturate to the output width.

Coefficient writes are independent of the sample stream. System integration must avoid changing coefficients in the middle of an incident unless that behavior is intentional; a future AXI-Lite frontend will provide commit/shadow semantics.

## FFT8

Eight natural-order samples are written into bit-reversed memory locations. The engine performs four butterflies per stage over three Radix-2 stages:

```text
stage 0: distance 1, W0
stage 1: distance 2, W0/W2
stage 2: distance 4, W0/W1/W2/W3
```

Q1.15 twiddles approximate the irrational rotations. Three internal growth bits retain an unscaled transform. After 12 butterfly cycles, bins stream in natural order with an index and `last` marker.

## CORDIC

Vectoring mode rotates `(x,y)` toward the positive x-axis and accumulates angle. Negative-x inputs are reflected and initialized near `+π` or `-π` to preserve quadrant. Sixteen arctangent constants use the signed phase representation. The final x value is multiplied by inverse CORDIC gain in Q1.15.

## Composition boundary

The blocks intentionally expose different service patterns: mixer and FIR are sample-streaming, FFT is framed/bursty, and CORDIC accepts one vector per 16-cycle iteration. A production top-level therefore needs explicit FIFOs and latency/burst sizing. Hiding this mismatch behind direct wiring would make backpressure failures harder to observe.

