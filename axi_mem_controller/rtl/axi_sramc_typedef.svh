typedef struct packed {
    logic [AXI_ADDR_WIDTH-1:0]      addr;
    logic [AXI_ID_WIDTH-1:0]        id;
    logic [7:0]                     len;
    logic [2:0]                     size;
    logic [1:0]                     burst;
    logic [AXI_USER_WIDTH-1:0]      user;
} ax_pld_st;

typedef struct packed {
    logic                           last;
    logic [AXI_ID_WIDTH-1:0]        id;
    logic [AXI_USER_WIDTH-1:0]      user;
    logic [AXI_ADDR_WIDTH-1:0]      addr;
} tr_split_pld_st;


function automatic logic [AXI_ADDR_WIDTH-1:0] nxt_addr_calc(input logic [AXI_ADDR_WIDTH-1:0] addr, logic [7:0] len, input logic [2:0] size, input logic [1:0] burst);
    logic [AXI_ADDR_WIDTH-1:0] aligned_addr;
    logic [AXI_ADDR_WIDTH-1:0] wrap_boundary;
    logic [AXI_ADDR_WIDTH-1:0] upper_wrap_addr;
    logic [3:0]                wrap_shift;
    logic [AXI_ADDR_WIDTH:0]   addr_temp;
    logic [AXI_ADDR_WIDTH-1:0] axi_addr_calc;

    aligned_addr  = (addr >> size) << size;
    
    if (burst == 2'b10) begin
        if (len == 8'd2) begin
            wrap_shift = size + 3'd1;
        end else if (len == 8'd4) begin
            wrap_shift = size + 3'd2;
        end else if (len == 8'd8) begin
            wrap_shift = size + 3'd3;
        end else begin
            wrap_shift = size + 3'd4;
        end 
    end else begin
        wrap_shift = 4'b0;
    end
    
    if (burst == 2'b10) begin
        wrap_boundary   = (addr >> wrap_shift ) << wrap_shift;
        upper_wrap_addr = wrap_boundary + (16'b1 << wrap_shift);
    end else begin
        wrap_boundary   = {AXI_ADDR_WIDTH{1'b0}};
        upper_wrap_addr = {AXI_ADDR_WIDTH{1'b0}};
    end

    addr_temp =  aligned_addr + {8'b1 << size};

    // axi burst addr split
    if (burst == 2'b10 && addr_temp == upper_wrap_addr) begin
        axi_addr_calc = wrap_boundary[AXI_ADDR_WIDTH-1:0];
    end else if (burst == 2'b10 || burst == 2'b01) begin
        axi_addr_calc = addr_temp[AXI_ADDR_WIDTH-1:0];
    end else begin
        axi_addr_calc = addr;
    end
    
    // sram data width aligned
    if (AXI_DATA_WIDTH == 64) begin
        nxt_addr_calc = {axi_addr_calc[AXI_ADDR_WIDTH-1:3], 3'h0};
    end else (AXI_DATA_WIDTH == 128) begin
        nxt_addr_calc = {axi_addr_calc[AXI_ADDR_WIDTH-1:4], 4'h0};
    end else (AXI_DATA_WIDTH == 256) begin
        nxt_addr_calc = {axi_addr_calc[AXI_ADDR_WIDTH-1:5], 5'h0};
    end else begin
        nxt_addr_calc = {axi_addr_calc[AXI_ADDR_WIDTH-1:3], 3'h0};
    end

endfunction