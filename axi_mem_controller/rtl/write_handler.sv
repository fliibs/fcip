module write_handler #(
    parameter AXI_ADDR_WIDTH  = 32,
    parameter AXI_ID_WIDTH    = 6,
    parameter AXI_DATA_WIDTH  = 64,
    parameter AXI_WSTRB_WIDTH = AXI_DATA_WIDTH/8,
    parameter AXI_USER_WIDTH  = 8
    
) (  
    // clk&rstn
    input logic                               clk,
    input logic                               rstn,
    // from axi if
    // aw
    input  logic                              s_awvld,
    output logic                              s_awrdy,
    input  logic [AXI_ADDR_WIDTH-1:0]         s_awaddr,
    input  logic [AXI_ID_WIDTH-1:0]           s_awid,
    input  logic [7:0]                        s_awlen,
    input  logic [2:0]                        s_awsize,
    input  logic [1:0]                        s_awburst,
    // input  logic [3:0]                        s_awcache,
    // input  logic [2:0]                        s_awprot,
    // input  logic [3:0]                        s_awqos,
    input  logic [AXI_USER_WIDTH-1:0]         s_awuser,
    // w
    input  logic                              s_wvld,
    output logic                              s_wrdy,
    input  logic [AXI_DATA_WIDTH-1:0]         s_wdata,
    input  logic [AXI_WSTRB_WIDTH-1:0]        s_wstrb,
    input  logic                              s_wlast,
    // b
    output logic                              s_bvld,
    input  logic                              s_brdy,
    output logic [AXI_ID_WIDTH-1:0]           s_bid,
    output logic [1:0]                        s_bresp,
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
    output logic                              write_handler_idle
);

    localparam ARB_REQ_WIDTH  = 1 + 1 + 1 + AXI_ID_WIDTH + AXI_USER_WIDTH + AXI_ADDR_WIDTH + AXI_DATA_WIDTH; //rw+rmw+last+id+user+addr+data

    logic [AXI_ADDR_WIDTH-1:0]  m_split_awaddr;
    logic [AXI_ID_WIDTH-1:0]    m_split_awid;
    logic [AXI_USER_WIDTH-1:0]  m_split_awuser;
    logic                       m_split_awlast;
    logic                       m_split_vld;
    logic                       m_split_rdy;

    logic                       aww_merge_vld;
    logic                       aww_merge_rdy;
    logic [AXI_ADDR_WIDTH-1:0]  aww_merge_awaddr;
    logic [AXI_ID_WIDTH-1:0]    aww_merge_awid;
    logic [AXI_USER_WIDTH-1:0]  aww_merge_awuser;
    logic                       aww_merge_awlast;
    logic [AXI_DATA_WIDTH-1:0]  aww_merge_wdata;
    logic [AXI_WSTRB_WIDTH-1:0] aww_merge_wstrb;

    logic                       m_rsp_0_vld;
    logic                       m_rsp_0_rdy;
    logic                       m_rsp_0_rw;
    logic                       m_rsp_0_rmw;
    logic                       m_rsp_0_axlast;
    logic [AXI_ID_WIDTH-1:0]    m_rsp_0_axid;
    logic [AXI_DATA_WIDTH-1:0]  m_rsp_0_data;
    logic                       m_rsp_1_vld;
    logic                       m_rsp_1_rdy;
    logic                       m_rsp_1_rw;
    logic                       m_rsp_1_rmw;
    logic                       m_rsp_1_axlast;
    logic [AXI_ID_WIDTH-1:0]    m_rsp_1_axid;
    logic [AXI_DATA_WIDTH-1:0]  m_rsp_1_data;

    logic                       rs_req_vld;
    logic                       rs_req_rdy;
    logic                       rs_req_rw;
    logic                       rs_req_rmw;
    logic                       rs_req_axlast;
    logic [AXI_ID_WIDTH-1:0]    rs_req_axid;
    logic [AXI_USER_WIDTH-1:0]  rs_req_axuser;
    logic [AXI_ADDR_WIDTH-1:0]  rs_req_axaddr;
    logic [AXI_DATA_WIDTH-1:0]  rs_req_data;

    logic [ARB_REQ_WIDTH-1:0]   rs_req_pld; 
    logic [ARB_REQ_WIDTH-1:0]   m_req_pld; 


    logic [3:0] tr_cnt;
    
    // transfer split
    transfer_split #(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH )
    ) u_aw_transfer_split(
        .clk     ( clk                ), 
        .rstn    ( rstn               ), 
        .s_vld   ( s_awvld            ),  
        .s_rdy   ( s_awrdy            ), 
        .s_addr  ( s_awaddr           ), 
        .s_id    ( s_awid             ), 
        .s_len   ( s_awlen            ), 
        .s_size  ( s_awsize           ), 
        .s_burst ( s_awburst          ),  
        .s_user  ( s_awuser           ),  
        .m_vld   ( m_split_vld        ), 
        .m_rdy   ( m_split_rdy        ), 
        .m_last  ( m_split_awlast     ),  
        .m_id    ( m_split_awid       ), 
        .m_user  ( m_split_awuser     ), 
        .m_addr  ( m_split_awaddr     )
    );
    
    // aww merge
    assign aww_merge_vld    = m_split_vld && s_wvld;
    assign m_split_rdy      = aww_merge_vld && aww_merge_rdy;
    assign s_wrdy           = aww_merge_vld && aww_merge_rdy;
    assign aww_merge_awaddr = m_split_awaddr;
    assign aww_merge_awid   = m_split_awid;
    assign aww_merge_awuser = m_split_awuser;
    assign aww_merge_awlast = s_wlast;
    assign aww_merge_wdata  = s_wdata;
    assign aww_merge_wstrb  = s_wstrb;
    
    // rmw handler
    read_modify_write #(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH )
    ) u_read_modify_write(
        .clk          ( clk              ),   
        .rstn         ( rstn             ),  
        .s_aww_vld    ( aww_merge_vld    ),   
        .s_aww_rdy    ( aww_merge_rdy    ),     
        .s_aww_addr   ( aww_merge_awaddr ),    
        .s_aww_id     ( aww_merge_awid   ),     
        .s_aww_user   ( aww_merge_awuser ),      
        .s_aww_data   ( aww_merge_wdata  ),     
        .s_aww_strb   ( aww_merge_wstrb  ),     
        .s_aww_last   ( aww_merge_awlast ),    
        .m_req_vld    ( m_req_vld        ),     
        .m_req_rdy    ( m_req_rdy        ),   
        .m_req_rw     ( m_req_rw         ),  
        .m_req_rmw    ( m_req_rmw        ),   
        .m_req_axlast ( m_req_axlast     ),   
        .m_req_axid   ( m_req_axid       ),  
        .m_req_axuser ( m_req_axuser     ),    
        .m_req_axaddr ( m_req_axaddr     ),   
        .m_req_data   ( m_req_data       ), 
        .s_rsp_vld    ( m_rsp_0_vld      ), 
        .s_rsp_rdy    ( m_rsp_0_rdy      ),    
        .s_rsp_rw     ( m_rsp_0_rw       ),   
        .s_rsp_rmw    ( m_rsp_0_rmw      ),  
        .s_rsp_axlast ( m_rsp_0_axlast   ),  
        .s_rsp_axid   ( m_rsp_0_axid     ), 
        .s_rsp_data   ( m_rsp_0_data     )
    );

    // assign rs_req_pld = {rs_req_rw,rs_req_rmw,rs_req_axlast,rs_req_axid,rs_req_axuser,rs_req_axaddr,rs_req_data};
    // assign {m_req_rw,m_req_rmw,m_req_axlast,m_req_axid,m_req_axuser,m_req_axaddr,m_req_data} = m_req_pld;
// 
    // reg_slice #(
        // .RS_TYPE   ( 2             ), // 0: Pass Through 1: Forward 2: Backward 3:Full
        // .PLD_WIDTH ( ARB_REQ_WIDTH )
    // ) u_reg_slice(
        // .clk    ( clk        ),
        // .rst_n  ( rstn       ),
        // .s_vld  ( rs_req_vld ),
        // .s_rdy  ( rs_req_rdy ),
        // .s_pld  ( rs_req_pld ),
        // .m_vld  ( m_req_vld  ),
        // .m_rdy  ( m_req_rdy  ),
        // .m_pld  ( m_req_pld  )
    // );

    // rmw dec
    rw_decoder #(
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH )
    ) u_rmw_rw_dec(
        .sel             ( s_rsp_rw       ),          
        .s_dec_vld       ( s_rsp_vld      ),
        .s_dec_rdy       ( s_rsp_rdy      ),
        .s_dec_rw        ( s_rsp_rw       ),
        .s_dec_rmw       ( s_rsp_rmw      ),
        .s_dec_axlast    ( s_rsp_axlast   ),
        .s_dec_axid      ( s_rsp_axid     ),
        .s_dec_data      ( s_rsp_data     ),             
        .m_dec_0_vld     ( m_rsp_0_vld    ),
        .m_dec_0_rdy     ( m_rsp_0_rdy    ),
        .m_dec_0_rw      ( m_rsp_0_rw     ),
        .m_dec_0_rmw     ( m_rsp_0_rmw    ),
        .m_dec_0_axlast  ( m_rsp_0_axlast ),
        .m_dec_0_axid    ( m_rsp_0_axid   ),
        .m_dec_0_data    ( m_rsp_0_data   ),             
        .m_dec_1_vld     ( m_rsp_1_vld    ),
        .m_dec_1_rdy     ( m_rsp_1_rdy    ),
        .m_dec_1_rw      ( m_rsp_1_rw     ),
        .m_dec_1_rmw     ( m_rsp_1_rmw    ),
        .m_dec_1_axlast  ( m_rsp_1_axlast ),
        .m_dec_1_axid    ( m_rsp_1_axid   ),
        .m_dec_1_data    ( m_rsp_1_data   )
    );

    // brsp gen
    assign m_rsp_1_rdy = s_brdy;
    
    assign s_bvld  = m_rsp_1_vld && m_rsp_1_axlast;
    assign s_bid   = m_rsp_1_axid;
    assign s_bresp = 2'b0;

    // write transaction cnt
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            tr_cnt <= 4'b0;
        end else if (s_awvld && s_awrdy) begin
            tr_cnt <= tr_cnt + 1'b1;
        end else if (s_bvld && s_brdy) begin
            tr_cnt <= tr_cnt - 1'b1;
        end
    end
    
    assign write_handler_idle = ~|tr_cnt;

endmodule