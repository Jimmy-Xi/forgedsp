// SPDX-License-Identifier: MIT
module axis_skid_buffer_formal;
    localparam int WIDTH = 8;
    (* gclk *) logic clk;
    logic rst_n = 1'b0;
    (* anyseq *) logic s_axis_valid;
    (* anyseq *) logic [WIDTH-1:0] s_axis_data;
    (* anyseq *) logic m_axis_ready;
    logic s_axis_ready;
    logic m_axis_valid;
    logic [WIDTH-1:0] m_axis_data;
    logic past_valid = 1'b0;

    axis_skid_buffer #(.WIDTH(WIDTH)) dut (
        .clk,
        .rst_n,
        .s_axis_valid,
        .s_axis_ready,
        .s_axis_data,
        .m_axis_valid,
        .m_axis_ready,
        .m_axis_data
    );

    always_ff @(posedge clk) begin
        past_valid <= 1'b1;
        if (!past_valid) begin
            assume(!rst_n);
            rst_n <= 1'b1;
        end else begin
            assume(rst_n);
            assert(s_axis_ready == (!m_axis_valid || m_axis_ready));
            if ($past(past_valid && rst_n && m_axis_valid && !m_axis_ready)) begin
                assert(m_axis_valid);
                assert($stable(m_axis_data));
            end
            cover(s_axis_valid && s_axis_ready);
            cover(m_axis_valid && m_axis_ready);
        end
    end
endmodule
