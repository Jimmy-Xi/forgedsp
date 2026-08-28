// SPDX-License-Identifier: MIT
module fft8_stream #(
    parameter int DATA_W = 16,
    parameter int INTERNAL_W = DATA_W + 3
) (
    input  logic                           clk,
    input  logic                           rst_n,
    input  logic                           s_axis_valid,
    output logic                           s_axis_ready,
    input  logic signed [DATA_W-1:0]       s_axis_i,
    input  logic signed [DATA_W-1:0]       s_axis_q,
    output logic                           m_axis_valid,
    input  logic                           m_axis_ready,
    output logic signed [INTERNAL_W-1:0]   m_axis_i,
    output logic signed [INTERNAL_W-1:0]   m_axis_q,
    output logic [2:0]                     m_axis_index,
    output logic                           m_axis_last
);
    typedef enum logic [1:0] {COLLECT, COMPUTE, OUTPUT_FRAME} state_t;
    state_t state;
    logic signed [INTERNAL_W-1:0] memory_i [0:7];
    logic signed [INTERNAL_W-1:0] memory_q [0:7];
    logic [2:0] input_count;
    logic [1:0] stage;
    logic [2:0] butterfly;
    logic [2:0] output_count;
    integer index;

    function automatic logic [2:0] bit_reverse3(input logic [2:0] value);
        bit_reverse3 = {value[0], value[1], value[2]};
    endfunction

    function automatic logic signed [15:0] twiddle_real(input logic [1:0] value);
        case (value)
            2'd0: twiddle_real = 16'sd32767;
            2'd1: twiddle_real = 16'sd23170;
            2'd2: twiddle_real = 16'sd0;
            default: twiddle_real = -16'sd23170;
        endcase
    endfunction

    function automatic logic signed [15:0] twiddle_imag(input logic [1:0] value);
        case (value)
            2'd0: twiddle_imag = 16'sd0;
            2'd1: twiddle_imag = -16'sd23170;
            2'd2: twiddle_imag = 16'sh8000;
            default: twiddle_imag = -16'sd23170;
        endcase
    endfunction

    assign s_axis_ready = (state == COLLECT);
    assign m_axis_valid = (state == OUTPUT_FRAME);
    assign m_axis_i = memory_i[output_count];
    assign m_axis_q = memory_q[output_count];
    assign m_axis_index = output_count;
    assign m_axis_last = (output_count == 3'd7);

    always_ff @(posedge clk) begin : fft_process
        integer first_index;
        integer second_index;
        logic [1:0] twiddle_index;
        logic signed [INTERNAL_W-1:0] a_i;
        logic signed [INTERNAL_W-1:0] a_q;
        logic signed [INTERNAL_W-1:0] b_i;
        logic signed [INTERNAL_W-1:0] b_q;
        logic signed [INTERNAL_W+15:0] multiply_rr;
        logic signed [INTERNAL_W+15:0] multiply_ii;
        logic signed [INTERNAL_W+15:0] multiply_ri;
        logic signed [INTERNAL_W+15:0] multiply_ir;
        logic signed [INTERNAL_W:0] product_i;
        logic signed [INTERNAL_W:0] product_q;

        if (!rst_n) begin
            state        <= COLLECT;
            input_count  <= '0;
            stage        <= '0;
            butterfly    <= '0;
            output_count <= '0;
            for (index = 0; index < 8; index = index + 1) begin
                memory_i[index] <= '0;
                memory_q[index] <= '0;
            end
        end else begin
            case (state)
                COLLECT: begin
                    if (s_axis_valid && s_axis_ready) begin
                        memory_i[bit_reverse3(input_count)] <= {{(INTERNAL_W-DATA_W){s_axis_i[DATA_W-1]}}, s_axis_i};
                        memory_q[bit_reverse3(input_count)] <= {{(INTERNAL_W-DATA_W){s_axis_q[DATA_W-1]}}, s_axis_q};
                        if (input_count == 3'd7) begin
                            input_count <= '0;
                            stage       <= '0;
                            butterfly   <= '0;
                            state       <= COMPUTE;
                        end else begin
                            input_count <= input_count + 3'd1;
                        end
                    end
                end

                COMPUTE: begin
                    if (stage == 0) begin
                        first_index  = butterfly * 2;
                        second_index = first_index + 1;
                        twiddle_index = 0;
                    end else if (stage == 1) begin
                        first_index  = (butterfly / 2) * 4 + (butterfly % 2);
                        second_index = first_index + 2;
                        twiddle_index = (butterfly % 2) * 2;
                    end else begin
                        first_index  = butterfly;
                        second_index = butterfly + 4;
                        twiddle_index = butterfly[1:0];
                    end

                    a_i = memory_i[first_index];
                    a_q = memory_q[first_index];
                    b_i = memory_i[second_index];
                    b_q = memory_q[second_index];
                    multiply_rr = b_i * twiddle_real(twiddle_index);
                    multiply_ii = b_q * twiddle_imag(twiddle_index);
                    multiply_ri = b_i * twiddle_imag(twiddle_index);
                    multiply_ir = b_q * twiddle_real(twiddle_index);
                    product_i = (multiply_rr - multiply_ii) >>> 15;
                    product_q = (multiply_ri + multiply_ir) >>> 15;
                    memory_i[first_index]  <= a_i + product_i;
                    memory_q[first_index]  <= a_q + product_q;
                    memory_i[second_index] <= a_i - product_i;
                    memory_q[second_index] <= a_q - product_q;

                    if (butterfly == 3'd3) begin
                        butterfly <= '0;
                        if (stage == 2) begin
                            output_count <= '0;
                            state <= OUTPUT_FRAME;
                        end else begin
                            stage <= stage + 2'd1;
                        end
                    end else begin
                        butterfly <= butterfly + 3'd1;
                    end
                end

                default: begin
                    if (m_axis_valid && m_axis_ready) begin
                        if (output_count == 3'd7) begin
                            output_count <= '0;
                            state <= COLLECT;
                        end else begin
                            output_count <= output_count + 3'd1;
                        end
                    end
                end
            endcase
        end
    end

`ifdef FORMAL
    always_ff @(posedge clk) begin
        if (rst_n && $past(rst_n) && $past(m_axis_valid && !m_axis_ready)) begin
            assert(m_axis_valid);
            assert($stable(m_axis_i));
            assert($stable(m_axis_q));
            assert($stable(m_axis_index));
            assert($stable(m_axis_last));
        end
    end
`endif
endmodule
