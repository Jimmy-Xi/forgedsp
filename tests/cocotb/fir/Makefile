TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(abspath ../../../rtl/axis_complex_fir.sv)
TOPLEVEL = axis_complex_fir
MODULE = test_fir
COMPILE_ARGS += -g2012
export PYTHONPATH := $(abspath ../../../src):$(PYTHONPATH)
PYTHON_BIN ?= python3
COCOTB_MAKEFILES := $(shell $(PYTHON_BIN) -c "import cocotb, pathlib; print(pathlib.Path(cocotb.__file__).parent / 'share' / 'makefiles')")

include $(COCOTB_MAKEFILES)/Makefile.sim
