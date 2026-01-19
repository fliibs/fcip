module fcip_onehot_demux #(
    parameter integer unsigned WIDTH=8,
    parameter type             PLD_TYPE=logic
) (
    input  logic             s_vld,
    output logic             s_rdy,
    input  PLD_TYPE          s_pld,
    input  logic [WIDTH-1:0] sel_onehot,
    output logic [WIDTH-1:0] v_m_vld,
    input  logic [WIDTH-1:0] v_m_rdy,
    output PLD_TYPE          v_m_pld [WIDTH-1:0]
);

    assign s_rdy = |(v_m_rdy & sel_onehot);
    assign v_m_vld = {WIDTH{s_vld}} & sel_onehot;
    always_comb begin : ASSIGN_PLD
        for (int i=0; i<WIDTH; i++) begin
            v_m_pld[i] = s_pld;
        end
    end
    
endmodule