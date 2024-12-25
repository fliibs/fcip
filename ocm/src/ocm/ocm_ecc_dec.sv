module ocm_ecc_dec
import ocm_package::*;
(
    input  logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0] data_in        ,       
    input  logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0] addr_in        ,       
    input  logic [OCM_ECC_INF_WIDTH-1:0]         ecc_enc_inf    ,
    output logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0] data_out       ,
    output logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0] addr_out       ,
    output logic                                 uncor_err      ,
    output logic                                 cor_err        
);
//==================================
//============internal signals
//==================================
logic [OCM_ECC_DATA_WIDTH-1:0]      ecc_data                ;
logic [OCM_ECC_INF_WIDTH-1:1]       ecc_dec_inf_no_par      ;

logic [OCM_ECC_CODE_WIDTH-1:1]      ecc_enc_code            ;
logic [OCM_ECC_INF_WIDTH-1:1]       ecc_enc_inf_no_par      ; 

// logic [OCM_ECC_CODE_WIDTH-1:1]      ecc_dec_code_bit    ;
// logic                               par_err                 ;

logic                               ecc_dec_par             ;
logic [OCM_ECC_CODE_WIDTH-1:0]      ecc_uncor_code          ;
logic [OCM_ECC_CODE_WIDTH-1:0]      ecc_cor_code            ;

//==================================
//============funtion
//==================================
function [OCM_ECC_CODE_WIDTH-1:1]       join_ecc_code;
    input [OCM_ECC_DATA_WIDTH-1:0]      ecc_data     ;
    input [OCM_ECC_INF_WIDTH-1:1]       ecc_enc_inf  ;
    integer ecc_idx   ;
    integer inf_idx   ;
    integer data_idx  ;
    data_idx = 0      ;   
    inf_idx  = 1      ;   
    for(int ecc_idx=1;ecc_idx<OCM_ECC_CODE_WIDTH;ecc_idx++) begin
        if(2**$clog2(ecc_idx)==ecc_idx) 
            join_ecc_code[ecc_idx] = ecc_enc_inf[inf_idx++]; 
        else
            join_ecc_code[ecc_idx] = ecc_data[data_idx++]  ;  
    end
endfunction

function [OCM_ECC_INF_WIDTH-1:1] cal_dec_inf    ;
    input [OCM_ECC_CODE_WIDTH-1:1] ecc_enc_code ;
    input [OCM_ECC_INF_WIDTH-1:1]  ecc_enc_inf  ;
    integer inf_idx                             ;
    integer ecc_idx                             ;
    cal_dec_inf = 0                             ; 
    for(inf_idx = 1; inf_idx<OCM_ECC_INF_WIDTH ; inf_idx++) begin
        for(ecc_idx = 1;ecc_idx<OCM_ECC_CODE_WIDTH;ecc_idx++) begin
            if(|(ecc_idx & 2**(inf_idx-1))) cal_dec_inf[inf_idx] = cal_dec_inf[inf_idx] ^ ecc_enc_code[ecc_idx];  
        end
    end
endfunction


function [OCM_ECC_CODE_WIDTH-1:0] correct_codeword      ;
    input [OCM_ECC_CODE_WIDTH-1:0] uncorrect_codeword   ;
    input [OCM_ECC_INF_WIDTH-1:1]  dec_inf              ;
    correct_codeword          = uncorrect_codeword          ;
    correct_codeword[dec_inf] = ~uncorrect_codeword[dec_inf];
endfunction

function [OCM_ECC_DATA_WIDTH-1:0] extract_ecc_data      ;
    input [OCM_ECC_CODE_WIDTH-1:0] correct_ecc_code     ;
    integer ecc_idx ;
    integer data_idx;
    data_idx = 0    ;
    for(ecc_idx=1; ecc_idx<OCM_ECC_CODE_WIDTH; ecc_idx++) begin
        if(2**$clog2(ecc_idx)!=ecc_idx) extract_ecc_data[data_idx++] = correct_ecc_code[ecc_idx];
    end

endfunction
//==================================
//============behavior
//================================== 
assign ecc_data             = {data_in,addr_in}                                     ;
assign ecc_dec_par          = ^{data_in,addr_in,ecc_enc_inf}                        ;     
assign ecc_enc_inf_no_par   = ecc_enc_inf[OCM_ECC_INF_WIDTH-1:1]                    ;
assign ecc_enc_code         = join_ecc_code(ecc_data, ecc_enc_inf_no_par)           ;
assign ecc_dec_inf_no_par   = cal_dec_inf(ecc_enc_code,ecc_enc_inf_no_par)          ;
//#TODO:if needs to seperate information error and data error       
assign cor_err              = ecc_dec_par  & (|ecc_dec_inf_no_par)                  ;
assign uncor_err            = ~ecc_dec_par & (|ecc_dec_inf_no_par)                  ;
assign ecc_uncor_code       = {ecc_enc_code,ecc_dec_par}                            ;
assign ecc_cor_code         = correct_codeword(ecc_uncor_code,ecc_dec_inf_no_par)   ;
assign {data_out,addr_out}  = extract_ecc_data(ecc_cor_code)                        ;
endmodule