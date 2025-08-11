# fcip_mem_ctrl_wrap

这个模块对memory又进行一层包装，用来解决物理实现上的各种问题。

这个模块在输入侧使用valid/ready接口，因为MCP的存在可能导致反压。在输出侧保留了enable接口。



## Memory I/O Pipeline

在memory warpper之外，对SRAM进出的路径又进行额外的打拍，用来应对SRAM组到数字逻辑之间的长距离路由可能产生的timing问题。


## Flow Control/SRAM Marker

这两个模块配套使用。在RTL中加入了SRAM Marker，用来找到这个模块连接的memory wrapper，并且通过marker的instance name来判断function层面对模块MCP可以放松到几拍。随后对SRAM设置对应的MCP。

Flow Control用来完成MCP需要的反压，即MCP2意味着每隔cycle反压前级一次。


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


这些参数在大部分使用了SRAM的模块中都会定义。