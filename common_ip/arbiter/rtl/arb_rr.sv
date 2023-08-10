module arb_rr #(
    parameter WIDTH=4
)(
    input               clk,
    input               rst_n,
    input   [WIDTH-1:0] v_vld,
    output  [WIDTH-1:0] v_grant
);

logic [WIDTH-1:0] prio_reg;

logic [WIDTH-1:0] mask_nxt_vld;
logic [WIDTH-1:0] vld_mask;
logic [WIDTH-1:0] mask_grant;

logic [WIDTH-1:0] unmask_nxt_vld;
logic [WIDTH-1:0] unmask_grant;

logic [WIDTH-1:0] unmask_grant_no_mask;

// reg pre priority
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        prio_reg <= {WIDTH{1'b1}};
    end else if(|vld_mask) begin 
        prio_reg <= mask_nxt_vld;
    end else if(|v_vld) begin 
        prio_reg <= unmask_nxt_vld;
    end
end

// vld mask
assign vld_mask = v_vld & prio_reg;

// mask channel
assign mask_nxt_vld[0] = 1'b0; 
assign mask_nxt_vld[WIDTH-1:1] = mask_nxt_vld[WIDTH-2:0] | vld_mask[WIDTH-2:0];
assign mask_grant = (~mask_nxt_vld) & vld_mask;

// unmask channel
assign unmask_nxt_vld[0] = 1'b0;
assign unmask_nxt_vld[WIDTH-1:1] = unmask_nxt_vld[WIDTH-2:0] |  v_vld[WIDTH-2:0];
assign unmask_grant = (~unmask_nxt_vld) & v_vld;

// merge two channel to v_grant
assign unmask_grant_no_mask = {WIDTH{~(|vld_mask)}} & unmask_grant;
assign v_grant = unmask_grant_no_mask | mask_grant;


endmodule