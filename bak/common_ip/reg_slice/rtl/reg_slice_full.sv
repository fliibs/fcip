module reg_slice_full #(
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

logic [PLD_WIDTH-1:0] pld_r [1:0];

logic [1:0] pntr_w;
logic [1:0] pntr_r;

assign s_rdy = ~(pntr_w=={~pntr_r[1],pntr_r[0]}); // not full
assign m_vld = ~(pntr_w==pntr_r); // not empty

assign m_pld = pntr_r[0] ? pld_r[1] : pld_r[0];

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) pntr_w <= 2'b0;
    else if(s_vld&&s_rdy) pntr_w <= pntr_w + 1'b1;
end

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) pntr_r <= 2'b0;
    else if(m_rdy&&m_vld) pntr_r <= pntr_r + 1'b1;
end

genvar i;
generate
    for(i=0;i<2;i=i+1) begin: reg_num
        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) pld_r[i] <= {PLD_WIDTH{1'b0}};
            else if(s_vld&&s_rdy&&(pntr_w[0]==i)) pld_r[i] <= s_pld;
        end
    end 
endgenerate




endmodule   