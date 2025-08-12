`timescale 1ns/10ps

module axi_sramc_dv_top;
     
    parameter  AXI_ADDR_WIDTH      = 32;
    parameter  AXI_ID_WIDTH        = 6;
    parameter  AXI_DATA_WIDTH      = 64;
    parameter  AXI_WSTRB_WIDTH     = AXI_DATA_WIDTH/8;
    parameter  AXI_USER_WIDTH      = 8;
    parameter  SRAM_R_LATENCY      = 1;
    parameter  HAS_NARROW_TR       = 1;
    parameter  HAS_UNALIGNED_TR    = 1;
    parameter  SRAM_DATA_WIDTH     = 64;

    // clk&rstn
    logic                              clk;
    logic                              rstn;
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
    
    // memory wrapper master interface
    logic                              mi_ce;
    logic                              mi_we;
    logic [AXI_ADDR_WIDTH-1:0]         mi_addr;
    logic [SRAM_DATA_WIDTH-1:0]        mi_data;
    logic [SRAM_DATA_WIDTH-1:0]        mo_data;

    event   w_event;
    
    // axi sramc
    axi_sramc #(
        .AXI_ADDR_WIDTH    ( AXI_ADDR_WIDTH   ),
        .AXI_ID_WIDTH      ( AXI_ID_WIDTH     ),
        .AXI_DATA_WIDTH    ( AXI_DATA_WIDTH   ),
        .AXI_WSTRB_WIDTH   ( AXI_WSTRB_WIDTH  ),
        .AXI_USER_WIDTH    ( AXI_USER_WIDTH   ),
        .SRAM_R_LATENCY    ( SRAM_R_LATENCY   ),
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
        .m_mi_ce              ( mi_ce             ),
        .m_mi_we              ( mi_we             ),
        .m_mi_addr            ( mi_addr           ),
        .m_mi_data            ( mi_data           ), 
        .m_mo_data            ( mo_data           ),
        .axi_sramc_idle       ( axi_sramc_idle    )
    );

    // memory wrapper
    memory_wrapper #(
        .ADDR_WIDTH      ( AXI_ADDR_WIDTH   ),
        .DATA_WIDTH      ( SRAM_DATA_WIDTH  )
    ) u_memory_wrapper(
        .clk        ( clk        ), 
        .rstn       ( rstn       ), 
        .mi_ce      ( mi_ce      ), 
        .mi_we      ( mi_we      ), 
        .mi_addr    ( mi_addr    ), 
        .mi_data    ( mi_data    ), 
        .mo_data    ( mo_data    ) 
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

    //initial begin 
    //    $fsdbDumpfile("tb_top.fsdb");
    //    $fsdbDumpvars("+all");
    //end

endmodule