module ocm_xbar
import ocm_package::*;
(
    input  logic                                        wr_data_ram_en                                      ,
    input  pack_ocm_rob_ack_pld                         wr_data_ram_pld                                     ,
    input  logic [OCM_DATA_RAM_UNENC_DATA_WIDTH-1:0]    wr_data_ram_data                                    ,                 
    input  logic                                        rd_data_ram_en                                      ,
    input  pack_ocm_rob_ack_pld                         rd_data_ram_pld                                     ,
    output pack_ocm_ram_wrapper_in_pld                  ram_wrapper_in_pld [OCM_DATA_RAM_BANK_NUM-1:0]      ,
    output logic [OCM_DATA_RAM_UNENC_DATA_WIDTH-1:0]    ram_wrapper_din    [OCM_DATA_RAM_BANK_NUM-1:0]      ,
    output logic                                        wr_data_ram_done                                    ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]              wr_data_ram_id                                      ,
    output logic                                        rd_data_ram_done                                    ,
    output logic [OCM_ROB_ENTRY_WIDTH-1:0]              rd_data_ram_id                          
);
//============================================
//=====================internal signals
//============================================
logic [OCM_DATA_RAM_BANK_NUM-1:0]  v_wr_data_ram_num;
logic [OCM_DATA_RAM_BANK_NUM-1:0]  v_rd_data_ram_num;
logic [OCM_DATA_RAM_BANK_NUM-1:0]  v_wr_data_ram_en ;
logic [OCM_DATA_RAM_BANK_NUM-1:0]  v_rd_data_ram_en ;

//============================================
//=====================decoder
//============================================
cmn_bin2onehot#(
    .BIN_WIDTH    (OCM_DATA_RAM_BANK_NUM_WIDTH  ),
    .ONEHOT_WIDTH (OCM_DATA_RAM_BANK_NUM        )
)u_xbar_wr_dec(
    .bin_in     (wr_data_ram_pld.ram_num),
    .onehot_out (v_wr_data_ram_num      )
);

cmn_bin2onehot#(
    .BIN_WIDTH    (OCM_DATA_RAM_BANK_NUM_WIDTH  ),
    .ONEHOT_WIDTH (OCM_DATA_RAM_BANK_NUM        )
)u_xbar_rd_dec(
    .bin_in     (rd_data_ram_pld.ram_num),
    .onehot_out (v_rd_data_ram_num      )
);

assign v_wr_data_ram_en = {OCM_DATA_RAM_BANK_NUM{wr_data_ram_en}} & v_wr_data_ram_num  ;
assign v_rd_data_ram_en = {OCM_DATA_RAM_BANK_NUM{rd_data_ram_en}} & v_rd_data_ram_num  ;

//============================================
//=====================arbiter
//============================================
genvar i;
generate for(i=0;i<OCM_DATA_RAM_BANK_NUM;i++) begin
ocm_xbar_v_arb u_ocm_xbar_v_arb(
    .v_wr_data_ram_en      (v_wr_data_ram_en[i]  ),
    .v_wr_data_ram_pld     (wr_data_ram_pld      ),  
    .v_wr_data_ram_data    (wr_data_ram_data     ),                 
    .v_rd_data_ram_en      (v_rd_data_ram_en[i]  ),               
    .v_rd_data_ram_pld     (rd_data_ram_pld      ),
    .v_ram_wrapper_in_pld  (ram_wrapper_in_pld[i]),
    .v_ram_wrapper_din     (ram_wrapper_din   [i])
);
end
endgenerate

//============================================
//=====================behavior
//============================================
assign wr_data_ram_done = wr_data_ram_en            ;
assign wr_data_ram_id   = wr_data_ram_pld.rob_id    ;
assign rd_data_ram_done = rd_data_ram_en            ;
assign rd_data_ram_id   = rd_data_ram_pld.rob_id    ;
endmodule