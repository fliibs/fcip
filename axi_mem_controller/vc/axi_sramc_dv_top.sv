`timescale 1ns/10ps

module axi_sramc_dv_top;
     
    parameter  AXI_ADDR_WIDTH      = 32;
    parameter  AXI_ID_WIDTH        = 6;
    parameter  AXI_DATA_WIDTH      = 64;
    parameter  AXI_WSTRB_WIDTH     = AXI_DATA_WIDTH/8;
    parameter  AXI_USER_WIDTH      = 8;
    parameter  HAS_NARROW_TR       = 1;
    parameter  HAS_UNALIGNED_TR    = 1;
    // The data bit width of SRAM needs to meet the ecc requirements 
    localparam ECC_CHECK__WIDTH    = ($clog2($clog2(AXI_DATA_WIDTH) + AXI_DATA_WIDTH) == $clog2(AXI_DATA_WIDTH)) ? $clog2(AXI_DATA_WIDTH) :  $clog2(AXI_DATA_WIDTH)+1;
    localparam SRAM_DATA_WIDTH     = AXI_DATA_WIDTH + ECC_CHECK__WIDTH + 1;
    localparam SRAM_CTRL_WIDTH     = AXI_ID_WIDTH+1+1+1; // rw+rmw+id+last

    // clk&rstn
    logic                               clk;
    logic                               rstn;
    // axi slave interface 
    // aw
    logic                              s_awvalid;
    logic                              s_awready;
    logic [AXI_ADDR_WIDTH-1:0]         s_awaddr;
    logic [AXI_ID_WIDTH-1:0]           s_awid;
    logic [7:0]                        s_awlen;
    logic [2:0]                        s_awsize;
    logic [1:0]                        s_awburst;
    logic [3:0]                        s_awcache;
    logic [2:0]                        s_awprot;
    logic [3:0]                        s_awqos;
    logic [AXI_USER_WIDTH-1:0]         s_awuser;
    // w
    logic                              s_wvalid;
    logic                              s_wready;
    logic [AXI_DATA_WIDTH-1:0]         s_wdata;
    logic [AXI_WSTRB_WIDTH-1:0]        s_wstrb;
    logic                              s_wlast;
    // b
    logic                              s_bvalid;
    logic                              s_bready;
    logic [AXI_ID_WIDTH-1:0]           s_bid;
    logic [1:0]                        s_bresp;
    // ar
    logic                              s_arvalid;
    logic                              s_arready;
    logic [AXI_ADDR_WIDTH-1:0]         s_araddr;
    logic [AXI_ID_WIDTH-1:0]           s_arid;
    logic [7:0]                        s_arlen;
    logic [2:0]                        s_arsize;
    logic [1:0]                        s_arburst;
    logic [3:0]                        s_arcache;
    logic [2:0]                        s_arprot;
    logic [3:0]                        s_arqos;
    logic [AXI_USER_WIDTH-1:0]         s_aruser;
    // r
    logic                              s_rvalid;
    logic                              s_rready;
    logic [AXI_DATA_WIDTH-1:0]         s_rdata;
    logic [AXI_ID_WIDTH-1:0]           s_rid;
    logic [1:0]                        s_rresp;
    logic                              s_rlast;
    // Reg
    logic                              axi_sramc_idle;
    logic                              ecc_err;
    
    // memory wrapper master interface
    // memory in
    logic                              m_mi_valid;
    logic                              m_mi_ready;
    logic                              m_mi_rw;
    logic                              m_mi_rmw;
    logic                              m_mi_axlast;
    logic [AXI_ID_WIDTH-1:0]           m_mi_axid;
    logic [AXI_USER_WIDTH-1:0]         m_mi_axuser;
    logic [AXI_ADDR_WIDTH-1:0]         m_mi_axaddr;
    logic [SRAM_DATA_WIDTH-1:0]        m_mi_data;
    // memory out
    logic                              m_mo_valid;
    logic                              m_mo_ready;
    logic                              m_mo_rw;
    logic                              m_mo_rmw;
    logic                              m_mo_axlast;
    logic [AXI_ID_WIDTH-1:0]           m_mo_axid;
    logic [SRAM_DATA_WIDTH-1:0]        m_mo_data;

    event   w_event;
    
    // axi sramc
    axi_sramc #(
        .AXI_ADDR_WIDTH    ( AXI_ADDR_WIDTH   ),
        .AXI_ID_WIDTH      ( AXI_ID_WIDTH     ),
        .AXI_DATA_WIDTH    ( AXI_DATA_WIDTH   ),
        .AXI_WSTRB_WIDTH   ( AXI_WSTRB_WIDTH  ),
        .AXI_USER_WIDTH    ( AXI_USER_WIDTH   ),
        .HAS_NARROW_TR     ( HAS_NARROW_TR    ),
        .HAS_UNALIGNED_TR  ( HAS_UNALIGNED_TR )
    ) u_axi_sramc(
        .clk                  ( clk               ),  
        .rstn                 ( rstn              ), 
        .s_awvalid            ( s_awvalid         ),
        .s_awready            ( s_awready         ), 
        .s_awaddr             ( s_awaddr          ),    
        .s_awid               ( s_awid            ),   
        .s_awlen              ( s_awlen           ),   
        .s_awsize             ( s_awsize          ),  
        .s_awburst            ( s_awburst         ),  
        .s_awcache            ( s_awcache         ),     
        .s_awprot             ( s_awprot          ),    
        .s_awqos              ( s_awqos           ),   
        .s_awuser             ( s_awuser          ),   
        .s_wvalid             ( s_wvalid          ), 
        .s_wready             ( s_wready          ),  
        .s_wdata              ( s_wdata           ),  
        .s_wstrb              ( s_wstrb           ), 
        .s_wlast              ( s_wlast           ),  
        .s_bvalid             ( s_bvalid          ),   
        .s_bready             ( s_bready          ), 
        .s_bid                ( s_bid             ),  
        .s_bresp              ( s_bresp           ),      
        .s_arvalid            ( s_arvalid         ),      
        .s_arready            ( s_arready         ),     
        .s_araddr             ( s_araddr          ),    
        .s_arid               ( s_arid            ),  
        .s_arlen              ( s_arlen           ),   
        .s_arsize             ( s_arsize          ),       
        .s_arburst            ( s_arburst         ),     
        .s_arcache            ( s_arcache         ),     
        .s_arprot             ( s_arprot          ), 
        .s_arqos              ( s_arqos           ),  
        .s_aruser             ( s_aruser          ),    
        .s_rvalid             ( s_rvalid          ),   
        .s_rready             ( s_rready          ),  
        .s_rdata              ( s_rdata           ),
        .s_rid                ( s_rid             ), 
        .s_rresp              ( s_rresp           ),
        .s_rlast              ( s_rlast           ),  
        .m_mi_valid           ( m_mi_valid        ),     
        .m_mi_ready           ( m_mi_ready        ),   
        .m_mi_rw              ( m_mi_rw           ),    
        .m_mi_rmw             ( m_mi_rmw          ),     
        .m_mi_axlast          ( m_mi_axlast       ),    
        .m_mi_axid            ( m_mi_axid         ),   
        .m_mi_axuser          ( m_mi_axuser       ),    
        .m_mi_axaddr          ( m_mi_axaddr       ),  
        .m_mi_data            ( m_mi_data         ),   
        .m_mo_valid           ( m_mo_valid        ),      
        .m_mo_ready           ( m_mo_ready        ),    
        .m_mo_rw              ( m_mo_rw           ),  
        .m_mo_rmw             ( m_mo_rmw          ), 
        .m_mo_axlast          ( m_mo_axlast       ),    
        .m_mo_axid            ( m_mo_axid         ),    
        .m_mo_data            ( m_mo_data         ),  
        .axi_sramc_idle       ( axi_sramc_idle    ),    
        .ecc_err              ( ecc_err           )       
    );

    // memory wrapper
    memory_wrapper #(
        .ADDR_WIDTH      ( AXI_ADDR_WIDTH                                                      ),
        .DATA_WIDTH      ( SRAM_DATA_WIDTH                                                     ),
        .CTRL_WIDTH      ( SRAM_CTRL_WIDTH                                                     ), // rw+rmw+id+last
        .PLD_I_WIDTH     ( SRAM_CTRL_WIDTH + AXI_USER_WIDTH + AXI_ADDR_WIDTH + SRAM_DATA_WIDTH ),
        .PLD_O_WIDTH     ( SRAM_CTRL_WIDTH + SRAM_DATA_WIDTH                                   ),
        .SRAM_R_LATENCY  ( 1                                                                   )
    ) u_memory_wrapper(
        .clk    ( clk        ), 
        .rstn   ( rstn       ), 
        .s_vld  ( m_mi_valid ), 
        .s_rdy  ( m_mi_ready ), 
        .s_pld  ( {m_mi_rw,m_mi_rmw,m_mi_axid,m_mi_axlast,m_mi_axuser,m_mi_axaddr,m_mi_data} ), 
        .m_vld  ( m_mo_valid ), 
        .m_rdy  ( m_mo_ready ), 
        .m_pld  ( {m_mo_rw,m_mo_rmw,m_mo_axid,m_mo_axlast,m_mo_data} )
    );

    // sim
    initial begin
        clk=0;
        forever #1 clk=~clk;
    end
    
    initial begin
        rstn=1;
        #20;
        rstn=0;
        #20;
        rstn=1;
    end

    initial begin
        s_awvalid <= 1'b0;
        s_awaddr  <= {AXI_ADDR_WIDTH{1'b0}};
        s_awid    <= {AXI_ID_WIDTH{1'b0}};
        s_awlen   <= 8'h0;
        s_awsize  <= 3'h0;
        s_awburst <= 2'h0;
        s_awcache <= 4'h0;
        s_awprot  <= 3'h0;
        s_awqos   <= 4'h0;
        s_awuser  <= {AXI_USER_WIDTH{1'b0}};

        s_wvalid  <= 1'b0; 
        s_wdata   <= {AXI_DATA_WIDTH{1'b0}};
        s_wstrb   <= {AXI_WSTRB_WIDTH{1'b0}};
        s_wlast   <= 1'b0;

        s_bready  <= 1'b1;
        
        s_arvalid <= 1'b0;
        s_araddr  <= {AXI_ADDR_WIDTH{1'b0}};
        s_arid    <= {AXI_ID_WIDTH{1'b0}};
        s_arlen   <= 8'h0;
        s_arsize  <= 3'h0;
        s_arburst <= 2'h0;
        s_arcache <= 4'h0;
        s_arprot  <= 3'h0;
        s_arqos   <= 4'h0;
        s_aruser  <= {AXI_USER_WIDTH{1'b0}};

        s_rready  <= 1'b1;
        #100;

        // read tr
        repeat(2) @(posedge clk);
        s_awvalid <= #0.01 1'b1;
        s_awaddr  <= 32'h8;
        s_awid    <= 'h1;
        s_awlen   <= 8'h3;
        s_awsize  <= 3'b011; // 8B
        s_awburst <= 2'h2;
        s_awcache <= 4'h0;
        s_awprot  <= 3'h0;
        s_awqos   <= 4'h0;
        s_awuser  <= 'h8;
        
        s_wvalid  <= 1'b1; 
        s_wdata   <= 64'h1111_1111_1111_1111;
        s_wstrb   <= 8'hff;
        s_wlast   <= 1'b0;
        
        @ w_event;
        repeat(1) @(posedge clk);
        s_wvalid  <= 1'b1; 
        s_wdata   <= 64'h2222_2222_2222_2222;
        s_wstrb   <= 8'hff;
        s_wlast   <= 1'b0;
        @ w_event;
        repeat(1) @(posedge clk);
        s_wvalid  <= 1'b1; 
        s_wdata   <= 64'h3333_3333_3333_3333;
        s_wstrb   <= 8'hff;
        s_wlast   <= 1'b0;
        @ w_event;
        repeat(1) @(posedge clk);
        s_wvalid  <= 1'b1; 
        s_wdata   <= 64'h4444_4444_4444_4444;
        s_wstrb   <= 8'hff;
        s_wlast   <= 1'b1;
        @ w_event;
        s_wvalid  <= 1'b0;
         
        // read
        #50;
        repeat(2) @(posedge clk);

        s_arvalid <= #0.01 1'b1;
        s_araddr  <= 32'h8;
        s_arid    <= 'h3;
        s_arlen   <= 8'h3;
        s_arsize  <= 3'b011; // 8B
        s_arburst <= 2'h2;
        s_arcache <= 4'h0;
        s_arprot  <= 3'h0;
        s_arqos   <= 4'h0;
        s_aruser  <= 'h4;

        // rmw 
        #50;
        repeat(2) @(posedge clk);
        s_awvalid <= #0.01 1'b1;
        s_awaddr  <= 32'h8;
        s_awid    <= 'h5;
        s_awlen   <= 8'h3;
        s_awsize  <= 3'b010; // 4B
        s_awburst <= 2'h1; //incr
        s_awcache <= 4'h0;
        s_awprot  <= 3'h0;
        s_awqos   <= 4'h0;
        s_awuser  <= 'h9;
        
        s_wvalid  <= 1'b1; 
        s_wdata   <= 64'hffff_ffff_ffff_ffff;
        s_wstrb   <= 8'h0f;
        s_wlast   <= 1'b0;

        @ w_event;
        repeat(1) @(posedge clk);
        s_wvalid  <= 1'b1; 
        s_wdata   <= 64'heeee_eeee_eeee_eeee;
        s_wstrb   <= 8'hf0;
        s_wlast   <= 1'b0;
        @ w_event;
        repeat(1) @(posedge clk);
        s_wvalid  <= 1'b1; 
        s_wdata   <= 64'haaaa_aaaa_aaaa_aaaa;
        s_wstrb   <= 8'h0f;
        s_wlast   <= 1'b0;
        @ w_event;
        repeat(1) @(posedge clk);
        s_wvalid  <= 1'b1; 
        s_wdata   <= 64'hbbbb_bbbb_bbbb_bbbb;
        s_wstrb   <= 8'hf0;
        s_wlast   <= 1'b1;
        @ w_event;
        s_wvalid  <= 1'b0;
        
        // read
         #50;
        repeat(2) @(posedge clk);
        s_arvalid <= #0.01 1'b1;
        s_araddr  <= 32'h8;
        s_arid    <= 'h4;
        s_arlen   <= 8'h3;
        s_arsize  <= 3'b011; // 8B
        s_arburst <= 2'h1;//incr
        s_arcache <= 4'h0;
        s_arprot  <= 3'h0;
        s_arqos   <= 4'h0;
        s_aruser  <= 'h6;

        #100;
        $finish();
    end

    always @(posedge clk or negedge rstn) begin
        if (s_arvalid && s_arready) begin
            s_arvalid <= 1'b0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (s_awvalid && s_awready) begin
            s_awvalid <= 1'b0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (s_wvalid && s_wready) begin
            s_wvalid <= 1'b0;
            -> w_event;
        end
    end

    initial begin 
        $fsdbDumpfile("tb_top.fsdb");
        $fsdbDumpvars("+all");
    end

endmodule