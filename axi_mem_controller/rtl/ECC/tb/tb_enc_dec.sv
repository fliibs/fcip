module tb_enc_dec;


    localparam      INFO_WIDTH  =   999 ;
    localparam      CHECK_WIDTH         =   ($clog2($clog2(INFO_WIDTH) + INFO_WIDTH) == $clog2(INFO_WIDTH)) ? $clog2(INFO_WIDTH) :  $clog2(INFO_WIDTH)+1;
    localparam      TOTAL_WIDTH         =   INFO_WIDTH + CHECK_WIDTH + 1;


    logic                       clk                     ;
    logic                       rst_n                   ;

    logic [INFO_WIDTH-1 : 0]    info_bits               ;
    logic [TOTAL_WIDTH-1 : 0]   encoded_bits            ;
    logic [TOTAL_WIDTH-1 : 0]   inject_err_encoded_bits ;
    logic [TOTAL_WIDTH+1 : 0]   error_pattern           ;

    logic [INFO_WIDTH-1 : 0]    corr_info_bits          ;
    logic                       corr_error              ;
    logic                       fatal_error             ;

    logic                       check_result            ;


    assign check_result         =  ~|(info_bits ^ corr_info_bits) || fatal_error;

    always #1 clk = ~clk    ;

    initial begin
        clk = 1'b0;
        std::randomize(info_bits);
        rst_n = 1'b0;
        #100;
        rst_n = 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)
            error_pattern <= {2'b10,{TOTAL_WIDTH{1'b0}}};
        else
            error_pattern <= {error_pattern[TOTAL_WIDTH-1:0],error_pattern[TOTAL_WIDTH+1]};
    end 


    assign inject_err_encoded_bits = error_pattern[TOTAL_WIDTH] ? (encoded_bits ^ 5'b01010) : //uncorrectable error
                                                                            encoded_bits ^ error_pattern[TOTAL_WIDTH-1 : 0]   ; //when error_pattern[TOTAL_WIDTH+1] == 1, non error injected, others, 1bit error;

    hamming_secded_encoder#(
        .INFO_WIDTH         (INFO_WIDTH     )
    )u_encoder(
        .info_bits          (info_bits      ),

        .encoded_bits       (encoded_bits   ),
        .info_bits_extend   () //open
    );
    

    hamming_secded_decoder#(
        .INFO_WIDTH         (INFO_WIDTH     )
    )u_decoder(        
        .encoded_bits       (inject_err_encoded_bits   ),

        .info_bits          (corr_info_bits),
        .corr_err         (corr_error     ),
        .fatal_err        (fatal_error    )
    );


    initial begin

        $fsdbDumpfile("test.fsdb");      
        $fsdbDumpvars(0,tb_enc_dec);
        $fsdbDumpMDA();
    end


    always @(posedge clk) begin
        if(error_pattern == {2'b01,{TOTAL_WIDTH{1'b0}}}) begin
            @ clk;
            @ clk;
            @ clk;

            $finish;
        end
    end

endmodule
