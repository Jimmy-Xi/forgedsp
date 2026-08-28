// SPDX-License-Identifier: MIT
module axis_skid_buffer #(
    parameter int WIDTH = 32
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 s_axis_valid,
    output logic                 s_axis_ready,
    input  logic [WIDTH-1:0]     s_axis_data,
    output logic                 m_axis_valid,
    input  logic                 m_axis_ready,
    output logic [WIDTH-1:0]     m_axis_data
);
    logic full;
    logic [WIDTH-1:0] stored_data;

    assign s_axis_ready = !full || m_axis_ready;
    assign m_axis_valid = full;
    assign m_axis_data  = stored_data;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            full        <= 1'b0;
            stored_data <= '0;
        end else if (s_axis_ready) begin
            full <= s_axis_valid;
            if (s_axis_valid)
                stored_data <= s_axis_data;
        end
    end

`ifdef FORMAL
    always_ff @(posedge clk) begin
        if (rst_n && $past(rst_n) && $past(m_axis_valid && !m_axis_ready)) begin
            assert(m_axis_valid);
            assert($stable(m_axis_data));
        end
    end
`endif
endmodule

