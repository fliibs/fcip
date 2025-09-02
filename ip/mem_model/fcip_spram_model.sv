module fcip_spram_model #(
    parameter integer unsigned  ADDR_WIDTH      = 32    ,
    parameter integer unsigned  DATA_WIDTH      = 32
) (
    input  logic                     clk         ,

    input  logic                     en          ,
    input  logic [ADDR_WIDTH-1:0]    addr        ,
    output logic [DATA_WIDTH-1:0]    rd_data     ,
    input  logic [DATA_WIDTH-1:0]    wr_data     ,
    // input  logic [DATA_WIDTH/8-1:0]  wr_byte_en  ,
    input  logic                     wr_en       
);

    //logic [DATA_WIDTH-1:0] mem [0:1<<10-1];

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
    initial begin
        forever begin
            @(posedge clk)
            if(wr_en && en) begin
                memory[addr] <= wr_data;
            end
        end
    end

    // memory read handler =========================================================
    initial begin
        forever begin
            @(posedge clk)            
            if(en && ~wr_en) rd_data = read_memory(addr);
        end
    end
    



endmodule