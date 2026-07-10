module fcip_dpram_model #(
    parameter string            ARGPARSE_KEY    = "HEX" ,
    parameter integer unsigned  ALLOW_NO_HEX    = 1     ,
    parameter integer unsigned  ADDR_WIDTH      = 32    ,
    parameter integer unsigned  DATA_WIDTH      = 32
) (
    input  logic                     clk         ,

    input  logic                     rd_en       ,
    input  logic [ADDR_WIDTH-1:0]    rd_addr     ,
    output logic [DATA_WIDTH-1:0]    rd_data     ,
    
    input  logic                     wr_en       ,
    input  logic [DATA_WIDTH-1:0]    wr_bit_en   ,
    input  logic [ADDR_WIDTH-1:0]    wr_addr     ,
    input  logic [DATA_WIDTH-1:0]    wr_data     
);

    typedef logic [ADDR_WIDTH-1:0]    logic_addr   ;
    typedef logic [DATA_WIDTH-1:0]    logic_data   ;


    logic_data              memory[logic_addr]      ;
    logic_data              tmp_data                ;
    string                  arg_parse_str           ;
    string                  code_path               ;


    function logic_data read_memory(logic_addr address);
        logic_data data;

        if (memory.exists(address)) begin
            data = memory[address];
        end else begin
            memory[address] = {DATA_WIDTH{1'b0}};
            data = {DATA_WIDTH{1'b0}}; 
        end

        return data;
    endfunction

    // memory initialize ===========================================================
    initial begin
        $sformat(arg_parse_str, "%s=%%s", ARGPARSE_KEY);
        
        if($value$plusargs(arg_parse_str, code_path)) begin
            $readmemh(code_path, memory);
            if($test$plusargs("DEBUG")) begin
                $display("print memory first 10 row parse from arg %s:", ARGPARSE_KEY);
                for(int i=0;i<10;i++) begin
                    $display("memory row[%0d] = %h" , i, read_memory(logic_addr'(i)));
                end
            end
        end else begin
            if(ALLOW_NO_HEX!=0) begin
                if($test$plusargs("DEBUG"))
                    $info("Missing required parameter +%s",ARGPARSE_KEY);
            end
            else begin
                $error("Missing required parameter +%s",ARGPARSE_KEY);
                $finish;
            end
        end
    end
    // memory write handler ========================================================
    always @(posedge clk) begin
        if(wr_en) begin
            tmp_data = read_memory(wr_addr);
            tmp_data = (tmp_data & ~wr_bit_en) | (wr_data & wr_bit_en);
            memory[wr_addr] = tmp_data;
        end
    end

    
    // memory read handler =========================================================
    always @(posedge clk) begin
        if(rd_en) rd_data <= read_memory(rd_addr);
    end

    // debug =======================================================================
    initial begin
        if($test$plusargs("DEBUG")) begin
            forever begin
                @(posedge clk)
                if(rd_en)
                    $display("[%s][rd] %h : %h", ARGPARSE_KEY, rd_addr, read_memory(rd_addr));
                if(wr_en)
                    $display("[%s][wr] %h : %h", ARGPARSE_KEY, wr_addr, wr_data);
            end
        end
    end


endmodule