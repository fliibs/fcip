typedef struct packed {
    logic [AXI_ADDR_WIDTH-1:0]      addr,
    logic [AXI_ID_WIDTH-1:0]        id,
    input logic [7:0]               len,
    input logic [2:0]               size,
    input logic [1:0]               burst,
    logic [AXI_USER_WIDTH-1:0]      user
} ax_pld_st;