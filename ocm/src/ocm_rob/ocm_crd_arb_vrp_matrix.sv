module ocm_crd_arb_vrp_matrix
#(
    parameter  integer unsigned WIDTH        = 4                    ,
    parameter  integer unsigned CRD_NUM      = 8                    , 
    parameter  type             PLD_TYPE     = logic                ,
    localparam integer unsigned CRD_CNT_WIDHT= $clog2(CRD_NUM)+1
)(
    input   logic                        clk    ,
    input   logic                        rst_n  ,
    input   logic                        crd    ,  
    input   logic    [WIDTH-1:0]         vv_matrix [WIDTH-1:0],

    input   logic    [WIDTH-1:0]         v_vld_s,
    output  logic    [WIDTH-1:0]         v_rdy_s,
    input   PLD_TYPE                     v_pld_s   [WIDTH-1:0],

    output  logic                        vld_m,
    input   logic                        rdy_m,
    output  PLD_TYPE                     pld_m
);
//============================================= 
//==========internal signals
//=============================================
logic  [CRD_CNT_WIDHT-1:0]  crd_cnt      ;  
logic                       m_hsk        ; 
logic  [WIDTH-1:0]          select_onehot;
PLD_TYPE                    select_pld   ;

assign m_hsk = vld_m && rdy_m   ;
always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)                  crd_cnt <= {CRD_CNT_WIDHT{1'b0}}                        ;
    else if(m_hsk && ~crd  )    crd_cnt <= crd_cnt - {{(CRD_CNT_WIDHT-1){1'b0}},{1'b1}} ;
    else if(crd   && ~m_hsk)    crd_cnt <= crd_cnt + {{(CRD_CNT_WIDHT-1){1'b0}},{1'b1}} ;
    else                        crd_cnt <= crd_cnt                                      ;
end

genvar i;
generate
    for(i=0;i<WIDTH;i=i+1) begin: select_onehot_
        assign select_onehot[i] =  (~|(v_vld_s&vv_matrix[i])) && (rdy_m && v_vld_s[i]);
    end
endgenerate

cmn_real_mux_onehot #(
    .WIDTH    (WIDTH                ),
    .PLD_WIDTH($bits(PLD_TYPE)      )
) u_mux (
    .select_onehot  (select_onehot  ),
    .v_pld          (v_pld_s        ),
    .select_pld     (select_pld     )
);

assign vld_m   = |v_vld_s && |crd_cnt   ;
assign pld_m   = select_pld             ;
assign v_rdy_s = select_onehot          ;
endmodule