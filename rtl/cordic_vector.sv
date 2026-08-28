// SPDX-License-Identifier: MIT
module cordic_vector #(
    parameter int DATA_W = 16,
    parameter int PHASE_W = 16,
    parameter int ITERATIONS = 16,
    parameter int XY_W = DATA_W + 3
) (
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic                         s_axis_valid,
    output logic                         s_axis_ready,
    input  logic signed [DATA_W-1:0]     s_axis_i,
    input  logic signed [DATA_W-1:0]     s_axis_q,
    output logic                         m_axis_valid,
    input  logic                         m_axis_ready,
    output logic [DATA_W:0]              m_axis_magnitude,
    output logic signed [PHASE_W-1:0]    m_axis_phase
);
    typedef enum logic [1:0] {IDLE, ROTATE, RESULT} state_t;
    state_t state;
    logic signed [XY_W-1:0] x_value;
    logic signed [XY_W-1:0] y_value;
    logic signed [PHASE_W:0] phase_value;
    logic [$clog2(ITERATIONS)-1:0] iteration;

    function automatic logic signed [PHASE_W-1:0] atan_value(input integer value);
        case (value)
            0: atan_value = 16'sd8192;
            1: atan_value = 16'sd4836;
            2: atan_value = 16'sd2555;
            3: atan_value = 16'sd1297;
            4: atan_value = 16'sd651;
            5: atan_value = 16'sd326;
            6: atan_value = 16'sd163;
            7: atan_value = 16'sd81;
            8: atan_value = 16'sd41;
            9: atan_value = 16'sd20;
            10: atan_value = 16'sd10;
            11: atan_value = 16'sd5;
            12: atan_value = 16'sd3;
            13: atan_value = 16'sd1;
            14: atan_value = 16'sd1;
            default: atan_value = 16'sd0;
        endcase
    endfunction

    assign s_axis_ready = (state == IDLE);
    assign m_axis_valid = (state == RESULT);

    always_ff @(posedge clk) begin : cordic_process
        logic signed [XY_W-1:0] next_x;
        logic signed [XY_W-1:0] next_y;
        logic signed [PHASE_W:0] next_phase;
        logic signed [XY_W+15:0] gain_product;

        if (!rst_n) begin
            state            <= IDLE;
            x_value          <= '0;
            y_value          <= '0;
            phase_value      <= '0;
            iteration        <= '0;
            m_axis_magnitude <= '0;
            m_axis_phase     <= '0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_valid && s_axis_ready) begin
                        if (s_axis_i < 0) begin
                            x_value <= -{{(XY_W-DATA_W){s_axis_i[DATA_W-1]}}, s_axis_i};
                            y_value <= -{{(XY_W-DATA_W){s_axis_q[DATA_W-1]}}, s_axis_q};
                            phase_value <= s_axis_q >= 0 ? ((1 <<< (PHASE_W-1)) - 1) : -(1 <<< (PHASE_W-1));
                        end else begin
                            x_value <= {{(XY_W-DATA_W){s_axis_i[DATA_W-1]}}, s_axis_i};
                            y_value <= {{(XY_W-DATA_W){s_axis_q[DATA_W-1]}}, s_axis_q};
                            phase_value <= '0;
                        end
                        iteration <= '0;
                        state <= ROTATE;
                    end
                end

                ROTATE: begin
                    if (y_value >= 0) begin
                        next_x = x_value + (y_value >>> iteration);
                        next_y = y_value - (x_value >>> iteration);
                        next_phase = phase_value + atan_value(iteration);
                    end else begin
                        next_x = x_value - (y_value >>> iteration);
                        next_y = y_value + (x_value >>> iteration);
                        next_phase = phase_value - atan_value(iteration);
                    end
                    x_value <= next_x;
                    y_value <= next_y;
                    phase_value <= next_phase;
                    if (iteration == ITERATIONS-1) begin
                        gain_product = next_x * 16'sd19898;
                        m_axis_magnitude <= gain_product >>> 15;
                        if (next_phase > ((1 <<< (PHASE_W-1)) - 1))
                            m_axis_phase <= {1'b0, {(PHASE_W-1){1'b1}}};
                        else if (next_phase < -(1 <<< (PHASE_W-1)))
                            m_axis_phase <= {1'b1, {(PHASE_W-1){1'b0}}};
                        else
                            m_axis_phase <= next_phase[PHASE_W-1:0];
                        state <= RESULT;
                    end else begin
                        iteration <= iteration + 1'b1;
                    end
                end

                default: begin
                    if (m_axis_valid && m_axis_ready)
                        state <= IDLE;
                end
            endcase
        end
    end

`ifdef FORMAL
    always_ff @(posedge clk) begin
        if (rst_n && $past(rst_n) && $past(m_axis_valid && !m_axis_ready)) begin
            assert(m_axis_valid);
            assert($stable(m_axis_magnitude));
            assert($stable(m_axis_phase));
        end
    end
`endif
endmodule

