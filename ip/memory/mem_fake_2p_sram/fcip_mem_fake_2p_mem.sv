module fcip_mem_fake_2p_mem 
#(
    parameter integer unsigned SRAM_ACCESS_LATENCY = 1,
    parameter integer unsigned SRAM_REQ_PIPE_STAGE = 0,
    parameter integer unsigned SRAM_RSP_PIPE_STAGE = 0,
    parameter integer unsigned SIDEBAND_WIDTH = 1,
    parameter integer unsigned DATA_WIDTH = 128,
    parameter integer unsigned ADDR_WIDTH = 10,
    parameter integer unsigned MCP_CYCLE = 1,
    parameter integer unsigned WRITE_BUFFER_SIZE = 4,
    parameter integer unsigned RW_ARBITER_TYPE = 0,  //0 read first,1 write first
    parameter integer unsigned READ_FORWARD_EN = 1,
    parameter integer unsigned READ_BUFFER_SIZE = 4,
    parameter integer unsigned WRITE_BIT_MASK_EN = 1
)(
    input  logic                        clk,
    input  logic                        rst_n,

    //write req
    input  logic                        write_req_vld,
    input  logic [DATA_WIDTH-1:0]       write_req_data,
    input  logic [ADDR_WIDTH-1:0]       write_req_addr,
    output logic                        write_req_rdy,
    input  logic [DATA_WIDTH-1:0]       write_req_bit_en,

    //read_req
    input  logic                        read_req_vld,
    input  logic [ADDR_WIDTH-1:0]       read_req_addr,
    input  logic [SIDEBAND_WIDTH-1:0]   read_req_sideband,
    output logic                        read_req_rdy,

    //read response
    output logic                        read_resp_vld,
    output logic [DATA_WIDTH-1:0]       read_resp_data,
    output logic [SIDEBAND_WIDTH-1:0]   read_resp_sideband,
    input  logic                        read_resp_rdy,

    //mem port
    output logic [ADDR_WIDTH-1:0]       spram_addr,
    input  logic [DATA_WIDTH-1:0]       spram_dout,
    output logic [DATA_WIDTH-1:0]       spram_din,
    output logic                        spram_en,
    output logic                        spram_wren,
    output logic [DATA_WIDTH -1 : 0]    spram_bit_en,

    //lowpower
    input  logic                        stall,
    input  logic                        clear,
    output logic                        idle
);

localparam int unsigned FIFO_THRESHOLD  = READ_BUFFER_SIZE-1;
localparam int unsigned MEM_LATENCY     = SRAM_ACCESS_LATENCY + SRAM_REQ_PIPE_STAGE + SRAM_RSP_PIPE_STAGE;

/*========================================*/
/*               write buffer             */
/*========================================*/

logic                        write_buffer_full;
logic                        write_buffer_empty;

logic                        write_sram_vld;
logic                        write_sram_rdy;
logic [DATA_WIDTH-1:0]       write_sram_data;
logic [ADDR_WIDTH-1:0]       write_sram_addr;
logic [DATA_WIDTH-1:0]       write_sram_bit_en;

logic                        read_cmp_vld;
logic [ADDR_WIDTH-1:0]       read_cmp_addr;

logic                        read_cmp_hit_delay;
logic [DATA_WIDTH-1:0]       read_hit_data_delay;
logic [DATA_WIDTH-1:0]       read_hit_data_bit_en_delay;

logic                        read_buffer_idle;
logic                        read_out_vld;
logic [DATA_WIDTH-1:0]       read_out_data;
logic [SIDEBAND_WIDTH-1:0]   read_out_sideband;
logic                        read_out_rdy;

logic                        read_buffer_full;
logic                        read_buffer_empty;
logic                        fifo_almost_full;

logic                        mem_req_vld;
logic                        mem_req_rdy;
logic                        mem_req_opcode;
logic [ADDR_WIDTH-1:0]       mem_req_addr;
logic [DATA_WIDTH-1:0]       mem_req_data;
logic [DATA_WIDTH-1:0]       mem_req_bit_en;
logic [SIDEBAND_WIDTH-1:0]   mem_req_sideband;

logic                        mem_rsp_en;
logic [SIDEBAND_WIDTH-1:0]   mem_rsp_sideband;
logic [DATA_WIDTH-1:0]       mem_rsp_data;

logic                                   read_buffer_in_vld;
logic [DATA_WIDTH+SIDEBAND_WIDTH-1:0]   read_buffer_in_pld;
logic                                   read_buffer_in_rdy;

logic                                   read_buffer_out_vld;
logic [DATA_WIDTH+SIDEBAND_WIDTH-1:0]   read_buffer_out_pld;
logic                                   read_buffer_out_rdy;

generate 
    if(WRITE_BUFFER_SIZE == 0)begin
        
        assign write_sram_vld   = write_req_vld;
        assign write_sram_data  = write_req_data;
        assign write_sram_addr  = write_req_addr;
        assign write_req_rdy    = write_sram_rdy;

    end else begin
        fcip_mem_fake_write_buffer #(
            .ADDR_WIDTH         (ADDR_WIDTH),
            .DATA_WIDTH         (DATA_WIDTH),
            .WRITE_BUFFER_SIZE  (WRITE_BUFFER_SIZE),
            .MEM_LATENCY        (MEM_LATENCY),
            .WRITE_BIT_MASK_EN  (WRITE_BIT_MASK_EN)
        ) u_mem_fake_write_buffer(
            .clk                    (clk             ),
            .rst_n                  (rst_n           ),

            .write_req_vld          (write_req_vld   ),
            .write_req_data         (write_req_data  ),
            .write_req_addr         (write_req_addr  ),
            .write_req_rdy          (write_req_rdy   ),
            .write_req_bit_en       (write_req_bit_en),

            .buffer_full            (write_buffer_full  ),
            .buffer_empty           (write_buffer_empty ),

            .write_buffer_vld       (write_sram_vld     ),
            .write_buffer_rdy       (write_sram_rdy     ),
            .write_buffer_data      (write_sram_data    ),
            .write_buffer_addr      (write_sram_addr    ),
            .write_buffer_bit_en    (write_sram_bit_en  ),

            .clear                  (clear           ),
            .stall                  (stall           ),

            .read_cmp_vld           (read_cmp_vld    ),
            .read_cmp_addr          (read_cmp_addr   ),
            .read_cmp_hit_delay     (read_cmp_hit_delay ),
            .read_hit_data_delay    (read_hit_data_delay),
            .read_hit_data_bit_en_delay(read_hit_data_bit_en_delay)
    );
    end
endgenerate

/*========================================*/
/*             Read req arbiter           */
/*========================================*/

generate 
    if(RW_ARBITER_TYPE==1)begin:MEM_FAKE_WRIST_FIRST
        
        assign read_req_rdy         = ~(fifo_almost_full || stall) && read_out_rdy && mem_req_rdy && ~write_sram_vld;
        assign write_sram_rdy       = mem_req_rdy;

        assign mem_req_addr         = write_sram_vld ? write_sram_addr : read_req_addr;
        assign mem_req_data         = write_sram_data;
        assign mem_req_vld          = (read_req_vld && read_req_rdy) || (write_sram_vld && write_sram_rdy);
        assign mem_req_opcode       = write_sram_vld ? 1'b1 : 1'b0 ;//wren
        assign mem_req_sideband     = read_req_sideband;
        assign mem_req_bit_en       = write_sram_bit_en;
 
    end else begin:MEM_FAKE_READ_FIRST

        assign read_req_rdy         = ~(fifo_almost_full || stall) && read_out_rdy && mem_req_rdy;
        assign write_sram_rdy       = ~read_req_vld && mem_req_rdy;

        assign mem_req_addr         = read_req_vld ? read_req_addr : write_sram_addr;
        assign mem_req_data         = write_sram_data;
        assign mem_req_vld          = (read_req_vld && read_req_rdy) || (write_sram_vld && write_sram_rdy);
        assign mem_req_opcode       = read_req_vld ? 1'b0 : write_sram_vld;//wren
        assign mem_req_sideband     = read_req_sideband;
        assign mem_req_bit_en       = write_sram_bit_en;

        assign read_cmp_vld         = read_req_vld && read_req_rdy;
        assign read_cmp_addr        = read_req_addr;

    end
endgenerate

generate
    if(WRITE_BUFFER_SIZE == 0) begin

        assign read_out_vld         = mem_rsp_en;
        assign read_out_data        = mem_rsp_data;
        assign read_out_sideband    = mem_rsp_sideband;

    end else if(WRITE_BIT_MASK_EN == 0)begin

        assign read_out_vld         = mem_rsp_en;
        
        assign read_out_data        = read_cmp_hit_delay ? read_hit_data_delay : mem_rsp_data;
        assign read_out_sideband    = mem_rsp_sideband;

    end else begin

        logic [DATA_WIDTH-1:0]  rsp_vld_data;
        logic [DATA_WIDTH-1:0]  data_merge;

        assign read_out_vld         = mem_rsp_en;
        assign rsp_vld_data         = mem_rsp_data & ~read_hit_data_bit_en_delay;
        assign data_merge           = rsp_vld_data | read_hit_data_delay;
        
        assign read_out_data        = read_cmp_hit_delay ? data_merge : mem_rsp_data;
        assign read_out_sideband    = mem_rsp_sideband;
    end
endgenerate

/*========================================*/
/*                ECC decode              */
/*========================================*/

//add future

/*========================================*/
/*              Memory Wrapper            */
/*========================================*/

fcip_mem_ctrl_wrap #(
        .SRAM_ACCESS_LATENCY(SRAM_ACCESS_LATENCY),
        .SRAM_REQ_PIPE_STAGE(SRAM_REQ_PIPE_STAGE),
        .SRAM_RSP_PIPE_STAGE(SRAM_RSP_PIPE_STAGE),
        .SIDEBAND_WIDTH(SIDEBAND_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MCP_CYCLE(MCP_CYCLE)
    )u_fifo_spram_mem_ctrl(
        .clk                 (clk             ),
        .rst_n               (rst_n           ),
        .mem_req_vld         (mem_req_vld     ),
        .mem_req_rdy         (mem_req_rdy     ),
        .mem_req_opcode      (mem_req_opcode  ),
        .mem_req_addr        (mem_req_addr    ),
        .mem_req_data        (mem_req_data    ),
        .mem_req_bit_en      (mem_req_bit_en  ),
        .mem_req_sideband    (mem_req_sideband),

        .mem_rsp_en          (mem_rsp_en      ),
        .mem_rsp_sideband    (mem_rsp_sideband),
        .mem_rsp_data        (mem_rsp_data    ),
        
        .spram_addr          (spram_addr      ),
        .spram_din           (spram_din       ),
        .spram_dout          (spram_dout      ),
        .spram_en            (spram_en        ),
        .spram_wren          (spram_wren      ),
        .spram_bit_en        (spram_bit_en    )
);

/*========================================*/
/*              Sync fifo                 */
/*========================================*/

fcip_sync_fifo_reg #(
    .FIFO_DEPTH(READ_BUFFER_SIZE),
    .FIFO_WIDTH(DATA_WIDTH+SIDEBAND_WIDTH),
    .ALMOST_FULL_THRESHOLD (READ_BUFFER_SIZE-MEM_LATENCY),
    .ALMOST_EMPTY_THRESHOLD(FIFO_THRESHOLD),
    .FORWARD_EN(0)
) u_sync_fifo(
    .clk                (clk),
    .rst_n              (rst_n),

    .stall              (stall),
    .clear              (clear),
    .idle               (read_buffer_idle),

    .write_req_vld      (read_buffer_in_vld ),
    .write_req_pld      (read_buffer_in_pld ),
    .write_req_rdy      (read_buffer_in_rdy),

    .read_resp_vld      (read_buffer_out_vld),
    .read_resp_pld      (read_buffer_out_pld),
    .read_resp_rdy      (read_buffer_out_rdy),

    .almost_full        (fifo_almost_full),
    .almost_empty       (),
    .empty              (read_buffer_empty),
    .full               (read_buffer_full)
);

generate
    if(READ_FORWARD_EN)begin

        logic forward_enable;

        assign forward_enable       = read_resp_rdy && read_buffer_empty;

        assign read_buffer_in_vld   = read_out_vld && ~forward_enable;
        assign read_buffer_in_pld   = {read_out_sideband,read_out_data};
        assign read_out_rdy         = read_buffer_in_rdy;

        assign read_resp_vld        = forward_enable ? read_out_vld      : read_buffer_out_vld;
        assign read_resp_data       = forward_enable ? read_out_data     : read_buffer_out_pld[DATA_WIDTH-1:0];
        assign read_resp_sideband   = forward_enable ? read_out_sideband : read_buffer_out_pld[DATA_WIDTH+SIDEBAND_WIDTH-1 : DATA_WIDTH];
        assign read_buffer_out_rdy  = read_resp_rdy;

    end else begin

        assign read_buffer_in_vld   = read_out_vld;
        assign read_buffer_in_pld   = {read_out_sideband,read_out_data};
        assign read_out_rdy         = read_buffer_in_rdy;
        
        assign read_resp_vld        = read_buffer_out_vld;
        assign read_resp_data       = read_buffer_out_pld[DATA_WIDTH-1:0];
        assign read_resp_sideband   = read_buffer_out_pld[DATA_WIDTH+SIDEBAND_WIDTH-1 : DATA_WIDTH];
        assign read_buffer_out_rdy  = read_resp_rdy;

    end
endgenerate

assign idle             = read_buffer_idle && write_buffer_empty;

endmodule