module axi_sramc #(
    parameter  AXI_ADDR_WIDTH    = 32,
    parameter  AXI_ID_WIDTH      = 6,
    parameter  AXI_DATA_WIDTH    = 64,
    parameter  AXI_WSTRB_WIDTH   = AXI_DATA_WIDTH/8,
    parameter  AXI_USER_WIDTH    = 8,
    parameter  SRAM_R_LATENCY    = 1,
    parameter  HAS_NARROW_TR     = 1,
    parameter  HAS_UNALIGNED_TR  = 1
) (
    // clk&rstn
    input logic                               clk,
    input logic                               rstn,
    // axi slave interface 
    // aw
    input  logic                              s_awvalid,
    output logic                              s_awready,
    input  logic [AXI_ADDR_WIDTH-1:0]         s_awaddr,
    input  logic [AXI_ID_WIDTH-1:0]           s_awid,
    input  logic [7:0]                        s_awlen,
    input  logic [2:0]                        s_awsize,
    input  logic [1:0]                        s_awburst,
    input  logic [3:0]                        s_awcache,
    input  logic [2:0]                        s_awprot,
    input  logic [3:0]                        s_awqos,
    input  logic [AXI_USER_WIDTH-1:0]         s_awuser,
    // w
    input  logic                              s_wvalid,
    output logic                              s_wready,
    input  logic [AXI_DATA_WIDTH-1:0]         s_wdata,
    input  logic [AXI_WSTRB_WIDTH-1:0]        s_wstrb,
    input  logic                              s_wlast,
    // b
    output logic                              s_bvalid,
    input  logic                              s_bready,
    output logic [AXI_ID_WIDTH-1:0]           s_bid,
    output logic [1:0]                        s_bresp,
    // ar
    input  logic                              s_arvalid,
    output logic                              s_arready,
    input  logic [AXI_ADDR_WIDTH-1:0]         s_araddr,
    input  logic [AXI_ID_WIDTH-1:0]           s_arid,
    input  logic [7:0]                        s_arlen,
    input  logic [2:0]                        s_arsize,
    input  logic [1:0]                        s_arburst,
    input  logic [3:0]                        s_arcache,
    input  logic [2:0]                        s_arprot,
    input  logic [3:0]                        s_arqos,
    input  logic [AXI_USER_WIDTH-1:0]         s_aruser,
    // r
    output logic                              s_rvalid,
    input  logic                              s_rready,
    output logic [AXI_DATA_WIDTH-1:0]         s_rdata,
    output logic [AXI_ID_WIDTH-1:0]           s_rid,
    output logic [1:0]                        s_rresp,
    output logic                              s_rlast,
    // memory wrapper master interface
    // memory in
    output logic                              m_mi_ce,
    output logic                              m_mi_we,
    output logic [AXI_ADDR_WIDTH-1:0]         m_mi_addr,
    output logic [AXI_DATA_WIDTH-1:0]         m_mi_data,
    // memory out
    input  logic [AXI_DATA_WIDTH-1:0]         m_mo_data,
    // Reg
    output logic                              axi_sramc_idle

);

    logic read_handler_idle;
    logic write_handler_idle;
    
    localparam ARB_REQ_WIDTH = AXI_ADDR_WIDTH + AXI_ID_WIDTH + AXI_USER_WIDTH + AXI_DATA_WIDTH + 1 + 1 + 1; // addr+data+id+user+rm+rmw+last
    
    logic                              r_req_vld;  
    logic                              r_req_rdy;
    logic                              r_req_rw;
    logic                              r_req_rmw;
    logic                              r_req_axlast;
    logic [AXI_ID_WIDTH-1:0]           r_req_axid;
    logic [AXI_USER_WIDTH-1:0]         r_req_axuser;
    logic [AXI_ADDR_WIDTH-1:0]         r_req_axaddr;
    logic [AXI_DATA_WIDTH-1:0]         r_req_data;

    logic                              w_req_vld;  
    logic                              w_req_rdy;
    logic                              w_req_rw;
    logic                              w_req_rmw;
    logic                              w_req_axlast;
    logic [AXI_ID_WIDTH-1:0]           w_req_axid;
    logic [AXI_USER_WIDTH-1:0]         w_req_axuser;
    logic [AXI_ADDR_WIDTH-1:0]         w_req_axaddr;
    logic [AXI_DATA_WIDTH-1:0]         w_req_data;
    
    logic [1:0]                        v_arb_req_vld;
    logic [1:0]                        v_arb_req_rdy;
    logic [ARB_REQ_WIDTH-1:0]          v_arb_req_pld[1:0];

    logic                              req_aft_arb_vld;  
    logic                              req_aft_arb_rdy;
    logic [ARB_REQ_WIDTH-1:0]          req_aft_arb_pld;

    logic                              req_aft_arb_rw;
    logic                              req_aft_arb_rmw;
    logic                              req_aft_arb_axlast;
    logic [AXI_ID_WIDTH-1:0]           req_aft_arb_axid;
    logic [AXI_USER_WIDTH-1:0]         req_aft_arb_axuser;
    logic [AXI_ADDR_WIDTH-1:0]         req_aft_arb_axaddr;
    logic [AXI_DATA_WIDTH-1:0]         req_aft_arb_data;

    logic                              rsp_b4_dec_vld;
    logic                              rsp_b4_dec_rdy;
    logic                              rsp_b4_dec_rw;
    logic                              rsp_b4_dec_rmw;
    logic                              rsp_b4_dec_axlast;
    logic [AXI_ID_WIDTH-1:0]           rsp_b4_dec_axid;
    logic [AXI_DATA_WIDTH-1:0]         rsp_b4_dec_data;

    logic                              r_rsp_vld;
    logic                              r_rsp_rdy;
    logic                              r_rsp_rw;
    logic                              r_rsp_rmw;
    logic                              r_rsp_axlast;
    logic [AXI_ID_WIDTH-1:0]           r_rsp_axid;
    logic [AXI_DATA_WIDTH-1:0]         r_rsp_data;

    logic                              w_rsp_vld;
    logic                              w_rsp_rdy;
    logic                              w_rsp_rw;
    logic                              w_rsp_rmw;
    logic                              w_rsp_axlast;
    logic [AXI_ID_WIDTH-1:0]           w_rsp_axid;
    logic [AXI_DATA_WIDTH-1:0]         w_rsp_data;

    // axi_sramc idle
    assign axi_sramc_idle = read_handler_idle && write_handler_idle;

    // read handler
    read_handler #(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH )
    ) u_read_handler(
        .clk                  ( clk               ),  
        .rstn                 ( rstn              ),
        .s_arvld              ( s_arvalid         ), 
        .s_arrdy              ( s_arready         ),
        .s_araddr             ( s_araddr          ),  
        .s_arid               ( s_arid            ),  
        .s_arlen              ( s_arlen           ),  
        .s_arsize             ( s_arsize          ),
        .s_arburst            ( s_arburst         ), 
        .s_aruser             ( s_aruser          ), 
        .s_rvld               ( s_rvalid          ),  
        .s_rrdy               ( s_rready          ),   
        .s_rdata              ( s_rdata           ),    
        .s_rid                ( s_rid             ),    
        .s_rresp              ( s_rresp           ), 
        .s_rlast              ( s_rlast           ),  
        .m_req_vld            ( r_req_vld         ),    
        .m_req_rdy            ( r_req_rdy         ),  
        .m_req_rw             ( r_req_rw          ),  
        .m_req_rmw            ( r_req_rmw         ),  
        .m_req_axlast         ( r_req_axlast      ),  
        .m_req_axid           ( r_req_axid        ),  
        .m_req_axuser         ( r_req_axuser      ),  
        .m_req_axaddr         ( r_req_axaddr      ),  
        .m_req_data           ( r_req_data        ),  
        .s_rsp_vld            ( r_rsp_vld         ),  
        .s_rsp_rdy            ( r_rsp_rdy         ),  
        .s_rsp_rw             ( r_rsp_rw          ),  
        .s_rsp_rmw            ( r_rsp_rmw         ),  
        .s_rsp_axlast         ( r_rsp_axlast      ),  
        .s_rsp_axid           ( r_rsp_axid        ),  
        .s_rsp_data           ( r_rsp_data        ),  
        .read_handler_idle    ( read_handler_idle )  
    );

    write_handler #(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH )
    ) u_write_handler(
        .clk                 ( clk                ),
        .rstn                ( rstn               ),  
        .s_awvld             ( s_awvalid          ), 
        .s_awrdy             ( s_awready          ),  
        .s_awaddr            ( s_awaddr           ),
        .s_awid              ( s_awid             ),  
        .s_awlen             ( s_awlen            ),   
        .s_awsize            ( s_awsize           ),    
        .s_awburst           ( s_awburst          ),     
        .s_awuser            ( s_awuser           ),    
        .s_wvld              ( s_wvalid           ),      
        .s_wrdy              ( s_wready           ),     
        .s_wdata             ( s_wdata            ),     
        .s_wstrb             ( s_wstrb            ),      
        .s_wlast             ( s_wlast            ),      
        .s_bvld              ( s_bvalid           ),     
        .s_brdy              ( s_bready           ),     
        .s_bid               ( s_bid              ),       
        .s_bresp             ( s_bresp            ),      
        .m_req_vld           ( w_req_vld          ),        
        .m_req_rdy           ( w_req_rdy          ),          
        .m_req_rw            ( w_req_rw           ),        
        .m_req_rmw           ( w_req_rmw          ),         
        .m_req_axlast        ( w_req_axlast       ),      
        .m_req_axid          ( w_req_axid         ),      
        .m_req_axuser        ( w_req_axuser       ),      
        .m_req_axaddr        ( w_req_axaddr       ),      
        .m_req_data          ( w_req_data         ),     
        .s_rsp_vld           ( w_rsp_vld          ),      
        .s_rsp_rdy           ( w_rsp_rdy          ),      
        .s_rsp_rw            ( w_rsp_rw           ),     
        .s_rsp_rmw           ( w_rsp_rmw          ),      
        .s_rsp_axlast        ( w_rsp_axlast       ),      
        .s_rsp_axid          ( w_rsp_axid         ),        
        .s_rsp_data          ( w_rsp_data         ),     
        .write_handler_idle  ( write_handler_idle )
    );
    
    // rw req arb
    assign v_arb_req_vld          = {w_req_vld, r_req_vld};
    assign {w_req_rdy, r_req_rdy} = v_arb_req_rdy;
    assign v_arb_req_pld[0]       = {r_req_rw,r_req_rmw,r_req_axlast,r_req_axid,r_req_axuser,r_req_axaddr,r_req_data};
    assign v_arb_req_pld[1]       = {w_req_rw,w_req_rmw,w_req_axlast,w_req_axid,w_req_axuser,w_req_axaddr,w_req_data};

    assign {
            req_aft_arb_rw,req_aft_arb_rmw,req_aft_arb_axlast,req_aft_arb_axid,
            req_aft_arb_axuser,req_aft_arb_axaddr,req_aft_arb_data
           } = req_aft_arb_pld;

    arb_vrp #(
        .MODE       ( 1             ),
        .HSK_MODE   ( 0             ),
        .WIDTH      ( 2             ),
        .PLD_WIDTH  ( ARB_REQ_WIDTH )
    ) u_rw_req_arb(
        .clk     ( clk              ),
        .rst_n   ( rstn            ),  
        .v_vld_s ( v_arb_req_vld    ), 
        .v_rdy_s ( v_arb_req_rdy    ), 
        .v_pld_s ( v_arb_req_pld    ), 
        .vld_m   ( req_aft_arb_vld  ), 
        .rdy_m   ( req_aft_arb_rdy  ),
        .pld_m   ( req_aft_arb_pld  )
    );

    // rw rsp dec
    rw_decoder #(
        .AXI_ID_WIDTH    ( AXI_ID_WIDTH   ),
        .AXI_DATA_WIDTH  ( AXI_DATA_WIDTH )
    ) u_rw_rsp_dec(
        .sel             ( rsp_b4_dec_rmw | rsp_b4_dec_rw ),          
        .s_dec_vld       ( rsp_b4_dec_vld                 ),
        .s_dec_rdy       ( rsp_b4_dec_rdy                 ),
        .s_dec_rw        ( rsp_b4_dec_rw                  ),
        .s_dec_rmw       ( rsp_b4_dec_rmw                 ),
        .s_dec_axlast    ( rsp_b4_dec_axlast              ),
        .s_dec_axid      ( rsp_b4_dec_axid                ),
        .s_dec_data      ( rsp_b4_dec_data                ),             
        .m_dec_0_vld     ( r_rsp_vld                      ),
        .m_dec_0_rdy     ( r_rsp_rdy                      ),
        .m_dec_0_rw      ( r_rsp_rw                       ),
        .m_dec_0_rmw     ( r_rsp_rmw                      ),
        .m_dec_0_axlast  ( r_rsp_axlast                   ),
        .m_dec_0_axid    ( r_rsp_axid                     ),
        .m_dec_0_data    ( r_rsp_data                     ),             
        .m_dec_1_vld     ( w_rsp_vld                      ),
        .m_dec_1_rdy     ( w_rsp_rdy                      ),
        .m_dec_1_rw      ( w_rsp_rw                       ),
        .m_dec_1_rmw     ( w_rsp_rmw                      ),
        .m_dec_1_axlast  ( w_rsp_axlast                   ),
        .m_dec_1_axid    ( w_rsp_axid                     ),
        .m_dec_1_data    ( w_rsp_data                     )
    );
    
    mem_if_ctrl #(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH ),
        .SRAM_R_LATENCY ( SRAM_R_LATENCY )
    ) u_mem_if_ctrl(
        .clk           ( clk                  ),
        .rstn          ( rstn                 ),
        .s_req_valid   ( req_aft_arb_vld      ),
        .s_req_ready   ( req_aft_arb_rdy      ),
        .s_req_rw      ( req_aft_arb_rw       ),
        .s_req_rmw     ( req_aft_arb_rmw      ),
        .s_req_axlast  ( req_aft_arb_axlast   ),
        .s_req_axid    ( req_aft_arb_axid     ),
        .s_req_axuser  ( req_aft_arb_axuser   ),
        .s_req_axaddr  ( req_aft_arb_axaddr   ),
        .s_req_data    ( req_aft_arb_data     ), 
        .s_rsp_valid   ( rsp_b4_dec_vld       ), 
        .s_rsp_ready   ( rsp_b4_dec_rdy       ),
        .s_rsp_rw      ( rsp_b4_dec_rw        ),
        .s_rsp_rmw     ( rsp_b4_dec_rmw       ),
        .s_rsp_axlast  ( rsp_b4_dec_axlast    ),
        .s_rsp_axid    ( rsp_b4_dec_axid      ), 
        .s_rsp_data    ( rsp_b4_dec_data      ),
        .m_mi_ce       ( m_mi_ce              ), 
        .m_mi_we       ( m_mi_we              ),
        .m_mi_addr     ( m_mi_addr            ), 
        .m_mi_data     ( m_mi_data            ),  
        .m_mo_data     ( m_mo_data            )
    );


endmodule