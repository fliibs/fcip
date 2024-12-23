module reg_slice_forward #(
    parameter type PLD_TYPE = logic
)(
    input                       clk,
    input                       rst_n,

    input                       s_vld,
    output                      s_rdy,
    input   PLD_TYPE            s_pld,

    output                      m_vld,
    input                       m_rdy,
    output  PLD_TYPE            m_pld

);

logic                   vld_r;
PLD_TYPE                pld_r;

assign s_rdy = !m_vld || m_rdy;
assign m_vld = vld_r;
assign m_pld = pld_r;

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) vld_r <= 1'b0;
    else if(s_vld&&s_rdy) vld_r <= 1'b1;
    else if(m_rdy) vld_r <= 1'b0;
end 

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) pld_r <= {($bits(PLD_TYPE)){1'b0}};
    else if(s_vld&&s_rdy) pld_r <= s_pld;
end 

endmodule   