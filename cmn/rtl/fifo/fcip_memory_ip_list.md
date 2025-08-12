

# FCIP Memory IP list

FCIP Memory IP指在提供一组高性能、高度抽象、高度Physical Aware的memory ip。并提供足够灵活的选项让用户在Area/Latency/Freq之间进行权衡。


| Class | IP                     | Description                                                  | Status |
| ---   | ---                    | -----------                                                  | ------ |
| BASIC | fcip_mem_ctrl_wrap     | SRAM封装，输入接口为valid/ready，输出为en，封装了MCP和Pipeline  | ongoing |
| FIFO  | fcip_sync_fifo_reg     | 基于reg实现的同步FIFO                                         | ongoing |
|       | fcip_sync_fifo_spram   | 基于单口SRAM实现的同步FIFO，通过多个SRAM动态分配实现满读写带宽    | ongoing |
|       | fcip_sync_fifo_dpram   | 基于双口SRAM实现的同步FIFO                                     | toto |
|       | fcip_async_fifo        | 基于reg实现的异步FIFO                                          | ongoing |
| MEM   | fcip_mem_spram_fake_2p | 单口sram封装，提供一读一写，基于valid/ready握手的访问接口        |   ongoing     |
|       | fcip_mem_spram         | 单口sram封装，提供一个读写，基于valid/ready握手的访问接口        |    todo        |
|       | fcip_mem_dpram         | 双口sram封装，提供一读一写，基于valid/ready握手的访问接口        |    todo        |
| MODEL | fcip_spram_model       | 单口SRAM行为模型| todo |
|       | fcip_dpram_model       | 双口SRAM行为模型| todo|


