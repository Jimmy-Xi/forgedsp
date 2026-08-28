TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(abspath ../../../rtl/axis_quarter_rate_mixer.sv)
TOPLEVEL = axis_quarter_rate_mixer
MODULE = test_mixer
COMPILE_ARGS += -g2012
export PYTHONPATH := $(abspath ../../../src):$(PYTHONPATH)
PYTHON_BIN ?= python3
COCOTB_MAKEFILES := $(shell $(PYTHON_BIN) -c "import cocotb, pathlib; print(pathlib.Path(cocotb.__file__).parent / 'share' / 'makefiles')")

include $(COCOTB_MAKEFILES)/Makefile.sim
