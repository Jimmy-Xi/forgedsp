TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(abspath ../../../rtl/axis_quarter_rate_mixer.sv)
TOPLEVEL = axis_quarter_rate_mixer
MODULE = test_mixer
COMPILE_ARGS += -g2012
export PYTHONPATH := $(abspath ../../../src):$(PYTHONPATH)
COCOTB_MAKEFILES := $(shell python -c "import cocotb, os; print(os.path.join(os.path.dirname(cocotb.__file__), 'share', 'makefiles'))")

include $(COCOTB_MAKEFILES)/Makefile.sim
