module fcip_sync_fifo_reg #(
    parameter  integer unsigned FIFO_DEPTH = 16,
    parameter  integer unsigned FIFO_WIDTH = 16,
    parameter  integer unsigned ALMOST_FULL_THRESHOLD  = 12,
    parameter  integer unsigned ALMOST_EMPTY_THRESHOLD = 4 ,
    parameter  integer unsigned FORWARD_EN = 1 ,
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

    output logic                    almost_full,
    output logic                    almost_empty,
    output logic                    empty,
    output logic                    full
);

logic [CNT_WIDTH-1:0]           wr_ptr;
logic [CNT_WIDTH-1:0]           rd_ptr;
logic [FIFO_WIDTH-1:0]          array_data[FIFO_DEPTH-1:0];
logic [CNT_WIDTH:0]             ptr_cnt;
logic                           rinc;
logic                           winc;

/*========================================*/
/*            read/write control          */
/*========================================*/

generate 
    if(FORWARD_EN) begin

        logic forward_enable;

        assign forward_enable   = empty && read_resp_rdy;
        assign read_resp_pld    = forward_enable ? write_req_pld : array_data[rd_ptr];
        assign read_resp_vld    = forward_enable ? write_req_vld : ~empty;

        assign rinc             = (~empty) && read_resp_rdy;
        assign write_req_rdy    = ~full;
        assign winc             = write_req_vld && write_req_rdy && ~forward_enable;

    end else begin
        assign read_resp_pld    = array_data[rd_ptr];
        assign read_resp_vld    = ~empty;

        assign rinc             = (~empty) && read_resp_rdy;

        assign write_req_rdy    = ~full;
        assign winc             = write_req_vld && write_req_rdy;
    end
endgenerate

assign idle = empty; 

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

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        ptr_cnt <= 'b0;
    else if(winc && rinc)
        ptr_cnt <= ptr_cnt;
    else if(winc)
        ptr_cnt <= ptr_cnt + 1'b1;
    else if(rinc)
        ptr_cnt <= ptr_cnt - 1'b1;
end

/*========================================*/
/*              Almost signals            */
/*========================================*/

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        almost_full <= 'b0;
    else if( ptr_cnt >= ALMOST_FULL_THRESHOLD)
        almost_full <= 1'b1;
    else if( (ptr_cnt == (ALMOST_FULL_THRESHOLD-1)) && winc && ~rinc)
        almost_full <= 1'b1;
    else 
        almost_full <= 1'b0;
end

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        almost_empty <= 'b0;
    else if(ptr_cnt <= ALMOST_EMPTY_THRESHOLD)
        almost_empty <= 1'b1;
    else if( (ptr_cnt == (ALMOST_EMPTY_THRESHOLD-1)) && rinc && ~winc)
        almost_empty <= 1'b1;
    else 
        almost_empty <= 1'b0;
end

/*========================================*/
/*               pointer check            */
/*========================================*/

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        full <= 'b0;
    else if( (ptr_cnt == (FIFO_DEPTH-1)) && winc && ~rinc)
        full <= 1'b1;
    else if( ptr_cnt <= (FIFO_DEPTH-1) )
        full <= 1'b0;
end

always_ff @( posedge clk or negedge rst_n ) begin
    if(~rst_n)
        empty <= 'b1;
    else if( (ptr_cnt == 1) && rinc && ~winc )
        empty <= 1'b1;
    else if( ptr_cnt >= 1 )
        empty <= 1'b0;
end

/*========================================*/
/*                Reg entry               */
/*========================================*/

generate
    for(genvar i=0;i<FIFO_DEPTH;i++)begin
        always_ff @( posedge clk or negedge rst_n ) begin : DATA_ARRAY
            if(~rst_n)
                array_data[i] <= 'b0;
            else if( winc && (wr_ptr==i))
                array_data[i] <= write_req_pld;
        end
    end
endgenerate

endmodule