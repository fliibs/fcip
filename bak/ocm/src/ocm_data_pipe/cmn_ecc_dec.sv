module cmn_ecc_dec #(
    parameter  integer unsigned DATA_WIDTH    = 1024                                                                                                   ,
    localparam integer unsigned CODE_WIDTH    = ($clog2(DATA_WIDTH)+DATA_WIDTH+1 <= 2**$clog2(DATA_WIDTH))? $clog2(DATA_WIDTH) :$clog2(DATA_WIDTH) + 1 ,
    localparam integer unsigned TOTAL_WIDTH   = DATA_WIDTH + CODE_WIDTH + 1                                                                            ,
    localparam integer unsigned CODE_WIDTH_OH = 2**CODE_WIDTH
)(
    input  logic [TOTAL_WIDTH-1:0]  encode_data ,
    output logic [DATA_WIDTH-1:0]   data        ,
    output logic                    sb_err      ,
    output logic                    db_err      
);

logic [TOTAL_WIDTH-1:1]     dec_check_bits_array [CODE_WIDTH-1:0] ;
logic [CODE_WIDTH-1:0]      dec_check_bits                        ;
logic [CODE_WIDTH_OH-1:0]   dec_check_bits_ohot                   ;
logic                       dec_parity_bit                        ;
logic [TOTAL_WIDTH-1:1]     dec_data_extend_msk                   ;
    
logic                       enc_parity_bit                        ;
logic [CODE_WIDTH-1:0]      enc_check_bits                        ;
logic [DATA_WIDTH-1:0]      enc_data                              ;
logic [TOTAL_WIDTH-1:1]     enc_data_extend                       ;

assign {enc_data,enc_check_bits,enc_parity_bit} = encode_data   ;

genvar i,j;
generate for(i=1;i<TOTAL_WIDTH;i++) begin
    if(2**$clog2(i)==i) 
    assign enc_data_extend[i] = enc_check_bits[$clog2(i)];
    else
    assign enc_data_extend[i] = enc_data[i-$clog2(i)-1]  ;
    
end
endgenerate

generate for(i=0;i<CODE_WIDTH;i++) begin
    for(j=1;j<TOTAL_WIDTH;j++) begin
        if(|(j&(2**i)))
        assign dec_check_bits_array[i][j] = enc_data_extend[j];
        else
        assign dec_check_bits_array[i][j] = 1'b0              ; 
    end
    assign dec_check_bits[i] = |dec_check_bits_array[i];
end
endgenerate

assign dec_parity_bit = ^encode_data                        ;   
assign sb_err         =   dec_parity_bit                    ;
assign db_err         = (~dec_parity_bit) & |dec_check_bits ;

cmn_bin2onehot#(
    .BIN_WIDTH    (CODE_WIDTH   ),
    .ONEHOT_WIDTH (CODE_WIDTH_OH)
)u_cmn_bin2onehot(
    .bin_in      (dec_check_bits     ),
    .onehot_out  (dec_check_bits_ohot)
);

assign dec_data_extend_msk = dec_check_bits_ohot[TOTAL_WIDTH-1:1] ^ enc_data_extend;

generate for (i=1;i<TOTAL_WIDTH;i++) begin
    if(2**$clog2(i)!=i)
    assign data[i-$clog2(i)-1] = dec_data_extend_msk[i]     ;
end
endgenerate
endmodule