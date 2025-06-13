module cmn_arb_vrp_matrix #(
        parameter  integer unsigned WIDTH        =4,
        parameter  type             PLD_TYPE     = logic
    )(
        input   logic                        clk,
        input   logic                        rst_n,

        input   logic    [WIDTH-1:0]         vv_matrix [WIDTH-1:0],

        input   logic    [WIDTH-1:0]         v_vld_s,
        output  logic    [WIDTH-1:0]         v_rdy_s,
        input   PLD_TYPE                     v_pld_s   [WIDTH-1:0],

        output  logic                        vld_m,
        input   logic                        rdy_m,
        output  PLD_TYPE                     pld_m
    );


    logic    [WIDTH-1:0]       select_onehot;
    PLD_TYPE                   select_pld;

    genvar i;
    generate
        for(i=0;i<WIDTH;i=i+1) begin: select_onehot_
            assign select_onehot[i] =  (~|(v_vld_s&vv_matrix[i])) && v_vld_s[i];
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

    assign vld_m   = |v_vld_s;
    assign pld_m   = select_pld;
    assign v_rdy_s = select_onehot & {WIDTH{rdy_m}};

endmodule