module fcip_mem_fake_write_buffer 
#(  parameter integer unsigned ADDR_WIDTH = 8,
    parameter integer unsigned DATA_WIDTH = 128,
    parameter integer unsigned WRITE_BUFFER_SIZE =16 ,
    parameter integer unsigned MEM_LATENCY = 1,
    parameter integer unsigned WRITE_BIT_MASK_EN =1
)(
    input  logic                        clk,
    input  logic                        rst_n,

    //write req
    input  logic                        write_req_vld,
    input  [DATA_WIDTH-1:0]             write_req_data,
    input  [ADDR_WIDTH-1:0]             write_req_addr,
    output logic                        write_req_rdy,
    input  [DATA_WIDTH-1:0]             write_req_bit_en,

    //control
    output logic                        buffer_full,
    output logic                        buffer_empty,

    output logic                        write_buffer_vld,
    input  logic                        write_buffer_rdy,
    output logic [DATA_WIDTH-1:0]       write_buffer_data,
    output logic [ADDR_WIDTH-1:0]       write_buffer_addr,
    output logic [DATA_WIDTH-1:0]       write_buffer_bit_en,

    input  logic                        clear,
    input  logic                        stall,

    //compare
    input  logic                        read_cmp_vld,
    input  logic [ADDR_WIDTH-1:0]       read_cmp_addr,

    output logic                        read_cmp_hit_delay,
    output logic [DATA_WIDTH-1:0]       read_hit_data_delay,
    output logic [DATA_WIDTH-1:0]       read_hit_data_bit_en_delay
);

localparam CNT_WIDTH = $clog2(WRITE_BUFFER_SIZE);

typedef struct packed {
    logic [DATA_WIDTH-1:0] write_data;
    logic [ADDR_WIDTH-1:0] write_addr;
    logic [DATA_WIDTH-1:0] write_bit_en;
} mem_fake_write_req_t;

logic [CNT_WIDTH-1:0]           prealloc_entry;
logic [WRITE_BUFFER_SIZE-1:0]   prealloc_entry_onehot;
logic                           write_handshake;
logic                           rel_write_entry;

logic [CNT_WIDTH:0]             wr_ptr;
logic [CNT_WIDTH:0]             rd_ptr;
logic [CNT_WIDTH-1:0]           wr_ptr_true;
logic [CNT_WIDTH-1:0]           rd_ptr_true;
logic                           wr_ptr_msb;
logic                           rd_ptr_msb;
logic                           full;
logic                           empty;

logic [WRITE_BUFFER_SIZE-1:0]   cmp_hit_onehot;
mem_fake_write_req_t            write_array_data_sel;

mem_fake_write_req_t            write_req_pld;
mem_fake_write_req_t            write_array_data[WRITE_BUFFER_SIZE-1:0];
logic [WRITE_BUFFER_SIZE-1:0]   write_array_vld;

logic                           read_cmp_vld_1d;
logic [ADDR_WIDTH-1:0]          read_cmp_addr_1d;

/*========================================*/
/*                prealloc                */
/*========================================*/

assign write_req_rdy    = ~(full || stall);

assign write_handshake  = write_req_vld && write_req_rdy;
assign prealloc_entry   = wr_ptr_true;

assign buffer_empty     = empty;
assign buffer_full      = full;

/*========================================*/
/*           Write Trans counter          */
/*========================================*/

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        rd_ptr <= 'b0;
    else if(clear)
        rd_ptr <= 'b0;
    else if(rel_write_entry)
        rd_ptr <= rd_ptr + 1'b1;
end

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        wr_ptr <= 'b0;
    else if(clear)
        wr_ptr <= 'b0;
    else if(write_handshake)
        wr_ptr <= wr_ptr + 1'b1;
end

assign {wr_ptr_msb,wr_ptr_true} = wr_ptr;
assign {rd_ptr_msb,rd_ptr_true} = rd_ptr;

assign full     = (rd_ptr_true == wr_ptr_true) && (wr_ptr_msb != rd_ptr_msb);
assign empty    = (rd_ptr == wr_ptr);

/*========================================*/
/*               Write Entry              */
/*========================================*/

assign write_req_pld.write_bit_en   = write_req_bit_en;
assign write_req_pld.write_data     = write_req_data;
assign write_req_pld.write_addr     = write_req_addr;

generate
    for(genvar i=0; i<WRITE_BUFFER_SIZE ; i++ )begin
        always_ff @( posedge clk or negedge rst_n ) begin : DATA_ARRAY
            if(~rst_n)
                write_array_data[i] <= 'b0;
            else if(clear)
                write_array_data[i] <= 'b0;
            else if( (prealloc_entry == i) && write_handshake)
                write_array_data[i] <= write_req_pld;
        end

        always_ff @( posedge clk or negedge rst_n ) begin : VALID_ARRAY
            if(~rst_n)
                write_array_vld[i] <= 'b0;
            else if(clear)
                write_array_vld[i] <= 'b0;
            else if( rel_write_entry && (rd_ptr==i) )
                write_array_vld[i] <= 'b0;
            else if( (prealloc_entry == i) && write_handshake )
                write_array_vld[i] <= 1'b1;
        end
    end
endgenerate

/*========================================*/
/*               Write req                */
/*========================================*/

assign write_buffer_vld        = ~empty;
assign write_buffer_data       = write_array_data[rd_ptr_true].write_data;
assign write_buffer_addr       = write_array_data[rd_ptr_true].write_addr;
assign write_buffer_bit_en     = write_array_data[rd_ptr_true].write_bit_en;
assign rel_write_entry         = ~empty && write_buffer_rdy;

/*========================================*/
/*   Comparator Array and hazard check    */
/*========================================*/

//bit enable
logic                        read_cmp_hit;
logic [DATA_WIDTH-1:0]       read_hit_data;
logic [DATA_WIDTH-1:0]       read_hit_data_bit_en;

always_ff @( posedge clk ) begin
    read_cmp_vld_1d  <= read_cmp_vld;
    read_cmp_addr_1d <= read_cmp_addr;
end

generate

    logic [DATA_WIDTH-1:0] cmp_array_data[WRITE_BUFFER_SIZE-1:0];
        logic [ADDR_WIDTH-1:0] cmp_array_addr[WRITE_BUFFER_SIZE-1:0];
        logic [DATA_WIDTH-1:0] cmp_array_bit_en[WRITE_BUFFER_SIZE-1:0];

        for(genvar i=0;i<WRITE_BUFFER_SIZE;i++)begin
            assign cmp_array_data[i]   = write_array_data[i].write_data;
            assign cmp_array_addr[i]   = write_array_data[i].write_addr;
            assign cmp_array_bit_en[i] = write_array_data[i].write_bit_en;
        end

    if(WRITE_BIT_MASK_EN)begin:WRITE_BIT_MASK

        fcip_mem_fake_find_new_bit #(
            .ADDR_WIDTH (ADDR_WIDTH),
            .DATA_WIDTH (DATA_WIDTH),
            .WRITE_BUFFER_SIZE(WRITE_BUFFER_SIZE),
            .PTR_WIDTH(CNT_WIDTH)
        ) u_mem_fake_find_new_bit(
            .cmp_vld            (read_cmp_vld_1d      ),
            .cmp_addr           (read_cmp_addr_1d     ),
            .cmp_array_data     (cmp_array_data       ),
            .cmp_array_addr     (cmp_array_addr       ),
            .cmp_array_bit_en   (cmp_array_bit_en     ),
            .array_vld          (write_array_vld ),
            .wr_ptr             (wr_ptr_true     ),

            .cmp_hit            (read_cmp_hit),
            .cmp_hit_data       (read_hit_data),
            .cmp_hit_bit_en     (read_hit_data_bit_en)
        );

    end else begin

        logic [WRITE_BUFFER_SIZE-1:0]   mask_en;
        logic [WRITE_BUFFER_SIZE-1:0]   hazard_check[1:0];
        logic [WRITE_BUFFER_SIZE-1:0]   hazard_onehot[1:0];
        logic [1:0]                     hazard_en;
        logic                           multi_hit_en;
        logic [WRITE_BUFFER_SIZE-1:0]   multi_hit_addr_onehot;
        logic [WRITE_BUFFER_SIZE-1:0]   array_data_switch[DATA_WIDTH-1:0];

        assign hazard_check[0]      = cmp_hit_onehot & mask_en;    //forward wptr hazard check
        assign hazard_check[1]      = cmp_hit_onehot & (~mask_en); // backward wptr hazard check

        assign multi_hit_en         = hazard_en[0] | hazard_en[1];
        assign multi_hit_addr_onehot= hazard_en[0] ? hazard_onehot[0] : hazard_onehot[1];

        for(genvar i=0;i<DATA_WIDTH;i++)begin:LOOP_FOR_BIT
            for(genvar j=0;j<WRITE_BUFFER_SIZE;j++)begin:LOOP_FOR_BUFFER_SIZE
                assign array_data_switch[i][j] = cmp_array_data[j][i];
            end
        end

        for(genvar j=0; j<WRITE_BUFFER_SIZE; j++ )begin
            assign cmp_hit_onehot[j]    = read_cmp_vld_1d && (read_cmp_addr_1d == write_array_data[j].write_addr) && write_array_vld[j];
            assign mask_en[j]           = (j<=(WRITE_BUFFER_SIZE'(wr_ptr-1))); 
        end 

        for(genvar i=0;i<DATA_WIDTH;i++)begin:SEL_READ_HIT_BIT
            assign read_hit_data[i] = |(array_data_switch[i] & multi_hit_addr_onehot); 
        end
        
        for(genvar i=0;i<2;i++)begin
            fcip_lead_one_msb #(
                .ENTRY_NUM      (WRITE_BUFFER_SIZE   )
            ) u_hazard_multibit(
                .v_entry_vld    (hazard_check[i]      ),
                .v_free_idx_oh  (hazard_onehot[i]    ),
                .v_free_idx_bin (        ),
                .v_free_vld     (hazard_en[i]         )
            );
        end

        assign read_cmp_hit         = |cmp_hit_onehot;
        assign read_hit_data_bit_en = {(DATA_WIDTH){1'b1}};
    end

endgenerate

/*========================================*/
/*                Data pipe               */
/*========================================*/

generate 
    if(MEM_LATENCY==1)begin
        
        assign read_cmp_hit_delay           = read_cmp_hit;
        assign read_hit_data_delay          = read_hit_data;
        assign read_hit_data_bit_en_delay   = read_hit_data_bit_en;

    end else begin
    
    fcip_data_pipe #(
        .DATA_WIDTH  (1),
        .PIPE_STAGE  (MEM_LATENCY-1), // must upper than 1
        .VT_TYPE     (0) // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
    ) u_read_cmp_vld_pipe(
        .clk         (clk  ),
        .rst_n       (rst_n),
        .d           (read_cmp_hit),
        .q           (read_cmp_hit_delay)
    );

    fcip_data_pipe #(
        .DATA_WIDTH  (DATA_WIDTH),
        .PIPE_STAGE  (MEM_LATENCY-1), // must upper than 1
        .VT_TYPE     (0) // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
    ) u_read_hit_data_pipe(
        .clk         (clk  ),
        .rst_n       (rst_n),
        .d           (read_hit_data),
        .q           (read_hit_data_delay)
    );

    fcip_data_pipe #(
        .DATA_WIDTH  (DATA_WIDTH),
        .PIPE_STAGE  (MEM_LATENCY-1), // must upper than 1
        .VT_TYPE     (0) // 0: LVT, 1: SVT, 2: ULVT, 7: LVTLL, 8: ULVTLL
    ) u_read_hit_data_bit_en_pipe(
        .clk         (clk  ),
        .rst_n       (rst_n),
        .d           (read_hit_data_bit_en),
        .q           (read_hit_data_bit_en_delay)
    );
    end
endgenerate

endmodule