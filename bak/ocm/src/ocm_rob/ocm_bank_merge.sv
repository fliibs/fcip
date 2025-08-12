module ocm_bank_merge
import ocm_package::*;
(
    input  logic [OCM_ROB_ENTRY_DEPTH-1:0]          raw_vld                             ,
    input  logic [OCM_DATA_RAM_BANK_NUM_WIDTH-1:0]  bank_num [OCM_ROB_ENTRY_DEPTH-1:0]  ,
    input  logic [OCM_DATA_RAM_BANK_NUM-1:0]        bank_mask                           ,
    output logic [OCM_ROB_ENTRY_DEPTH-1:0]          vld                                 
);
logic [OCM_DATA_RAM_BANK_NUM-1:0] bank_num_ohot [OCM_ROB_ENTRY_DEPTH-1:0];
logic [OCM_DATA_RAM_BANK_NUM-1:0] bank_num_msk  [OCM_ROB_ENTRY_DEPTH-1:0];
logic [OCM_ROB_ENTRY_DEPTH-1:0]   bank_num_vld                           ;

genvar i;
generate for(i=0;i<OCM_ROB_ENTRY_DEPTH;i++) begin
    cmn_bin2onehot#(
        .BIN_WIDTH   (OCM_DATA_RAM_BANK_NUM_WIDTH),
        .ONEHOT_WIDTH(OCM_DATA_RAM_BANK_NUM      )
    )u_bank_num_bin2ohot(
        .bin_in      (bank_num[i]),
        .onehot_out  (bank_num_ohot[i])
    );
    assign bank_num_msk[i] = bank_num_ohot[i] & bank_mask;
    assign bank_num_vld[i] = |bank_num_msk[i]            ;
end
endgenerate

assign vld = raw_vld & bank_num_vld ;
endmodule