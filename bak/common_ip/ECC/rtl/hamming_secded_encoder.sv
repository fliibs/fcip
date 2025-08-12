 module hamming_secded_encoder#(
    parameter      INFO_WIDTH    =   256,

    //do NOT change below parameter, or use localparam at new version tools
    parameter     CHECK_WIDTH   =   ($clog2($clog2(INFO_WIDTH) + INFO_WIDTH) == $clog2(INFO_WIDTH)) ? $clog2(INFO_WIDTH) :  $clog2(INFO_WIDTH)+1,
    parameter     TOTAL_WIDTH   =   INFO_WIDTH + CHECK_WIDTH + 1
)(
    input [INFO_WIDTH-1 : 0]        info_bits,
    
    output [TOTAL_WIDTH-1 : 0]      encoded_bits,       //{parity_check,hamming_check_bits,info_bits}
    output [TOTAL_WIDTH-1 : 1]      info_bits_extend    //only used in decoder
);

    logic                       parity_bit;
    //logic [TOTAL_WIDTH-1 : 1]   info_bits_extend; 
    logic [TOTAL_WIDTH-1 : 1]   check_bits_array [CHECK_WIDTH-1 : 0];
    logic [CHECK_WIDTH-1 : 0]   check_bits;

    genvar i,j;

    assign encoded_bits = {parity_bit,check_bits,info_bits};

    assign parity_bit = ^{check_bits,info_bits};

    generate
        for(i=1;i<TOTAL_WIDTH;i=i+1) begin: extend_info_bits
            if(2**($clog2(i)) == i)
                assign info_bits_extend[i]  =   1'b0;
            else
                assign info_bits_extend[i]  =   info_bits[i-$clog2(i)-1]; 
        end
    endgenerate

    generate
        for(i=0;i<CHECK_WIDTH;i=i+1) begin: check_bits_array_1st_stage
            for(j=1;j<TOTAL_WIDTH;j=j+1) begin: check_bits_array_2nd_stage
                if(j[i])
                    assign check_bits_array[i][j]   =   info_bits_extend[j] ;
                else
                    assign check_bits_array[i][j]   =   1'b0    ;
            end
            assign  check_bits[i]   =   ^check_bits_array[i]    ;
        end
    endgenerate 



endmodule
