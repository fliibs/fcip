

package mem_fake_pack;

parameter integer unsigned MEM_ADDR_WIDTH = 8;
parameter integer unsigned MEM_DATA_WIDTH = 128;

typedef struct packed {
    logic [MEM_DATA_WIDTH-1:0] write_data;
    logic [MEM_ADDR_WIDTH-1:0] write_addr;
} mem_fake_write_req_t;

endpackage