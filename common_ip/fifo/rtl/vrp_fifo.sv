module vrp_fifo #(
    parameter PLD_WIDTH     = 32,
    parameter DEPTH         = 8,
    parameter PNTR_WDITH    = $clog2(DEPTH) 
)(
    input                   clk,
    input                   rst_n,

    input                   vld_s,
    output                  rdy_s,
    input [PLD_WIDTH-1:0]   pld_s, 

    output                  vld_m,
    output [PLD_WIDTH-1:0]  pld_m,
    input                   rdy_m
);

logic [PLD_WIDTH-1:0] mem_r [DEPTH-1:0];

logic [PNTR_WDITH:0] pntr_w;
logic [PNTR_WDITH:0] pntr_r;
logic full, empty;

// full & empty
assign full  = pntr_r=={~pntr_w[PNTR_WDITH],pntr_w[PNTR_WDITH-1:0]};
assign empty = pntr_r==pntr_w;

//read channel
assign pld_m = mem_r[pntr_r[PNTR_WDITH-1:0]];
assign vld_m = !empty;

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) pntr_r <= {PNTR_WDITH{1'b0}};
    else if(vld_m&&rdy_m) pntr_r <= pntr_r + 1'b1;
end


//write channel
assign rdy_s = !full;

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) pntr_w <= {PNTR_WDITH{1'b0}};
    else if(vld_s&&rdy_s) pntr_w <= pntr_w + 1'b1;
end 

always @(posedge clk) begin 
    if(vld_s&&rdy_s) mem_r[pntr_w] <= pld_s;

end 



endmodule 