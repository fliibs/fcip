module fcip_ip_mimo_queue #(
    parameter int unsigned DEPTH    = 128,
    parameter int unsigned WR_WIDTH = 4,
    parameter int unsigned RD_WIDTH = 4,
    parameter type         PLD_TYPE = logic
)(
    input  logic                                        clk,
    input  logic                                        rst_n,
    
    // WRITE REQ channel
    output logic            [WR_WIDTH-1:0]              v_req_rdy,
    input  logic            [WR_WIDTH-1:0]              v_req_vld,
    input  PLD_TYPE                                     v_req_pld            [WR_WIDTH-1:0],

    // READ ACK channel
    output logic            [RD_WIDTH-1:0]              v_ack_vld,
    input  logic            [RD_WIDTH-1:0]              v_ack_rdy,
    output PLD_TYPE                                     v_ack_pld            [RD_WIDTH-1:0]

);

//============================================================
// Internal parameters
//============================================================
    localparam  int unsigned CRDT_CNT_WIDTH   = $clog2(DEPTH)+1;
    localparam  int unsigned DEPTH_WIDTH      = $clog2(DEPTH);
    localparam  int unsigned WRITE_NUM_WIDTH  = $clog2(WR_WIDTH)+1;
    localparam  int unsigned READ_NUM_WIDTH   = $clog2(RD_WIDTH)+1;
    localparam  int unsigned PTR_WIDTH        = $clog2(DEPTH)+1;

//============================================================
// Internal logic
//============================================================
    // credit counter
    logic           [CRDT_CNT_WIDTH-1:0]            crdt_cnt;
    logic           [CRDT_CNT_WIDTH-1:0]            crdt_cal;
    logic           [CRDT_CNT_WIDTH-1:0]            crdt_sub;
    logic           [CRDT_CNT_WIDTH-1:0]            crdt_add;
    logic           [CRDT_CNT_WIDTH-1:0]            crdt_residue;

    // read / write num accumulation
    logic           [WRITE_NUM_WIDTH-1:0]           v_write_num_acc       [WR_WIDTH-1:0];
    logic           [READ_NUM_WIDTH-1:0]            v_read_num_acc        [RD_WIDTH-1:0];

    // queue entry
    PLD_TYPE                                        queue_entry           [DEPTH   -1:0];

    // read / write pointer
    logic           [PTR_WIDTH-1:0]                 wr_ptr;
    logic           [PTR_WIDTH-1:0]                 rd_ptr;
    logic           [PTR_WIDTH-1:0]                 v_wr_add_ptr          [WR_WIDTH-1:0];
    logic           [PTR_WIDTH-1:0]                 v_rd_add_ptr          [RD_WIDTH-1:0];

    // control signal
    logic                                           wren;
    logic                                           rden;
    PLD_TYPE                                        wr_entry_data_map     [DEPTH   -1:0];
    logic           [DEPTH-1:0]                     wr_entry_en_map;


//===========================================================================
//  Handshake
//===========================================================================
    // Allow input only when there is enough credit
    generate
        for (genvar i=0; i<WR_WIDTH; i=i+1) begin: GEN_WR_REQ_RDY
            assign v_req_rdy[i] = crdt_residue >= CRDT_CNT_WIDTH'(i+1);
        end
    endgenerate
    //
    generate 
        for(genvar i = 0; i < RD_WIDTH; i=i+1) begin: GEN_RD_ACK_VLD
            assign v_ack_vld[i] = (crdt_cnt>CRDT_CNT_WIDTH'(i));
        end
    endgenerate

//===========================================================================
// Read/Write Num
//===========================================================================

    // write num
    generate 
        for (genvar i = 0; i < WR_WIDTH; i=i+1) begin: GEN_WR_NUM
            if (i==0)   assign v_write_num_acc[i] = WRITE_NUM_WIDTH'(v_req_vld[i] && v_req_rdy[i]);
            else        assign v_write_num_acc[i] = WRITE_NUM_WIDTH'((v_req_vld[i] && v_req_rdy[i]) + v_write_num_acc[i-1]);
        end
    endgenerate 

    // read num 
    generate 
        for(genvar i = 0; i < RD_WIDTH; i=i+1) begin: GEN_RD_NUM
            if(i==0)    assign v_read_num_acc[i] = READ_NUM_WIDTH'(v_ack_vld[i] && v_ack_rdy[i]);
            else        assign v_read_num_acc[i] = READ_NUM_WIDTH'((v_ack_vld[i] && v_ack_rdy[i]) + v_read_num_acc[i-1]);
        end 
    endgenerate 

    


//===========================================================================
// credit counter
//===========================================================================
    assign crdt_residue = CRDT_CNT_WIDTH'(DEPTH - crdt_cnt);
    assign crdt_add     = v_write_num_acc[WR_WIDTH-1] & {WRITE_NUM_WIDTH{wren}};
    assign crdt_sub     = v_read_num_acc[RD_WIDTH-1] & {READ_NUM_WIDTH{rden}};
    assign crdt_cal     = crdt_add - crdt_sub;

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)              crdt_cnt <= {CRDT_CNT_WIDTH{1'b0}};
        else if(wren|rden)      crdt_cnt <= CRDT_CNT_WIDTH'(crdt_cnt + crdt_cal);
    end


//===========================================================================
// Read/Write pointer
//===========================================================================
    assign wren = |(v_req_rdy & v_req_vld);
    assign rden = |(v_ack_rdy|v_ack_vld);

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)          wr_ptr <= {PTR_WIDTH{1'b0}};
        else if(wren)       wr_ptr <= PTR_WIDTH'(wr_ptr + v_write_num_acc[WR_WIDTH-1]);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)          rd_ptr <= {PTR_WIDTH{1'b0}};
        else if(rden)       rd_ptr <= PTR_WIDTH'(rd_ptr + v_read_num_acc[RD_WIDTH-1]);
    end

    // read entry ptr
    generate 
        for (genvar i = 0; i < RD_WIDTH; i=i+1) begin: GEN_RD_DATA
            assign v_rd_add_ptr[i]      = PTR_WIDTH'(rd_ptr + i);
            assign v_ack_pld[i]         = queue_entry[v_rd_add_ptr[i][DEPTH_WIDTH-1:0]];
        end
    endgenerate 

    // write entry ptr
    generate 
        for (genvar i = 0; i < WR_WIDTH; i=i+1) begin: GEN_WR_PTR 
            assign v_wr_add_ptr[i] = PTR_WIDTH'(wr_ptr + i);
        end
    endgenerate 

//===========================================================================
// write req -> bitmap
//===========================================================================
    generate
        for (genvar i=0; i<DEPTH; i=i+1) begin: GEN_ENTRY_WR_REMAP
            always_comb begin
            // init
                wr_entry_data_map[i] = {$bits(PLD_TYPE){1'b0}};
                wr_entry_en_map[i]   = 1'b0;
                for (integer j=0; j<WR_WIDTH; j=j+1) begin
                    if(v_req_rdy[j] && v_req_vld[j] && v_wr_add_ptr[j][DEPTH_WIDTH-1:0]==DEPTH_WIDTH'(i)) begin 
                        wr_entry_data_map[i] = wr_entry_data_map[i] | v_req_pld[j];
                        wr_entry_en_map[i]   = wr_entry_en_map[i]   | 1'b1;
                    end
                end
            end
        end
    endgenerate
//===========================================================================
// queue entry
//===========================================================================
    generate
        for (genvar i = 0; i < DEPTH; i=i+1) begin: GEN_QUEUE_ENTRY
            always_ff @(posedge clk or negedge rst_n) begin 
                if (~rst_n) begin
                    queue_entry[i] <= {$bits(PLD_TYPE){1'b0}};
                end
                else if(wr_entry_en_map[i]) begin 
                    queue_entry[i] <= wr_entry_data_map[i];
                end
            end
        end
    endgenerate
    
    

endmodule