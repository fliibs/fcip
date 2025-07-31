module sync_fifo_reg #(
    parameter  integer unsigned FIFO_DEPTH = 16,
    parameter  integer unsigned FIFO_WIDTH = 16,
    parameter  integer unsigned THRESHOLD  = 8,
    localparam int unsigned CNT_WIDTH = $clog2(FIFO_DEPTH)
)(
    input  logic                    clk,
    input  logic                    rst_n,

    //power down
    input  logic                    stall,
    input  logic                    clear,
    output logic                    idle,

    //write req
    input  logic                    write_req_vld,
    input  logic [FIFO_WIDTH-1:0]   write_req_pld,
    output logic                    write_req_rdy,

    //read response
    output logic                    read_resp_vld,
    output logic [FIFO_WIDTH-1:0]   read_resp_pld,
    input  logic                    read_resp_rdy,

    output logic                    custom_threshold_en
);

logic [CNT_WIDTH:0]             wr_ptr;
logic [CNT_WIDTH:0]             rd_ptr;
logic [CNT_WIDTH-1:0]           wr_ptr_true;
logic [CNT_WIDTH-1:0]           rd_ptr_true;
logic                           wr_ptr_msb;
logic                           rd_ptr_msb;
logic                           full;
logic                           empty;
logic [FIFO_WIDTH-1:0]          array_data[FIFO_DEPTH-1:0];
logic [CNT_WIDTH-1:0]           fifo_used;

/*========================================*/
/*              read control              */
/*========================================*/

assign rinc             = ~empty && read_resp_rdy;
assign read_resp_pld    = array_data[rd_ptr_true];
assign read_resp_vld    = rinc;

/*========================================*/
/*             write control              */
/*========================================*/

assign write_req_rdy    = ~full;
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
/*                Reg entry               */
/*========================================*/

generate
    for(genvar i=0;i<FIFO_DEPTH;i++)begin
        always_ff @( posedge clk or negedge rst_n ) begin : DATA_ARRAY
            if(~rst_n)
                array_data[i] <= 'b0;
            else if( winc && (wr_ptr_true==i))
                array_data[i] <= write_req_pld;
        end
    end
endgenerate

endmodule