module ocm_ecc_enc
import ocm_package::*;
(
    input  logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0] data_in       ,
    input  logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0] addr_in       ,
    output logic [OCM_ECC_INF_WIDTH-1:0]         ecc_enc_inf  
);
//==================================
//============internal signals
//==================================
logic [OCM_ECC_DATA_WIDTH-1:0]             ecc_data             ;
logic [OCM_ECC_CODE_WIDTH-1:1]             ecc_code_store_data  ;
logic [OCM_ECC_CODE_WIDTH-1:1]             ecc_code_store_inf   ;

logic [OCM_ECC_INF_WIDTH-1:1]              ecc_inf_bit          ;
logic                                      ecc_inf_parity       ;

//==================================
//============funtion
//==================================
function [OCM_ECC_CODE_WIDTH-1:1] store_data_in_ecc_code;
    input [OCM_ECC_DATA_WIDTH-1:0] ecc_data     ;
    integer                        ecc_idx      ;
    integer                        data_idx     ;

    store_data_in_ecc_code = {(OCM_ECC_CODE_WIDTH-1){1'b0}};
    data_idx               = 0                             ;
    
    for(ecc_idx=1;ecc_idx<OCM_ECC_CODE_WIDTH;ecc_idx++) begin
        if(2**$clog2(ecc_idx)!=ecc_idx) store_data_in_ecc_code[ecc_idx] = ecc_data[data_idx++];
    end
endfunction

function [OCM_ECC_INF_WIDTH-1:1] cal_ecc_inf;
    input [OCM_ECC_CODE_WIDTH-1:1] ecc_code     ;
    integer                        inf_idx      ;
    integer                        ecc_idx      ;

    cal_ecc_inf =0 ; 
    for(inf_idx=1;inf_idx<OCM_ECC_INF_WIDTH;inf_idx++) begin
        for(ecc_idx=1;ecc_idx<OCM_ECC_CODE_WIDTH;ecc_idx++) 
            if(|(inf_idx & ecc_idx))    cal_ecc_inf[inf_idx] = cal_ecc_inf[inf_idx] ^ ecc_code[ecc_idx];
    end
endfunction

function [OCM_ECC_CODE_WIDTH-1:1]  store_inf_in_ecc_code;
    input [OCM_ECC_INF_WIDTH-1:1]   ecc_inf ;
    input [OCM_ECC_CODE_WIDTH-1:1]  ecc_code;
    integer                         ecc_idx ;
    integer                         inf_idx ;
    inf_idx = 1;
    for(ecc_idx=1;ecc_idx<OCM_ECC_CODE_WIDTH;ecc_idx++) begin 
        if(2**$clog2(ecc_idx)==ecc_idx) store_inf_in_ecc_code[ecc_idx] = ecc_inf[inf_idx++];
    end
endfunction

//==================================
//============behavior
//================================== 
assign ecc_data             = {data_in,addr_in}                                         ;
assign ecc_code_store_data  = store_data_in_ecc_code(ecc_data)                          ;
assign ecc_inf_bit          = cal_ecc_inf(ecc_code_store_data)                          ;
assign ecc_code_store_inf   = store_inf_in_ecc_code(ecc_inf_bit,ecc_code_store_data)    ;
assign ecc_inf_parity       = ^ecc_code_store_inf                                       ;                                                                  ;
assign ecc_enc_inf          = {ecc_inf_bit,ecc_inf_parity}                              ;

endmodule