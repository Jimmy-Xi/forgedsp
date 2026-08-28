#!/usr/bin/env bash
set -euo pipefail

mkdir -p build/synthesis

declare -A tops=(
  [axis_skid_buffer]=rtl/axis_skid_buffer.sv
  [axis_quarter_rate_mixer]=rtl/axis_quarter_rate_mixer.sv
  [axis_complex_fir]=rtl/axis_complex_fir.sv
  [fft8_stream]=rtl/fft8_stream.sv
  [cordic_vector]=rtl/cordic_vector.sv
)

for top in "${!tops[@]}"; do
  yosys -p "read_verilog -sv ${tops[$top]}; synth -top $top; stat" \
    | tee "build/synthesis/${top}.log"
done

