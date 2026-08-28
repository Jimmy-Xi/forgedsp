TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(abspath ../../../rtl/axis_complex_fir.sv)
TOPLEVEL = axis_complex_fir
MODULE = test_fir
COMPILE_ARGS += -g2012
export PYTHONPATH := $(abspath ../../../src):$(PYTHONPATH)
PYTHON_BIN ?= python3
COCOTB_CONFIG := $(shell $(PYTHON_BIN) -c "import os, sys; print(os.path.join(os.path.dirname(sys.executable), 'cocotb-config'))")
COCOTB_MAKEFILES := $(shell $(COCOTB_CONFIG) --makefiles)

include $(COCOTB_MAKEFILES)/Makefile.sim
