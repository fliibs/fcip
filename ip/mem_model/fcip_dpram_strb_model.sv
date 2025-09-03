module fcip_dpram_strb_model #(
    parameter integer unsigned  ADDR_WIDTH      = 32    ,
    parameter integer unsigned  DATA_WIDTH      = 32    ,
    parameter integer unsigned  STRB_WIDTH      = DATA_WIDTH/8
) (
    input  logic                     clk         ,

    input  logic                     rd_en       ,
    input  logic [ADDR_WIDTH-1:0]    rd_addr     ,
    output logic [DATA_WIDTH-1:0]    rd_data     ,
    
    input  logic                     wr_en       ,
    input  logic [ADDR_WIDTH-1:0]    wr_addr     ,
    input  logic [DATA_WIDTH-1:0]    wr_data     ,
    input  logic [STRB_WIDTH-1:0]    wr_strb    
);

    typedef logic [ADDR_WIDTH-1:0]    logic_addr   ;
    typedef logic [DATA_WIDTH-1:0]    logic_data   ;


    logic_data              memory[logic_addr]    ;

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

    // memory write handler ========================================================
    // initial begin
    //     forever begin
    //         @(posedge clk)
    //         if(wr_en) begin
    //             memory[wr_addr] <= wr_data;
    //         end
    //     end
    // end
    logic   [DATA_WIDTH-1:0]   tmp_data;
    initial begin
        forever begin
            @(posedge clk)
            if(wr_en) begin
                for(int i=0;i<STRB_WIDTH;i=i+1)begin
                    if(wr_strb[i]) tmp_data[8*i+:8] = wr_data[8*i+:8];
                end
                // if(wr_byte_en[0]) tmp_data[7 : 0] = wr_data[7 : 0];
                // if(wr_byte_en[1]) tmp_data[15: 8] = wr_data[15: 8];
                // if(wr_byte_en[2]) tmp_data[23:16] = wr_data[23:16];
                // if(wr_byte_en[3]) tmp_data[31:24] = wr_data[31:24];
                memory[wr_addr] <= tmp_data;
            end
        end
    end

    // memory read handler =========================================================
    initial begin
        forever begin
            @(posedge clk)            
            if(rd_en) rd_data = read_memory(rd_addr);
        end
    end
    
    

endmodule