module ocm_ram_wrapper
    import ocm_package::*;
(
    input  logic                                                              clk                       ,
    input  logic                                                              rst_n                     ,
    input  pack_ocm_ram_wrapper_in_pld                                        v_ram_wrapper_in_pld      ,
    input  logic [OCM_DATA_RAM_UNENC_DATA_WIDTH-1:0]                          v_sram_wrapper_din        ,
    output logic                                                              v_sb_err                  ,
    output logic                                                              v_db_err                  ,
    output pack_ocm_ram_wrapper_out_pld                                       v_ram_wrapper_out_pld     , 
    output logic                                                              v_ram_wrapper_out_en      ,   
    //ram if    
    output logic [OCM_DATA_RAM_SPLIT_NUM-1:0] [OCM_DATA_RAM_DATA_WIDTH-1:0]   v_ram_din                 ,
    input  logic [OCM_DATA_RAM_SPLIT_NUM-1:0] [OCM_DATA_RAM_DATA_WIDTH-1:0]   v_ram_dout                ,
    output logic [OCM_DATA_RAM_SPLIT_NUM-1:0]                                 v_ram_en                  ,
    output logic [OCM_DATA_RAM_SPLIT_NUM-1:0]                                 v_ram_wr                  ,
    output logic [OCM_DATA_RAM_SPLIT_NUM-1:0] [OCM_DATA_RAM_ADDR_WIDTH-1:0]   v_ram_addr                
    
);
//==================================================== 
//================internal signals
//==================================================== 
//===============bypass
logic                                     ram_bps_en          ;
logic                                     ram_bps_err         ;
logic                                     ram_bps_pld_err     ;
logic                                     ram_bps_pld_en      ;
pack_ocm_ram_bypass_pld                   ram_bps_pld_regfile ;

//===============ecc
logic [OCM_DATA_RAM_ADDR_WIDTH-1:0]       ram_addr_buf                                  ;
logic [OCM_ECC_DATA_WIDTH-1:0]            ecc_data        [OCM_DATA_RAM_SPLIT_NUM-1:0]  ;
logic [OCM_ECC_TOTAL_WIDTH-1:0]           ecc_enc_total   [OCM_DATA_RAM_SPLIT_NUM-1:0]  ;
logic [OCM_DATA_RAM_SPLIT_NUM-1:0]        ecc_sb_err                                    ;
logic [OCM_DATA_RAM_SPLIT_NUM-1:0]        ecc_db_err                                    ;
logic [OCM_ECC_TOTAL_WIDTH-1:0]           ecc_dec_total   [OCM_DATA_RAM_SPLIT_NUM-1:0]  ;
logic [OCM_ECC_DATA_WIDTH-1:0]            ecc_dec_data    [OCM_DATA_RAM_SPLIT_NUM-1:0]  ;

//==================================================== 
//================bypass regfile
//==================================================== 
always_ff@(posedge clk) begin
    ram_bps_pld_regfile <= v_ram_wrapper_in_pld.ram_bps_pld;
end

assign ram_bps_en = v_ram_wrapper_in_pld.en && (~v_ram_wrapper_in_pld.wr);

always_ff@(posedge clk or negedge rst_n) begin
    if(~rst_n)          ram_bps_pld_en <= 1'b0          ;
    else                ram_bps_pld_en <= ram_bps_en    ; 
end

assign ram_bps_err = (v_ram_wrapper_in_pld.ram_bps_pld.resp==3'b10);

always_ff@(posedge clk) begin
    ram_bps_pld_err <= ram_bps_err  ;
end
//==================================================== 
//================ecc enc
//==================================================== 
genvar i ;
generate for(i=0;i<OCM_DATA_RAM_SPLIT_NUM;i++) begin
    assign ecc_data[i] = {v_ram_wrapper_in_pld.addr,v_sram_wrapper_din[(i+1)*OCM_DATA_RAM_SPLIT_DATA_WIDTH-1:i*OCM_DATA_RAM_SPLIT_DATA_WIDTH]};
    cmn_ecc_enc #(
        .DATA_WIDTH(OCM_ECC_DATA_WIDTH  )
    )u_cmn_ecc_enc(
        .data       (ecc_data[i]        ),       
        .encode_data(ecc_enc_total[i]   )
    );
end
endgenerate

//==================================================== 
//================ecc dec
//==================================================== 
always_ff@(posedge clk) begin
    ram_addr_buf <= v_ram_wrapper_in_pld.addr        ;
end
generate for(i=0;i<OCM_DATA_RAM_SPLIT_NUM;i++) begin
    assign ecc_dec_total[i]= {ram_addr_buf,v_ram_dout[i]};
    cmn_ecc_dec #(
        .DATA_WIDTH(OCM_ECC_DATA_WIDTH  )
    )u_cmn_ecc_dec(
        .encode_data  (ecc_dec_total[i]  ), 
        .data         (ecc_dec_data[i]   ), 
        .sb_err       (ecc_sb_err[i]     ), 
        .db_err       (ecc_db_err[i]     ) 
    );
end
endgenerate

//==================================================== 
//================behavior 
//==================================================== 
generate for(i=0;i<OCM_DATA_RAM_SPLIT_NUM;i++) begin
    assign v_ram_din [i] = ecc_enc_total[i][OCM_DATA_RAM_DATA_WIDTH-1:0]                                                            ;
    // assign v_ram_en  [i] = v_ram_wrapper_in_pld.en && !(v_ram_wrapper_in_pld.wr && !v_ram_wrapper_in_pld.ram_bps_pld.data_msk[i])   ;
    assign v_ram_en  [i] = v_ram_wrapper_in_pld.en && !v_ram_wrapper_in_pld.ram_bps_pld.data_msk[i] && !ram_bps_err                 ;
    assign v_ram_wr  [i] = v_ram_wrapper_in_pld.wr                                                                                  ;
    assign v_ram_addr[i] = v_ram_wrapper_in_pld.addr                                                                                ; 
end
endgenerate

generate for(i=0;i<OCM_DATA_RAM_SPLIT_NUM;i++) begin
    assign v_ram_wrapper_out_pld.dout[OCM_DATA_RAM_SPLIT_DATA_WIDTH*(i+1)-1:OCM_DATA_RAM_SPLIT_DATA_WIDTH*i]  = ecc_dec_data[i][OCM_DATA_RAM_SPLIT_DATA_WIDTH-1:0];
end
endgenerate
//=============ram wrapper out
assign v_ram_wrapper_out_en              = ram_bps_pld_en                           ;
assign v_ram_wrapper_out_pld.ram_bps_pld = ram_bps_pld_regfile                      ;
//=============error 
assign v_sb_err   = |(ecc_sb_err & ram_bps_pld_regfile.data_msk) && ram_bps_pld_en  ;
assign v_db_err   = |(ecc_db_err & ram_bps_pld_regfile.data_msk) && ram_bps_pld_en  ;

endmodule