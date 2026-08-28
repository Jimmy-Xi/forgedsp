PYTHON ?= python3
SIM ?= icarus

.PHONY: test wordlength rtl formal synth clean

test:
	$(PYTHON) -m unittest discover -s tests/python -v

wordlength:
	$(PYTHON) -m forgedsp_model.wordlength --max-evm 0.01 --top 5

rtl:
	$(MAKE) -C tests/cocotb/mixer SIM=$(SIM)
	$(MAKE) -C tests/cocotb/fir SIM=$(SIM)
	$(MAKE) -C tests/cocotb/fft SIM=$(SIM)
	$(MAKE) -C tests/cocotb/cordic SIM=$(SIM)

formal:
	sby -f formal/axis_skid_buffer.sby

synth:
	scripts/synth_all.sh

clean:
	$(RM) -r build formal/axis_skid_buffer tests/cocotb/*/sim_build

