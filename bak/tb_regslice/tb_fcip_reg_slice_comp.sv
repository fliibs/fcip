

// inst three different types of reg slices
// have 3 input and 3 output channel
module tb_fcip_reg_slice_comp (
    input                       clk,
    input                       rst_n,

    input   logic               s_vld_0,
    output  logic               s_rdy_0,
    input   logic [31:0]        s_pld_0,
    output  logic               m_vld_0,
    input   logic               m_rdy_0,
    output  logic [31:0]        m_pld_0,

    input   logic               s_vld_1,
    output  logic               s_rdy_1,
    input   logic [31:0]        s_pld_1,
    output  logic               m_vld_1,
    input   logic               m_rdy_1,
    output  logic [31:0]        m_pld_1,

    input   logic               s_vld_2,
    output  logic               s_rdy_2,
    input   logic [31:0]        s_pld_2,
    output  logic               m_vld_2,
    input   logic               m_rdy_2,
    output  logic [31:0]        m_pld_2
);

    fcip_reg_slice #(
        .PLD_TYPE(logic[31:0]),
        .RS_TYPE(0)
    ) u_fcip_reg_slice_full (
        .clk(clk),
        .rst_n(rst_n),
        .s_vld(s_vld_0),
        .s_rdy(s_rdy_0),
        .s_pld(s_pld_0),
        .m_vld(m_vld_0),
        .m_rdy(m_rdy_0),
        .m_pld(m_pld_0)
    );

    fcip_reg_slice #(
        .PLD_TYPE(logic[31:0]),
        .RS_TYPE(1)
    ) u_fcip_reg_slice_forward (
        .clk(clk),
        .rst_n(rst_n),
        .s_vld(s_vld_1),
        .s_rdy(s_rdy_1),
        .s_pld(s_pld_1),
        .m_vld(m_vld_1),
        .m_rdy(m_rdy_1),
        .m_pld(m_pld_1)
    );

    fcip_reg_slice #(
        .PLD_TYPE(logic[31:0]),
        .RS_TYPE(2)
    ) u_fcip_reg_slice_backward (
        .clk(clk),
        .rst_n(rst_n),
        .s_vld(s_vld_2),
        .s_rdy(s_rdy_2),
        .s_pld(s_pld_2),
        .m_vld(m_vld_2),
        .m_rdy(m_rdy_2),
        .m_pld(m_pld_2)
    );

endmodule