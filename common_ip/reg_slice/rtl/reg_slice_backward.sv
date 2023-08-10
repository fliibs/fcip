module reg_slice_backward #(
    parameter PLD_WIDTH = 32
)(
    input                       clk,
    input                       rst_n,

    input                       s_vld,
    output                      s_rdy,
    input   [PLD_WIDTH-1:0]     s_pld,

    output                      m_vld,
    input                       m_rdy,
    output  [PLD_WIDTH-1:0]     m_pld

);

logic                   vld_r;
logic [PLD_WIDTH-1:0]   pld_r;



assign m_vld = s_vld||vld_r;
assign m_pld = vld_r ? pld_r : s_pld;

assign s_rdy = !vld_r;

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) pld_r <= {PLD_WIDTH{1'b0}};
    else if(s_vld&&s_rdy&&!m_rdy) pld_r <= s_pld;
end 

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) vld_r <= 1'b0;
    else if(s_vld&&s_rdy&&!m_rdy) vld_r <= 1'b1;
    else if(m_rdy) vld_r <= 1'b0;
end

endmodule   