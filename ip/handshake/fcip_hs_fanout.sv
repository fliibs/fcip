module fcip_hs_fanout #(
    parameter integer unsigned FANOUT_NUM = 4,
    parameter type             PLD_TYPE   = logic
) (
    input  logic                    clk,
    input  logic                    rst_n,
    // slv port
    input  logic                    slv_vld,
    input  PLD_TYPE                 slv_pld,
    output logic                    slv_rdy,

    // mst ports
    output logic [FANOUT_NUM-1:0]   v_mst_vld,
    output PLD_TYPE                 mst_pld,
    input  logic [FANOUT_NUM-1:0]   v_mst_rdy
);
//===================================================================
// Internal logic 
//===================================================================
    // pld buffer
    PLD_TYPE                buf_pld;
    logic                   buf_vld;
    
    // mst side
    logic                   all_consumed;
    logic [FANOUT_NUM-1:0]  v_is_consumed;

//===================================================================
// SLV side handshake
//===================================================================
    always_comb begin
        if ( ~buf_vld ) 
            slv_rdy = 1'b1;
        else if ( all_consumed )
            slv_rdy = 1'b1;
        else 
            slv_rdy = 1'b0; 
    end

//===================================================================
// PLD Buf
//===================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if ( ~rst_n ) 
            buf_vld <= 1'b0;
        else if ( slv_vld && slv_rdy )
            buf_vld <= 1'b1;
        else if ( all_consumed )
            buf_vld <= 1'b0; 
    end

    always_ff @(posedge clk) begin
        if (slv_vld && slv_rdy) begin
            buf_pld <= slv_pld;
        end
    end

//===================================================================
// MST side handshake
//===================================================================
    assign mst_pld      = buf_pld;
    assign all_consumed = &v_is_consumed || // consume multiple cycle 
                          (buf_vld && (&v_mst_rdy)); // consume nxt cycle   
;

    generate 
        for (genvar i=0; i< FANOUT_NUM; i++) begin: G_MST_HS
            always_ff @(posedge clk or negedge rst_n) begin
                if (~rst_n) 
                    v_is_consumed[i] <= 1'b0;
                else if ( slv_vld && slv_rdy ) // clear
                    v_is_consumed[i] <= 1'b0;
                else if ( v_mst_vld[i] && v_mst_rdy[i] ) // consumed
                    v_is_consumed[i] <= 1'b1;
            end
            
            assign v_mst_vld[i] = buf_vld && (~v_is_consumed[i]);
        end

    endgenerate

endmodule                                                                                                                                                                 