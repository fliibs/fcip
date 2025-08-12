package ocm_package;
    localparam integer unsigned OCM_AXI_DATA_MAX                    = 1024                                                          ;
    localparam integer unsigned OCM_AXI_DATA_WIDTH                  = 512                                                           ;
    localparam integer unsigned OCM_AXI_LEN                         = $clog2(1024/512)                                              ;
    localparam integer unsigned OCM_AXI_BURST_SIZE                  = 1                                                             ;
    localparam integer unsigned OCM_AXI_AWID_WIDTH                  = 8                                                             ;
    localparam integer unsigned OCM_AXI_RID_WIDTH                   = 8                                                             ;
    localparam integer unsigned OCM_AXI_ID_WIDTH                    = 8                                                             ;
                
    localparam integer unsigned OCM_AXI_ADDR_WIDTH                  = 12                                                            ; //8196*4
    localparam integer unsigned OCM_DATA_RAM_NUM                    = 4                                                             ;
    localparam integer unsigned OCM_DATA_RAM_DEPTH                  = $clog2(OCM_DATA_RAM_NUM)                                      ;
    localparam integer unsigned OCM_L_DATA_RAM_DATA_WIDTH           = 1024                                                          ;
    localparam integer unsigned OCM_L_DATA_RAM_ADDR_WIDTH           = 10                                                            ; //8196
    localparam integer unsigned OCM_L_DATA_RAM_ADDR_DEPTH           = 1 << OCM_L_DATA_RAM_ADDR_WIDTH                                ;
    localparam integer unsigned OCM_ROB_ENTRY_NUM                   = 32                                                            ;
    localparam integer unsigned OCM_ROB_ENTRY_WIDTH                 = $clog2(OCM_ROB_ENTRY_NUM)                                     ;
                      
    //arbiter parameter             
    localparam integer unsigned OCM_READ_BUFFER_CYCLE               = OCM_L_DATA_RAM_DATA_WIDTH/OCM_AXI_DATA_WIDTH                  ;
                    
    //data buf parameter                
    localparam integer unsigned OCM_PACK_DATA_WIDTH                 = 1024                                                          ;
                
    //read fifo depth               
    localparam integer unsigned OCM_PACK_FIFO_ADDR_DEPTH            = 8                                                             ; 
    localparam integer unsigned OCM_PACK_FIFO_ADDR_WIDTH            = $clog2(OCM_PACK_FIFO_ADDR_DEPTH)                              ;
    localparam integer unsigned OCM_PACK_FIFO_DATA_WIDTH            = OCM_L_DATA_RAM_DATA_WIDTH + OCM_AXI_LEN + OCM_AXI_ID_WIDTH + 1;

    //ecc_parameter
    localparam integer unsigned OCM_ECC_DATA_WIDTH                  = OCM_L_DATA_RAM_DATA_WIDTH + OCM_L_DATA_RAM_ADDR_WIDTH         ;
    localparam integer unsigned OCM_ECC_INF_WIDTH                   = cal_ecc_l(OCM_ECC_DATA_WIDTH) + 1                             ;
    localparam integer unsigned OCM_ECC_CODE_WIDTH                  = OCM_ECC_DATA_WIDTH + OCM_ECC_INF_WIDTH                        ;

    typedef struct packed{
        logic                                     addr_range_error  ;                                
        logic [OCM_AXI_AWID_WIDTH-1:0]            awid              ;
        logic [OCM_AXI_ADDR_WIDTH-1:0]            awaddr            ;
        logic [OCM_AXI_LEN-1:0]                   awlen             ;
        logic [OCM_AXI_BURST_SIZE-1:0]            awsize            ;
        logic [1:0]                               awburst           ;    
    } pack_ocm_aw_pld;

    typedef struct packed{
        logic [OCM_AXI_DATA_WIDTH-1:0]            wdata             ;
        logic [OCM_AXI_DATA_WIDTH/8-1:0]          wstrb             ;
        logic                                     wlast             ;
    } pack_ocm_w_pld;

    typedef struct packed{
        logic                                     addr_range_error  ;                                
        logic [OCM_AXI_RID_WIDTH-1:0]             arid              ;
        logic [OCM_AXI_ADDR_WIDTH-1:0]            araddr            ;
        logic [OCM_AXI_LEN-1:0]                   arlen             ;
        logic [OCM_AXI_BURST_SIZE-1:0]            arsize            ;
        logic [1:0]                               arburst           ;    
    } pack_ocm_ar_pld;

    typedef struct packed{
        logic [OCM_AXI_RID_WIDTH-1:0]             rid       ;
        logic [OCM_AXI_DATA_WIDTH-1:0]            rdata     ;
        logic [1:0]                               rresp     ;
        logic                                     rlast     ;
    } pack_ocm_r_pld;

    typedef struct packed{
        logic [OCM_AXI_AWID_WIDTH-1:0]            bid       ;
        logic [1:0]                               bresp     ;        
    } pack_ocm_b_pld;

    typedef struct packed{
        logic                                     addr_range_error  ;                                
        logic [OCM_AXI_ID_WIDTH-1:0]              axid              ;
        logic [OCM_AXI_ADDR_WIDTH-1:0]            axaddr            ;
        logic [OCM_AXI_LEN-1:0]                   axlen             ;
        logic [OCM_AXI_BURST_SIZE-1:0]            axsize            ;
        logic [1:0]                               axburst           ;
        logic                                     op_is_rd          ;   
        logic [OCM_ROB_ENTRY_WIDTH-1:0]           rob_id            ; 
    } pack_ocm_ax_pld;

    typedef struct packed{
        logic                                     addr_range_error  ;                                
        logic [OCM_AXI_ID_WIDTH-1:0]              axid              ;
        logic [OCM_DATA_RAM_DEPTH-1:0]            data_ram_num      ;
        logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]     data_ram_addr     ;
        logic [OCM_AXI_LEN-1:0]                   axlen             ;
        logic [OCM_AXI_BURST_SIZE-1:0]            axsize            ;
        logic [1:0]                               axburst           ; 
        logic                                     op_is_rd          ;    
    } pack_ocm_rob_pld; 

    typedef struct packed{
        logic [OCM_AXI_AWID_WIDTH-1:0]            axid          ;
        logic [OCM_AXI_LEN-1:0]                   len           ;
        logic [OCM_DATA_RAM_DEPTH-1:0]            data_ram_num  ;  
        logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]     data_ram_addr ;  
    } pack_ocm_arb_req_pld;

    typedef struct packed{
        logic [OCM_ROB_ENTRY_WIDTH-1:0]           rob_id        ;    
        logic [OCM_AXI_AWID_WIDTH-1:0]            axid          ;
        logic [OCM_AXI_LEN-1:0]                   len           ;
        logic [OCM_DATA_RAM_DEPTH-1:0]            data_ram_num  ;  
        logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]     data_ram_addr ;  
        logic                                     rlast         ;
    } pack_ocm_arb_ack_pld;

    typedef struct packed{
        logic [OCM_ROB_ENTRY_WIDTH-1:0]             awid          ;
        logic [OCM_DATA_RAM_DEPTH-1:0]              data_ram_num  ;  
        logic [OCM_L_DATA_RAM_ADDR_WIDTH-1:0]       data_ram_addr ;  
        logic [OCM_L_DATA_RAM_DATA_WIDTH-1:0]       data          ;
        logic [OCM_AXI_LEN-1:0]                     data_msk      ;
    } pack_ocm_data_ram_wr_pld;

    function integer cal_ecc_l;
        input integer data_l;
        integer ecc_l;
        begin
            ecc_l = 1;
            while(2**ecc_l<data_l+ecc_l+1) ecc_l++;
            cal_ecc_l = ecc_l;
        end
    endfunction
endpackage