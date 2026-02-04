
# fcip_mem_spram_fake_2p

这个模块对外提供一读一写两个端口，两个端口都是valid/ready握手接口。

这个模块使用单口SRAM，在不MCP时，最大读写带宽也仅有1 R/W per cycle，为了缓解峰值带宽冲突问题，内置store buffer，用于缓冲写数据。

## Parameter 

| Parameter | Default Value | Constraint | Description |
| --- | --- | --- | --- |
| SRAM_ACCESS_LATENCY | 1 | >=1 | 说明外部集成的SRAM访问延迟|
| SRAM_REQ_PIPE_STAGE | 0 | >=0 | 定义发往SRAM的数据会打几拍|
| SRAM_RSP_PIPE_STAGE | 0 | >=0 | 定义从SRAM回来的数据会打几拍|
| SIDEBAND_WIDTH | 1 | >=1 | 定义sdieband位宽，sideband在输入侧与read addr一起传入，与对应的read data一起传出|
| DATA_WIDTH | 32 | >=1 | 定义SRAM数据位宽 |
| ADDR_WDITH | 10 | >=1 | 定义SRAM地址位宽 |
| MCP_CYCLE | 1 | >= 1| 定义一次读写SRAM需要多少个cycle，根据这个值设置multi cycle path|
| WRITE_BUFFER_SIZE | 0 | >= 0 | Write Buffer大小，定义为0时即不启用Write Buffer|
| RW_ARBITER_TYPE | 0 | 0 or 1 | 读写仲裁器类型，0为读优先仲裁，1为写优先仲裁|
| READ_FORWARD_EN | 0 | 1 or 0 | 决定是否启用forwarding，在启用时，Read Buffer延迟为0，否则为1|
| READ_BUFFER_SIZE| 2 | >= SRAM_ACCESS_LATENCY+SRAM_REQ_PIPE_STAGE+SRAM_RSP_PIPE_STAGE+1|
| WRITE_BIT_MASK_EN| 0 | 0 or 1| 是否打开bit mask，不打开时默认bit enable全为1|

这里面有很多个参数用来在timing和latency之间进行平衡：

- SRAM_ACCESS_LATENCY
- SRAM_REQ_PIPE_STAGE
- SRAM_RSP_PIPE_STAGE
- MCP_CYCLE
- READ_FORWARD_EN

请参考微架构图，评估每个部分的延迟大小，决定哪些pipe是要启用的，哪些pipe是不启用的。

例如，通常来说SRAM_RSP_PIPE_STAGE和READ_FORWARD_EN就有较大关联

- 如果SRAM CP to Q延迟较大，启用了SRAM_RSP_PIPE_STAGE=1，那么启用READ_FORWARD_EN通常是可以的，这部分forward逻辑不会和SRAM CP to Q在同一拍里。
- 但如果没启用SRAM_RSP_PIPE_STAGE，那么启用READ_FORWARD_EN会把SRAM延迟和forward延迟放在同一拍里，对timing可能是潜在的挑战，需要注意，因此如果不苛求延迟，如果没开RSP_PIPE，那么也不用打开FORWARD。

这种考虑在设计中很多见，IP提供了大量的灵活性用来fix timing，请根据微架构和物理实现斟酌如何配置。

NOTED:

- 如果当前输入不支持bit mask，建议关掉WRITE_BIT_MASK_EN。防止频率过高，timing有违例风险