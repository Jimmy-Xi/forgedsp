# Resume and interview material

## 中文项目名称

**ForgeDSP：可形式验证的FPGA流式定点信号处理加速器**

## 中文简历表述

- 使用SystemVerilog设计AXI-Stream风格定点DSP IP，完成无乘法器四相复数混频、运行时可配置复数FIR、8点三级Radix-2 FFT和16次迭代CORDIC幅相计算。
- 建立NumPy独立位精确模型与cocotb记分板，在随机`ready/valid`背压下验证相位、历史样本、FFT顺序、帧尾和饱和行为。
- 使用SVA与SymbiYosys证明弹性缓冲区在任意输入/背压下保持输出有效与数据稳定，并通过Verilator lint和Yosys综合检查所有RTL模块。
- 开发自动定点位宽搜索器，以RMS EVM为约束优化数据/系数/累加器位宽；在8抽头参考实验中找到10位数据、8位系数、21位累加器的最低成本1% EVM配置。

## English resume bullets

- Designed AXI-Stream-style fixed-point DSP IP in SystemVerilog: multiplier-free complex mixing, runtime-programmable complex FIR, iterative 8-point Radix-2 FFT and 16-iteration vectoring CORDIC.
- Built independent NumPy bit-exact models and cocotb scoreboards with randomized ready/valid backpressure, checking phase, FIR history, natural-order FFT framing and saturation.
- Added SVA/SymbiYosys proofs for elastic-buffer stall stability plus Verilator lint and Yosys synthesis in CI.
- Implemented an automated word-length explorer that minimizes a transparent hardware-cost proxy under an RMS-EVM constraint; selected a 10/8/21-bit FIR configuration for the 1% reference target.

## Do not overclaim

Generic Yosys cell statistics are not FPGA utilization. Until a named device completes place-and-route, do not list Fmax, power, LUT, DSP slice or BRAM numbers.

## Interview prompts

1. Why must NCO phase advance on an accepted transfer rather than every clock?
2. How does a stalled `valid/ready` interface preserve payload identity?
3. Why does an unscaled eight-point FFT need three growth bits?
4. Why does natural-order input require bit-reversed storage for this DIT schedule?
5. How do truncation and saturation affect EVM and spurious tones?
6. What does the formal proof establish, and what data-conservation property is still missing?
7. Why are generic synthesis counts not equivalent to FPGA LUT/DSP utilization?
8. Where would FIFOs be placed when composing streaming FIR, burst FFT and iterative CORDIC?

