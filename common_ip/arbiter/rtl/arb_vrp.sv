module arb_vrp #(
    parameter MODE      = 0, // 0: Fix_Priority 1:Round_Robin 2:Age_Matrix
    parameter HSK_MODE  = 1, // 0: Pass 1: 1-Cycle
    parameter WIDTH     = 4,
    parameter PRIORITY  = {WIDTH{1'b0}},
    parameter PLD_WIDTH = 32
)(
    input                       clk,
    input                       rst_n,

    input   [WIDTH-1:0]         v_vld_s,
    output  [WIDTH-1:0]         v_rdy_s,
    input   [PLD_WIDTH-1:0]     v_pld_s   [WIDTH-1:0],
    
    output                      vld_m,
    input                       rdy_m,
    output  [PLD_WIDTH-1:0]     pld_m
);

logic [WIDTH-1:0]       v_grant;

logic [WIDTH-1:0]       v_vld;
logic [WIDTH-1:0]       v_rdy;

logic [PLD_WIDTH-1:0]   m_pld;
logic                   m_vld;

assign v_vld = v_vld_s;
assign v_rdy_s = v_grant & {WIDTH{rdy_m}};
assign m_vld = |v_vld_s;

generate 
    if(HSK_MODE==0) begin
        assign vld_m   = m_vld;
        assign pld_m   = m_pld;
        
    end else if(HSK_MODE==1) begin 
        logic                   vld_m_r;
        logic [PLD_WIDTH-1:0]   pld_m_r;

        assign vld_m   = vld_m_r;
        assign pld_m   = pld_m_r;

        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) vld_m_r  <= 1'b0;
            else       vld_m_r  <= m_vld;
        end 

        always @(posedge clk or negedge rst_n) begin 
            if(~rst_n) pld_m_r  <= 1'b0;
            else       pld_m_r  <= m_pld;
        end 
    
    end else begin 
        assign vld_m   = m_vld;
        assign pld_m   = m_pld;
    end 
endgenerate


real_mux_onehot #(
    .WIDTH(WIDTH),
    .PLD_WIDTH(PLD_WIDTH)
) u_mux (
    .select_onehot(v_grant),
    .v_pld(v_pld_s),
    .select_pld(m_pld)
);


generate
    if(MODE==0) begin 
        arb_fp #(
            .WIDTH(WIDTH)
        ) u_arb (
            .v_vld      (v_vld),
            .v_priority (PRIORITY),
            .v_grant    (v_grant)
        );
    end else if(MODE==1) begin 
        arb_rr #(
            .WIDTH(WIDTH)
        ) u_arb (
            .clk        (clk),
            .rst_n      (rst_n),
            .v_vld      (v_vld),
            .v_grant    (v_grant)
        );
    end else if(MODE==2) begin 
        logic               alloc_en;
        logic [WIDTH-1:0]   v_alloc;
        logic [WIDTH-1:0]   vv_matrix [WIDTH-1:0];

        assign alloc_en = |v_grant; // TODO
        assign v_alloc  = v_grant;

        age_matrix #(
            .WIDTH(WIDTH)
        ) u_matrix (
            .clk        (clk),
            .rst_n      (rst_n),
            .alloc_en   (alloc_en),
            .v_alloc    (v_alloc),
            .vv_matrix  (vv_matrix)
        );

        arb_matrix #(
            .WIDTH(WIDTH)
        ) u_arb (
            .clk        (clk),
            .rst_n      (rst_n),
            .vv_matrix  (vv_matrix),
            .v_vld      (v_vld),
            .v_grant    (v_grant)
        );
    end else begin 
        arb_rr #(
            .WIDTH(WIDTH)
        ) u_arb (
            .clk        (clk),
            .rst_n      (rst_n),
            .v_vld      (v_vld),
            .v_grant    (v_grant)
        );
    end

endgenerate




endmodule