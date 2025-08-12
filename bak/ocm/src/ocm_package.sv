package ocm_package;
//============================================
//=====================parameter
//============================================
    //=================AXI parameter 
    localparam integer unsigned OCM_AXI_DATA_WIDTH            = 1024                                                    ;
    localparam integer unsigned OCM_AXI_LEN_WIDTH             = 2                                                       ; //1~2
    localparam integer unsigned OCM_AXI_LEN_OH_WIDTH          = 1<<OCM_AXI_LEN_WIDTH                                    ;
    localparam integer unsigned OCM_AXI_ID_WIDTH              = 8                                                       ;
    localparam integer unsigned OCM_AXI_BURST_SIZE            = 3                                                       ;
    localparam integer unsigned OCM_AXI_STROB_SIZE            = 1024/8                                                  ;
    //=================ROB    
    localparam integer unsigned OCM_ROB_ENTRY_DEPTH           = 32                                                      ;
    localparam integer unsigned OCM_ROB_ENTRY_WIDTH           = $clog2(OCM_ROB_ENTRY_DEPTH)                             ;
    localparam integer unsigned OCM_OPCODE_WIDTH              = 2                                                       ; //0:INIT 1:READ 2:WRITE
    //=================Data buffer                                    
    localparam integer unsigned OCM_DATA_BUF_RAM_NUM          = 3                                                       ;
    //=================Data ram          
    localparam integer unsigned OCM_DATA_RAM_BANK_WIDTH       = 1024                                                    ;
    localparam integer unsigned OCM_DATA_RAM_BANK_NUM         = 4                                                       ;
    localparam integer unsigned OCM_DATA_RAM_BANK_NUM_WIDTH   = $clog2(OCM_DATA_RAM_BANK_NUM)                           ;
    localparam integer unsigned OCM_DATA_RAM_UNENC_DATA_WIDTH = OCM_DATA_RAM_BANK_WIDTH                                 ;
    localparam integer unsigned OCM_DATA_RAM_ADDR_DEPTH       = 8192                                                    ;
    localparam integer unsigned OCM_DATA_RAM_ADDR_WIDTH       = $clog2(OCM_DATA_RAM_ADDR_DEPTH)                         ;
    localparam integer unsigned OCM_DATA_RAM_SPLIT_NUM        = 2                                                       ;                                                       
    localparam integer unsigned OCM_DATA_RAM_MASK_WIDTH       = OCM_DATA_RAM_SPLIT_NUM                                  ;
    localparam integer unsigned OCM_DATA_RAM_SPLIT_DATA_WIDTH = OCM_DATA_RAM_BANK_WIDTH/OCM_DATA_RAM_SPLIT_NUM          ;
    localparam integer unsigned OCM_ECC_DATA_WIDTH            = OCM_DATA_RAM_UNENC_DATA_WIDTH + OCM_DATA_RAM_ADDR_WIDTH ;
    localparam integer unsigned OCM_ECC_CODE_WIDTH            = ($clog2(OCM_ECC_DATA_WIDTH)+OCM_ECC_DATA_WIDTH+1 <= 2**$clog2(OCM_ECC_DATA_WIDTH))? $clog2(OCM_ECC_DATA_WIDTH) :$clog2(OCM_ECC_DATA_WIDTH) + 1 ;
    localparam integer unsigned OCM_ECC_TOTAL_WIDTH           = OCM_ECC_DATA_WIDTH + OCM_ECC_CODE_WIDTH + 1             ;
    localparam integer unsigned OCM_DATA_RAM_DATA_WIDTH       = OCM_DATA_RAM_UNENC_DATA_WIDTH + OCM_ECC_CODE_WIDTH + 1  ;
    //=================Data pipe FIFO
    localparam integer unsigned OCM_DATA_FIFO_ADDR_WIDTH      = 8                                                       ;                              
    //=================REQ arbiter    
    localparam integer unsigned OCM_REQ_ARB_DEPTH             = 2                                                       ;
    localparam integer unsigned OCM_INIT_ADDR_WIDTH           = OCM_DATA_RAM_BANK_NUM_WIDTH + OCM_DATA_RAM_ADDR_WIDTH   ;
    localparam integer unsigned OCM_SPLIT_DATA_B_WIDTH        = OCM_DATA_RAM_SPLIT_DATA_WIDTH/8                         ;
    localparam integer unsigned OCM_AXI_ADDR_WIDTH            = OCM_DATA_RAM_BANK_NUM_WIDTH + OCM_DATA_RAM_ADDR_WIDTH + OCM_SPLIT_DATA_B_WIDTH + OCM_DATA_RAM_SPLIT_NUM - 1;  //num_width + addr_width + log2(512/8) + (1024/512 -1)
    localparam integer unsigned OCM_AXI_LEN_MAX               = 3                                                       ;
    localparam integer unsigned OCM_ROB_MASK_WIDTH            = OCM_AXI_LEN_MAX*OCM_DATA_RAM_SPLIT_NUM                  ;

//============================================
//=====================axi package
//============================================
    typedef struct packed{
        logic [OCM_AXI_ID_WIDTH-1:0]            id            ;
        logic [OCM_AXI_ADDR_WIDTH-1:0]          addr          ;
        logic [OCM_AXI_LEN_WIDTH-1:0]           len           ;
        logic [OCM_AXI_BURST_SIZE-1:0]          size          ;
        logic [1:0]                             burst         ;    
    } pack_ocm_ax_pld;

    typedef struct packed{
        logic [OCM_AXI_DATA_WIDTH-1:0]          wdata         ;
        logic [OCM_AXI_STROB_SIZE-1:0]          wstrb         ;
        logic                                   wlast         ;
    } pack_ocm_w_pld;
    
    typedef struct packed{
        logic [OCM_AXI_ID_WIDTH-1:0]            rid           ;
        logic [OCM_AXI_DATA_WIDTH-1:0]          rdata         ;
        logic [1:0]                             rresp         ;
        logic                                   rlast         ;
    } pack_ocm_r_pld;
    
    typedef struct packed{
        logic [OCM_AXI_ID_WIDTH-1:0]            bid           ;
        logic [1:0]                             bresp         ;        
    } pack_ocm_b_pld;     
//============================================
//=====================ocm package
//============================================
    typedef struct packed{
        pack_ocm_ax_pld                         axpld           ;
        logic [1:0]                             opcode          ;
    }pack_ocm_req_arb_ack_pld;

    typedef struct packed{
        logic [OCM_AXI_ID_WIDTH-1:0]            id              ;
        logic [2:0]                             resp            ;
        logic [OCM_AXI_BURST_SIZE-1:0]          size            ;
        logic [1:0]                             burst           ;   
        logic [OCM_ROB_MASK_WIDTH-1:0]          len_msk         ;
        logic [OCM_OPCODE_WIDTH-1:0]            opcode          ;
        logic [OCM_DATA_RAM_BANK_NUM_WIDTH-1:0] ram_num         ;
        logic [OCM_DATA_RAM_ADDR_WIDTH-1:0]     ram_addr        ;
    }pack_ocm_rob_req_pld;

    typedef struct packed{
        logic [OCM_AXI_ID_WIDTH-1:0]            id              ;
        logic [OCM_DATA_RAM_MASK_WIDTH-1:0]     data_msk        ;
        logic                                   last            ;
        logic [2:0]                             resp            ;
    } pack_ocm_ram_bypass_pld;

    typedef struct packed{
        logic [OCM_ROB_ENTRY_WIDTH-1:0]         rob_id          ;    
        logic [OCM_DATA_RAM_BANK_NUM_WIDTH-1:0] ram_num         ;
        logic [OCM_DATA_RAM_ADDR_WIDTH-1:0]     ram_addr        ;
        logic [OCM_OPCODE_WIDTH-1:0]            opcode          ;
        pack_ocm_ram_bypass_pld                 ram_bps_pld     ;
    }pack_ocm_rob_ack_pld;

    typedef struct packed{
        logic [OCM_DATA_RAM_ADDR_WIDTH-1:0]     addr            ;
        logic                                   en              ;
        logic                                   wr              ;
        pack_ocm_ram_bypass_pld                 ram_bps_pld     ;
    } pack_ocm_ram_wrapper_in_pld;

    typedef struct packed{
        logic [OCM_DATA_RAM_UNENC_DATA_WIDTH-1:0]   dout        ;
        pack_ocm_ram_bypass_pld                     ram_bps_pld ;
    } pack_ocm_ram_wrapper_out_pld;
    
endpackage