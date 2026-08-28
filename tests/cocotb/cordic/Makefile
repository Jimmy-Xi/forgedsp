TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(abspath ../../../rtl/cordic_vector.sv)
TOPLEVEL = cordic_vector
MODULE = test_cordic
COMPILE_ARGS += -g2012
export PYTHONPATH := $(abspath ../../../src):$(PYTHONPATH)
PYTHON_BIN ?= python3
COCOTB_MAKEFILES := $(shell $(PYTHON_BIN) -c "import cocotb, pathlib; print(pathlib.Path(cocotb.__file__).parent / 'share' / 'makefiles')")

include $(COCOTB_MAKEFILES)/Makefile.sim
