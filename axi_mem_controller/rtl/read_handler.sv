module read_handler #(
    parameter AXI_ADDR_WIDTH  = 32,
    parameter AXI_ID_WIDTH    = 6,
    parameter AXI_DATA_WIDTH  = 64,
    parameter AXI_USER_WIDTH  = 8
    
) (  
    // clk&rstn
    input logic                               clk,
    input logic                               rstn,
    // from axi if
    // ar
    input  logic                              s_arvld,
    output logic                              s_arrdy,
    input  logic [AXI_ADDR_WIDTH-1:0]         s_araddr,
    input  logic [AXI_ID_WIDTH-1:0]           s_arid,
    input  logic [7:0]                        s_arlen,
    input  logic [2:0]                        s_arsize,
    input  logic [1:0]                        s_arburst,
    // input  logic [3:0]                        s_arcache,
    // input  logic [2:0]                        s_arprot,
    // input  logic [3:0]                        s_arqos,
    input  logic [AXI_USER_WIDTH-1:0]         s_aruser,
    // r
    output logic                              s_rvld,
    input  logic                              s_rrdy,
    output logic [AXI_DATA_WIDTH-1:0]         s_rdata,
    output logic [AXI_ID_WIDTH-1:0]           s_rid,
    output logic [1:0]                        s_rresp,
    output logic                              s_rlast,
    // to req arb
    output logic                              m_req_vld,
    input  logic                              m_req_rdy,
    output logic                              m_req_rw,
    output logic                              m_req_rmw,
    output logic                              m_req_axlast,
    output logic [AXI_ID_WIDTH-1:0]           m_req_axid,
    output logic [AXI_USER_WIDTH-1:0]         m_req_axuser,
    output logic [AXI_ADDR_WIDTH-1:0]         m_req_axaddr,
    output logic [AXI_DATA_WIDTH-1:0]         m_req_data,
    // from rsp dec
    input  logic                              s_rsp_vld,
    output logic                              s_rsp_rdy,
    input  logic                              s_rsp_rw,
    input  logic                              s_rsp_rmw,
    input  logic                              s_rsp_axlast,
    input  logic [AXI_ID_WIDTH-1:0]           s_rsp_axid,
    input  logic [AXI_DATA_WIDTH-1:0]         s_rsp_data,
    output logic                              read_handler_idle
);

    logic [3:0] tr_cnt;
    
    // transfer split
    transfer_split #(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH )
    ) u_ar_transfer_split(
        .clk     ( clk                ), 
        .rstn    ( rstn               ), 
        .s_vld   ( s_arvld            ),  
        .s_rdy   ( s_arrdy            ), 
        .s_addr  ( s_araddr           ), 
        .s_id    ( s_arid             ), 
        .s_len   ( s_arlen            ), 
        .s_size  ( s_arsize           ), 
        .s_burst ( s_arburst          ),  
        .s_user  ( s_aruser           ),  
        .m_vld   ( m_req_vld          ), 
        .m_rdy   ( m_req_rdy          ), 
        .m_last  ( m_req_axlast       ),  
        .m_id    ( m_req_axid         ), 
        .m_user  ( m_req_axuser       ), 
        .m_addr  ( m_req_axaddr       )
    );

    assign m_req_rw     = 1'b0;
    assign m_req_rmw    = 1'b0;
    assign m_req_data   = {AXI_DATA_WIDTH{1'b0}};
    
    // rrsp gen
    assign s_rsp_rdy = s_rrdy;
    
    assign s_rvld  = s_rsp_vld;
    assign s_rdata = s_rsp_data;
    assign s_rid   = s_rsp_axid;
    assign s_rresp = 2'b0;
    assign s_rlast = s_rsp_axlast;

    // read transaction cnt
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            tr_cnt <= 4'b0;
        end else if (s_arvld && s_arrdy) begin
            tr_cnt <= tr_cnt + 1'b1;
        end else if (s_rvld && s_rrdy && s_rlast) begin
            tr_cnt <= tr_cnt - 1'b1;
        end
    end
    
    assign read_handler_idle = ~|tr_cnt;

endmodule