module fcip_mem_fake_find_new_bit #(
    parameter integer unsigned ADDR_WIDTH = 8,
    parameter integer unsigned DATA_WIDTH = 128,
    parameter integer unsigned WRITE_BUFFER_SIZE =16,
    parameter integer unsigned PTR_WIDTH =6
)(
    input  logic                            cmp_vld,
    input  logic [ADDR_WIDTH-1:0]           cmp_addr,

    input  logic [DATA_WIDTH-1:0]           cmp_array_data[WRITE_BUFFER_SIZE-1:0],
    input  logic [ADDR_WIDTH-1:0]           cmp_array_addr[WRITE_BUFFER_SIZE-1:0],
    input  logic [DATA_WIDTH-1:0]           cmp_array_bit_en[WRITE_BUFFER_SIZE-1:0],
    input  logic [WRITE_BUFFER_SIZE-1:0]    array_vld,
    input  logic [PTR_WIDTH-1:0]            wr_ptr,

    output logic                            cmp_hit,
    output logic [DATA_WIDTH-1:0]           cmp_hit_data,
    output logic [DATA_WIDTH-1:0]           cmp_hit_bit_en
);

logic [WRITE_BUFFER_SIZE-1:0] array_data_switch[DATA_WIDTH-1:0];

logic [WRITE_BUFFER_SIZE-1:0] cmp_hit_bit[DATA_WIDTH-1:0];
logic [WRITE_BUFFER_SIZE-1:0] mask_en;
logic [WRITE_BUFFER_SIZE-1:0] cmp_hit_onehot;

logic [WRITE_BUFFER_SIZE-1:0] hazard_check_bit_forward[DATA_WIDTH-1:0];
logic [WRITE_BUFFER_SIZE-1:0] hazard_check_bit_forward_oh[DATA_WIDTH-1:0];
logic [DATA_WIDTH-1:0]        hazard_check_bit_forward_en;

logic [WRITE_BUFFER_SIZE-1:0] hazard_check_bit_backward[DATA_WIDTH-1:0];
logic [WRITE_BUFFER_SIZE-1:0] hazard_check_bit_backward_oh[DATA_WIDTH-1:0];
logic [DATA_WIDTH-1:0]        hazard_check_bit_backward_en;

logic [WRITE_BUFFER_SIZE-1:0] multi_hit_addr_index[DATA_WIDTH-1:0];

generate

    for(genvar i=0;i<WRITE_BUFFER_SIZE;i++)begin
        assign mask_en[i]           = (i<=(WRITE_BUFFER_SIZE'(wr_ptr-1))); 
        assign cmp_hit_onehot[i]    = cmp_vld && (cmp_addr == cmp_array_addr[i]) && array_vld[i];
    end

    for(genvar i=0; i<DATA_WIDTH; i++ )begin:LOOP_FOR_BIT
        for(genvar j=0;j<WRITE_BUFFER_SIZE; j++)begin:LOOP_FOR_BUFFER_SIZE
            assign cmp_hit_bit[i][j]        = cmp_vld && (cmp_addr == cmp_array_addr[j]) && array_vld[j] && cmp_array_bit_en[j][i];
            assign array_data_switch[i][j]  = cmp_array_data[j][i];
        end
    end 

    for(genvar i=0; i<DATA_WIDTH; i++ )begin:LOOP_FOR_BIT_CHECK
        for(genvar j=0;j<WRITE_BUFFER_SIZE; j++)begin:LOOP_FOR_BUFFER_SIZE_CHECK
            assign hazard_check_bit_forward[i][j]  = cmp_hit_bit[i][j] && mask_en[j];
            assign hazard_check_bit_backward[i][j] = cmp_hit_bit[i][j] && ~mask_en[j];
        end
    end

    for(genvar i=0; i<DATA_WIDTH; i++ )begin:GET_HIT_BIT
        assign multi_hit_addr_index[i] = hazard_check_bit_forward_en[i] ? hazard_check_bit_forward_oh[i] : hazard_check_bit_backward_oh[i];
        assign cmp_hit_bit_en[i]       = (|hazard_check_bit_forward_en[i]) || (|hazard_check_bit_backward_en[i]);
        assign cmp_hit_data[i]         = |(array_data_switch[i] & multi_hit_addr_index[i]);
    end

    for(genvar i=0;i<DATA_WIDTH;i++)begin:BIT_HAZARD_LEAD_ONE
        fcip_lead_one_msb #(
            .ENTRY_NUM      (WRITE_BUFFER_SIZE   )
        ) u_hazard_bit_forward_lead_one(
            .v_entry_vld    (hazard_check_bit_forward[i]),
            .v_free_idx_oh  (hazard_check_bit_forward_oh[i]),
            .v_free_idx_bin (),
            .v_free_vld     (hazard_check_bit_forward_en[i] )
        );

        fcip_lead_one_msb #(
            .ENTRY_NUM      (WRITE_BUFFER_SIZE   )
        ) u_hazard_bit_backward_lead_one(
            .v_entry_vld    (hazard_check_bit_forward[i]),
            .v_free_idx_oh  (hazard_check_bit_backward_oh[i]),
            .v_free_idx_bin (),
            .v_free_vld     (hazard_check_bit_backward_en[i] )
        );
    end
    
endgenerate

assign cmp_hit = |cmp_hit_onehot;

endmodule