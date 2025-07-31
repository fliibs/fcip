module sync_fifo_spram #(
    parameter  integer unsigned FIFO_DEPTH = 16,
    parameter  integer unsigned FIFO_WIDTH = 16,
    parameter  integer unsigned THRESHOLD  = 8,
    localparam int unsigned CNT_WIDTH = $clog2(FIFO_DEPTH)
)(
    input  logic                        clk,
    input  logic                        rst_n,

    //power down
    input  logic                        stall,
    input  logic                        clear,
    output logic                        idle,

    //write req
    input  logic                        write_req_vld,
    input  logic [FIFO_WIDTH-1:0]       write_req_pld,
    output logic                        write_req_rdy,

    //read response
    output logic                        read_resp_vld,
    output logic [FIFO_WIDTH-1:0]       read_resp_pld,
    input  logic                        read_resp_rdy,

    output logic                        custom_threshold_en,
    output logic                        empty,
    output logic                        full,

    //mem port
    output logic [CNT_WIDTH-1:0]        spram_addr,
    output logic [FIFO_WIDTH-1:0]       spram_din,
    input  logic [FIFO_WIDTH-1:0]       spram_dout,
    output logic                        spram_en,
    output logic                        spram_wren
);

logic [CNT_WIDTH:0]             wr_ptr;
logic [CNT_WIDTH:0]             rd_ptr;
logic [CNT_WIDTH-1:0]           wr_ptr_true;
logic [CNT_WIDTH-1:0]           rd_ptr_true;
logic                           wr_ptr_msb;
logic                           rd_ptr_msb;
logic [FIFO_WIDTH-1:0]          array_data[FIFO_DEPTH-1:0];
logic [CNT_WIDTH-1:0]           fifo_used;

/*========================================*/
/*              read control              */
/*========================================*/

assign rinc             = ~empty && read_resp_rdy;

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        read_resp_vld <= 1'b0;
    else 
        read_resp_vld <= rinc;
end

//assign read_resp_vld    = rinc;

/*========================================*/
/*             write control              */
/*========================================*/

assign write_req_rdy    = ~(full || rinc);
assign winc             = write_req_vld && write_req_rdy;

/*========================================*/
/*           read & write counter         */
/*========================================*/

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        rd_ptr <= 'b0;
    else if(rinc)
        rd_ptr <= rd_ptr + 1'b1;
end

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        wr_ptr <= 'b0;
    else if(winc)
        wr_ptr <= wr_ptr + 1'b1;
end

assign fifo_used            = (wr_ptr >= rd_ptr) ? (wr_ptr - rd_ptr): (wr_ptr + FIFO_DEPTH - rd_ptr);
assign custom_threshold_en  = (fifo_used == THRESHOLD);

/*========================================*/
/*               pointer check            */
/*========================================*/

assign {wr_ptr_msb,wr_ptr_true} = wr_ptr;
assign {rd_ptr_msb,rd_ptr_true} = rd_ptr;

assign full     = (rd_ptr_true == wr_ptr_true) && (wr_ptr_msb != rd_ptr_msb);
assign empty    = (rd_ptr == wr_ptr);

/*========================================*/
/*               Ram control              */
/*========================================*/

assign spram_addr       = rinc ? rd_ptr_true : wr_ptr_true;
assign spram_din        = write_req_pld;
assign spram_en         = rinc || winc;
assign spram_wren       = winc;

assign read_resp_pld    = spram_dout;

endmodule