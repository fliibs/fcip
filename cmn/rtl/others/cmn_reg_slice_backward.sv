module cmn_reg_slice_backward #(
    parameter type PLD_TYPE = logic
)(
    input                       clk,
    input                       rst_n,

    input   logic               s_vld,
    output  logic               s_rdy,
    input   PLD_TYPE            s_pld,

    output  logic               m_vld,
    input   logic               m_rdy,
    output  PLD_TYPE            m_pld

);

logic                   vld_buffer; 
PLD_TYPE                pld_buffer;



assign m_vld = s_vld | vld_buffer;
assign m_pld = vld_buffer ? pld_buffer : s_pld;

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n)                              vld_buffer <= 1'b0;
    else if(s_vld && ~vld_buffer && ~m_rdy) vld_buffer <= 1'b1;
    else if(m_rdy)                          vld_buffer <= 1'b0;
end 

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n)                              pld_buffer <= {$bits(PLD_TYPE){1'b0}};
    else if(s_vld && ~vld_buffer && ~m_rdy) pld_buffer <= s_pld;
end 

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n)                              s_rdy <= 1'b1;
    else                                    s_rdy <= m_rdy;
end

endmodule  