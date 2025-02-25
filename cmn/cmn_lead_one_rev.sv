module cmn_lead_one_rev #(
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

    logic [ENTRY_NUM-1:0] v_entry_vld_rev;
    generate 
        for(genvar i=0; i < ENTRY_NUM; i=i+1) begin: gen_rev
            assign v_entry_vld_rev[i] = v_entry_vld[ENTRY_NUM-1-i];
        end 
    endgenerate 
//==============================================================
// generate free onehot
//==============================================================
    logic [ENTRY_NUM-1:0] v_free_idx_oh_rev;
    assign v_free_idx_oh_rev[0] = v_entry_vld_rev[0];
    generate
        for (j=1;j<ENTRY_NUM;j=j+1) begin
            assign v_free_idx_oh_rev[j] = (v_entry_vld_rev[j]) && (~|v_entry_vld_rev[j-1:0]);
        end
    endgenerate

    generate 
        for(genvar i=0; i < ENTRY_NUM; i=i+1) begin: gen_rev_back 
            assign v_free_idx_oh[i] = v_free_idx_oh_rev[ENTRY_NUM-1-i];
        end 
    endgenerate 
    

//==============================================================
// Free channel valid
//==============================================================
    assign v_free_vld = |v_free_idx_oh_rev;


//==============================================================
// onehot to binary
//==============================================================
    cmn_onehot2bin #(
        .ONEHOT_WIDTH(ENTRY_NUM)
    )u_oh2bin(
        .onehot_in(v_free_idx_oh),
        .bin_out  (v_free_idx_bin)
    );

endmodule