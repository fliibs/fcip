module cmn_fix_arb #(
    parameter type PLD_TYPE = logic
)(
    input                       clk,
    input                       rst_n,

    input   logic               s_vld_priority,
    output  logic               s_rdy_priority,
    input   PLD_TYPE            s_pld_priority,
    
    input   logic               s_vld,
    output  logic               s_rdy,
    input   PLD_TYPE            s_pld,

    output  logic               m_vld,
    input   logic               m_rdy,
    output  PLD_TYPE            m_pld

);


    assign m_vld            = s_vld_priority | s_vld                    ;
    assign s_rdy_priority   = s_vld_priority ? m_rdy : 1'b0             ;
    assign s_rdy            = s_vld_priority ? 1'b0 : m_rdy             ;
    assign m_pld            = s_vld_priority ? s_pld_priority : s_pld   ;


endmodule   