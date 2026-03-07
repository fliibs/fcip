module fcip_onehot_mux_pld #(
    parameter integer unsigned    REQ_NUM  = 4,
    parameter type                PLD_TYPE = logic
) (
    input   logic   [REQ_NUM-1:0]         in_sel,
    input   PLD_TYPE                      in_pld [REQ_NUM-1:0],
    output  PLD_TYPE                      out_pld
);
    always_comb begin
        out_pld = {$bits(PLD_TYPE){1'b0}};
        for (int i=0; i<REQ_NUM; i++) begin
            out_pld = in_sel[i] ? out_pld | in_pld[i] : out_pld;
        end
    end
endmodule
