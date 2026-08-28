// SPDX-License-Identifier: MIT
module axis_complex_fir #(
    parameter int DATA_W      = 16,
    parameter int COEFF_W     = 16,
    parameter int COEFF_FRAC  = 15,
    parameter int TAPS        = 4,
    parameter int ACC_W       = DATA_W + COEFF_W + $clog2(TAPS)
) (
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic                         s_axis_valid,
    output logic                         s_axis_ready,
    input  logic signed [DATA_W-1:0]     s_axis_i,
    input  logic signed [DATA_W-1:0]     s_axis_q,
    output logic                         m_axis_valid,
    input  logic                         m_axis_ready,
    output logic signed [DATA_W-1:0]     m_axis_i,
    output logic signed [DATA_W-1:0]     m_axis_q,
    input  logic                         cfg_valid,
    input  logic [$clog2(TAPS)-1:0]      cfg_index,
    input  logic signed [COEFF_W-1:0]    cfg_coefficient
);
    logic signed [COEFF_W-1:0] coefficients [0:TAPS-1];
    logic signed [DATA_W-1:0] delay_i [0:TAPS-2];
    logic signed [DATA_W-1:0] delay_q [0:TAPS-2];
    integer index;

    localparam logic signed [ACC_W-1:0] MAX_DATA = (1 <<< (DATA_W - 1)) - 1;
    localparam logic signed [ACC_W-1:0] MIN_DATA = -(1 <<< (DATA_W - 1));

    function automatic logic signed [DATA_W-1:0] saturate(
        input logic signed [ACC_W-1:0] value
    );
        if (value > MAX_DATA)
            saturate = {1'b0, {(DATA_W-1){1'b1}}};
        else if (value < MIN_DATA)
            saturate = {1'b1, {(DATA_W-1){1'b0}}};
        else
            saturate = value[DATA_W-1:0];
    endfunction

    assign s_axis_ready = !m_axis_valid || m_axis_ready;

    always_ff @(posedge clk) begin : fir_process
        logic signed [ACC_W-1:0] accumulator_i;
        logic signed [ACC_W-1:0] accumulator_q;
        logic signed [ACC_W-1:0] scaled_i;
        logic signed [ACC_W-1:0] scaled_q;

        if (!rst_n) begin
            m_axis_valid <= 1'b0;
            m_axis_i     <= '0;
            m_axis_q     <= '0;
            for (index = 0; index < TAPS; index = index + 1)
                coefficients[index] <= '0;
            coefficients[0] <= (1 <<< COEFF_FRAC) - 1;
            for (index = 0; index < TAPS-1; index = index + 1) begin
                delay_i[index] <= '0;
                delay_q[index] <= '0;
            end
        end else begin
            if (cfg_valid && cfg_index < TAPS)
                coefficients[cfg_index] <= cfg_coefficient;

            if (s_axis_ready) begin
                m_axis_valid <= s_axis_valid;
                if (s_axis_valid) begin
                    accumulator_i = $signed(s_axis_i) * $signed(coefficients[0]);
                    accumulator_q = $signed(s_axis_q) * $signed(coefficients[0]);
                    for (index = 1; index < TAPS; index = index + 1) begin
                        accumulator_i = accumulator_i + $signed(delay_i[index-1]) * $signed(coefficients[index]);
                        accumulator_q = accumulator_q + $signed(delay_q[index-1]) * $signed(coefficients[index]);
                    end
                    scaled_i = accumulator_i >>> COEFF_FRAC;
                    scaled_q = accumulator_q >>> COEFF_FRAC;
                    m_axis_i <= saturate(scaled_i);
                    m_axis_q <= saturate(scaled_q);

                    for (index = TAPS-2; index > 0; index = index - 1) begin
                        delay_i[index] <= delay_i[index-1];
                        delay_q[index] <= delay_q[index-1];
                    end
                    delay_i[0] <= s_axis_i;
                    delay_q[0] <= s_axis_q;
                end
            end
        end
    end

`ifdef FORMAL
    always_ff @(posedge clk) begin
        if (rst_n && $past(rst_n) && $past(m_axis_valid && !m_axis_ready)) begin
            assert(m_axis_valid);
            assert($stable(m_axis_i));
            assert($stable(m_axis_q));
        end
    end
`endif
endmodule

