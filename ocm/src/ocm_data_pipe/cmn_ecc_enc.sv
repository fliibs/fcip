module cmn_ecc_enc #(
    parameter  integer unsigned DATA_WIDTH  = 1024                                                                                                   ,
    localparam integer unsigned CODE_WIDTH  = ($clog2(DATA_WIDTH)+DATA_WIDTH+1 <= 2**$clog2(DATA_WIDTH))? $clog2(DATA_WIDTH) :$clog2(DATA_WIDTH) + 1 ,
    localparam integer unsigned TOTAL_WIDTH = DATA_WIDTH + CODE_WIDTH + 1
)(
    input  logic [DATA_WIDTH-1:0]   data        ,
    output logic [TOTAL_WIDTH-1:0]  encode_data
);

logic [TOTAL_WIDTH-1:1] check_bits_array [CODE_WIDTH-1:0]       ;
logic                   parity_bit                              ;
logic [CODE_WIDTH-1:0]  check_bits                              ;


logic [TOTAL_WIDTH-1:1] data_bits_extend                        ;

assign parity_bit = ^{data,check_bits};

genvar i,j;
generate for(i=1;i<TOTAL_WIDTH;i++) begin
    if(2**$clog2(i)==i) 
        assign data_bits_extend[i] =   1'b0                 ;
    else                
        assign data_bits_extend[i] =   data[i-$clog2(i)-1]  ;
end
endgenerate

generate for(i=0;i<CODE_WIDTH;i++) begin
    for(j=1;j<TOTAL_WIDTH;j++) begin
        if(|(j&(2**i))) assign check_bits_array[i][j] = data_bits_extend[j];
        else            assign check_bits_array[i][j] = 1'b0               ;
    end
    assign check_bits[i] = ^check_bits_array[i];
end
endgenerate

assign encode_data = {data,check_bits,parity_bit};
endmodule