module cmn_lead_one #(
    parameter  int unsigned ENTRY_NUM = 16,
    localparam int unsigned AWIDTH    = $clog2(ENTRY_NUM)
) (
    input  logic [ENTRY_NUM-1:0] v_entry_vld,
    output logic [ENTRY_NUM-1:0] v_free_idx_oh  ,
    output logic [AWIDTH-1   :0] v_free_idx_bin ,
    output logic  v_free_vld 
);

//==============================================================
// Internal signal
//==============================================================
    genvar j;
//==============================================================
// generate free onehot
//==============================================================
    assign v_free_idx_oh[0] = v_entry_vld[0];
    generate
        for (j=1;j<ENTRY_NUM;j=j+1) begin
            assign v_free_idx_oh[j] = (v_entry_vld[j]) && (~|v_entry_vld[j-1:0]);
        end
    endgenerate

//==============================================================
// Free channel valid
//==============================================================
    assign v_free_vld = |v_free_idx_oh;


//==============================================================
// onehot to binary
//==============================================================
    cmn_onehot2bin #(
        .ONEHOT_WIDTH(ENTRY_NUM)
    )u_oh2bin(
        .onehot_in(v_free_idx_oh ),
        .bin_out  (v_free_idx_bin)
    );

endmodule