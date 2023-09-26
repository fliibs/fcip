module hamming_secded_decoder#(
    parameter       INFO_WIDTH          =   256,

    //do NOT change below parameter, or use localparam at new version tools
    parameter      CHECK_WIDTH         =   ($clog2($clog2(INFO_WIDTH) + INFO_WIDTH) == $clog2(INFO_WIDTH)) ? $clog2(INFO_WIDTH) :  $clog2(INFO_WIDTH)+1,
    parameter      TOTAL_WIDTH         =   INFO_WIDTH + CHECK_WIDTH + 1,
    parameter      CHECK_1HOT_WIDTH    =   2**CHECK_WIDTH
)(
    input [TOTAL_WIDTH-1 : 0]       encoded_bits    , 
    
    output [INFO_WIDTH-1 : 0]       info_bits       ,
    output                          corr_err        , //correctable error
    output                          fatal_err       
); 
        

    logic                           org_parity_bit      ;
    logic                           new_parity_bit      ;
    logic                           dummy_parity_bit      ;
    logic                           parity_bit_result   ;

    logic [CHECK_WIDTH-1 : 0]       org_check_bits          ;
    logic [CHECK_WIDTH-1 : 0]       new_check_bits          ;
    logic [CHECK_WIDTH-1 : 0]       check_bits_result       ;
    logic [CHECK_1HOT_WIDTH-1 : 0]  check_bits_1hot_result  ;

    logic [INFO_WIDTH-1 : 0]        org_info_bits       ;
    logic [INFO_WIDTH-1 : 0]        dummy_info_bits     ;

    logic [TOTAL_WIDTH-1 : 1]       info_bits_extend        ;
    logic [TOTAL_WIDTH-1 : 1]       corr_info_bits_extend   ;

    genvar i;

    assign org_parity_bit   =   encoded_bits[TOTAL_WIDTH-1]                 ;
    assign org_check_bits   =   encoded_bits[TOTAL_WIDTH-2 : INFO_WIDTH]    ;
    assign org_info_bits    =   encoded_bits[INFO_WIDTH-1 : 0]              ;

    hamming_secded_encoder#(
        .INFO_WIDTH (INFO_WIDTH)    
    )u_hamming_checker(
        .info_bits              (org_info_bits                                  ),
        .encoded_bits           ({dummy_parity_bit,new_check_bits,dummy_info_bits}),
        .info_bits_extend       (info_bits_extend                               )
    );
    
    assign new_parity_bit       =   ^encoded_bits[TOTAL_WIDTH-2 : 0];

    assign parity_bit_result    =   new_parity_bit ^ org_parity_bit ;
    assign check_bits_result    =   new_check_bits ^ org_check_bits ;


    assign fatal_err  =  (~parity_bit_result && |(check_bits_result)) || (check_bits_result > TOTAL_WIDTH-1);

    assign corr_err   =   parity_bit_result && (check_bits_result <= TOTAL_WIDTH-1);

    
    bin2onehot #(
        .BIN_WIDTH(CHECK_WIDTH)  
    )u_check_1hot_result(
        .bin_in     (check_bits_result),
        .onehot_out (check_bits_1hot_result)
    );

    assign corr_info_bits_extend =   check_bits_1hot_result[TOTAL_WIDTH-1 : 1] ^ info_bits_extend   ;

    generate
        for(i=1;i<TOTAL_WIDTH;i=i+1) begin:get_info_out
            if(2**($clog2(i)) != i)
                assign info_bits[i-$clog2(i)-1] =   corr_info_bits_extend[i];
        end
    endgenerate


    

endmodule
