// SPDX-License-Identifier: MIT
module axis_quarter_rate_mixer #(
    parameter int DATA_W = 16
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
    output logic signed [DATA_W-1:0]     m_axis_q
);
    logic [1:0] phase;

    assign s_axis_ready = !m_axis_valid || m_axis_ready;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            phase        <= 2'd0;
            m_axis_valid <= 1'b0;
            m_axis_i     <= '0;
            m_axis_q     <= '0;
        end else if (s_axis_ready) begin
            m_axis_valid <= s_axis_valid;
            if (s_axis_valid) begin
                case (phase)
                    2'd0: begin m_axis_i <=  s_axis_i; m_axis_q <=  s_axis_q; end
                    2'd1: begin m_axis_i <=  s_axis_q; m_axis_q <= -s_axis_i; end
                    2'd2: begin m_axis_i <= -s_axis_i; m_axis_q <= -s_axis_q; end
                    default: begin m_axis_i <= -s_axis_q; m_axis_q <= s_axis_i; end
                endcase
                phase <= phase + 2'd1;
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

