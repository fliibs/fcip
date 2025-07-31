module mem_fake_write_buffer 
    import mem_pack::*;
#(
    parameter integer unsigned MEM_DEPTH = 256,
    parameter integer unsigned MEM_ADDR_WIDTH = 8,
    parameter integer unsigned MEM_DATA_WIDTH = 128,
    parameter integer unsigned WRITE_BUFFER_DEPTH =16 
)(
    input  logic                        clk,
    input  logic                        rst_n,

    //write req
    input  logic                        write_req_vld,
    input  mem_write_req_t              write_req_pld,
    output logic                        write_req_rdy,

    //control
    output logic                        buffer_full,
    output logic                        buffer_empty,

    output logic                        write_vld,
    input  logic                        write_rdy,
    output mem_write_req_t              write_pld,

    //compare
    input  logic                        read_cmp_vld,
    input  logic [MEM_ADDR_WIDTH-1:0]   read_cmp_addr,

    output logic                        read_cmp_hit,
    output logic [MEM_DATA_WIDTH-1:0]   read_buffer_data
);

localparam CNT_WIDTH = $clog2(WRITE_BUFFER_DEPTH);

logic [CNT_WIDTH-1:0]           prealloc_entry;
logic [WRITE_BUFFER_DEPTH-1:0]  prealloc_entry_onehot;
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

logic                           read_cmp_vld_1d;
logic [WRITE_BUFFER_DEPTH-1:0]  cmp_hit_onehot;
mem_write_req_t                 write_array_data_sel;
logic [WRITE_BUFFER_DEPTH-1:0]  mask_en;
logic [WRITE_BUFFER_DEPTH-1:0]  hazard_check[1:0];
logic [CNT_WIDTH-1:0]           hazard_bin[1:0];
logic [1:0]                     hazard_en;
logic                           multi_hit_en;
logic [CNT_WIDTH-1:0]           multi_hit_addr_index;

mem_write_req_t                 write_array_data[WRITE_BUFFER_DEPTH-1:0];
logic [WRITE_BUFFER_DEPTH-1:0]  write_array_vld;

//logic [WRITE_BUFFER_DEPTH-1:0]  alloc_entry;

/*========================================*/
/*                prealloc                */
/*========================================*/

assign write_req_rdy    = ~full;

assign write_handshake  = write_req_vld && write_req_rdy;
assign prealloc_entry   = wr_ptr;

assign buffer_empty     = empty;

/*========================================*/
/*           Write Trans counter          */
/*========================================*/

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        rd_ptr <= 'b0;
    else if(rel_write_entry)
        rd_ptr <= rd_ptr + 1'b1;
end

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        wr_ptr <= 'b0;
    else if(write_handshake)
        wr_ptr <= wr_ptr + 1'b1;
end

assign {wr_ptr_msb,wr_ptr_true} = wr_ptr;
assign {rd_ptr_msb,rd_ptr_true} = rd_ptr;

assign full     = (rd_ptr_true == wr_ptr_true) && (wr_ptr_msb != rd_ptr_msb);
assign empty    = (rd_ptr == wr_ptr);

/*========================================*/
/*           Alloc pointer decode         */
/*========================================*/

bin2onehot #(
    .ONEHOT_WIDTH (WRITE_BUFFER_DEPTH)
)u_write_ptr_onehot(
    .bin_in     (prealloc_entry),
    .onehot_out (prealloc_entry_onehot)
);

/*========================================*/
/*               Write Entry              */
/*========================================*/

generate
    for(genvar i=0; i<WRITE_BUFFER_DEPTH ; i++ )begin
        always_ff @( posedge clk or negedge rst_n ) begin : DATA_ARRAY
            if(~rst_n)
                write_array_data[i] <= 'b0;
            else if( (prealloc_entry_onehot[i]==1) && write_handshake)
                write_array_data[i] <= write_req_pld;
        end

        always_ff @( posedge clk or negedge rst_n ) begin : VALID_ARRAY
            if(~rst_n)
                write_array_vld[i] <= 'b0;
            else if( rel_write_entry && (rd_ptr==i))
                write_array_vld[i] <= 'b0;
            else if( (prealloc_entry_onehot[i]==1) && write_handshake)
                write_array_vld[i] <= 1'b1;
        end
    end
endgenerate

/*========================================*/
/*               Write req                */
/*========================================*/

assign write_vld        = ~empty;
assign write_pld        = write_array_data[rd_ptr];

assign rel_write_entry  = ~empty && write_rdy;

/*========================================*/
/*   Comparator Array and hazard check    */
/*========================================*/

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        read_cmp_vld_1d <= 1'b0;
    else 
        read_cmp_vld_1d <= read_cmp_vld;
end

assign hazard_check[0]      = cmp_hit_onehot & mask_en;    //forward wptr hazard check
assign hazard_check[1]      = cmp_hit_onehot & (~mask_en); // backward wptr hazard check

assign multi_hit_en         = hazard_en[0] | hazard_en[1];
assign multi_hit_addr_index = hazard_en[0] ? hazard_bin[0] : hazard_bin[1];

generate

    for(genvar j=0; j<WRITE_BUFFER_DEPTH; j++ )begin
        assign cmp_hit_onehot[j]    = read_cmp_vld_1d && (read_cmp_addr == write_array_data[j].write_addr) && write_array_vld[j];
        assign mask_en[j]           = (j<=(WRITE_BUFFER_DEPTH'(wr_ptr-1))); 
    end 

    for(genvar i=0;i<2;i++)begin
        cmn_lead_one_msb #(
            .ENTRY_NUM      (WRITE_BUFFER_DEPTH   )
        ) u_hazard_multibit(
            .v_entry_vld    (hazard_check[i]      ),
            .v_free_idx_oh  (    ),
            .v_free_idx_bin (hazard_bin[i]        ),
            .v_free_vld     (hazard_en[i]         )
        );
    end

endgenerate

assign read_cmp_hit = |cmp_hit_onehot;

assign write_array_data_sel = write_array_data[multi_hit_addr_index];
assign read_buffer_data     = write_array_data_sel.write_data;

endmodule