# FCIP IP List

> FCIP (Foundation Common IP) 通用基础IP库，提供SoC设计中常用的基础逻辑模块。

## IP 总览

| 序号 | 分类 | IP 名称 | 功能描述 |
|------|------|---------|----------|
| 1 | arbiter | `fcip_arb_vrp` | 多模式仲裁器顶层（支持Fix Priority/Round Robin/Age Matrix/PLRU四种模式），带valid-ready-payload握手接口 |
| 2 | arbiter | `fcip_arb_vrp_matrix` | 基于外部矩阵的仲裁器（带payload数据通路），valid-ready握手 |
| 3 | arbiter | `fcip_arb_vr_matrix` | 基于外部矩阵的仲裁器（无payload），valid-ready握手 |
| 4 | arbiter | `fcip_arb_matrix` | 矩阵仲裁核心逻辑，根据优先级矩阵和请求向量生成grant |
| 5 | arbiter | `fcip_fix_arb` | 两输入固定优先级仲裁器，priority端口优先 |
| 6 | arbiter | `fcip_grant_gen_fp` | 固定优先级grant生成器，支持两级优先级分组 |
| 7 | arbiter | `fcip_grant_gen_rr` | Round-Robin grant生成器，基于掩码的轮询仲裁 |
| 8 | arbiter | `fcip_age_matrix` | 年龄矩阵生成器（单次分配），维护条目间的年龄优先关系 |
| 9 | arbiter | `fcip_age_matrix_list` | 年龄矩阵生成器（多次分配），支持每周期多个分配操作 |
| 10 | arbiter | `fcip_mtx_gen_age` | 年龄矩阵生成模块（与fcip_age_matrix功能等价，独立封装） |
| 11 | arbiter | `fcip_mtx_gen_plru_tree` | Pseudo-LRU树形矩阵生成器，使用二叉树节点维护PLRU状态 |
| 12 | arbiter | `fcip_tree_plru_comb` | PLRU树形矩阵纯组合逻辑版本，提供节点更新和矩阵转换 |
| 13 | async_fifo | `fcip_afifo` | 异步FIFO顶层模块，集成写侧(slv)和读侧(mst)，支持跨时钟域数据传输 |
| 14 | async_fifo | `fcip_afifo_slv` | 异步FIFO写侧（slave端），处理写指针、满检测、CDC同步 |
| 15 | async_fifo | `fcip_afifo_mst` | 异步FIFO读侧（master端），处理读指针、空检测、CDC同步 |
| 16 | async_fifo | `fcip_afifo_doub` | 双倍数据线宽异步FIFO顶层，支持DOUBLE_DATA_WIRE模式 |
| 17 | async_fifo | `fcip_afifo_slv_doub` | 双倍数据线宽异步FIFO写侧 |
| 18 | async_fifo | `fcip_afifo_mst_doub` | 双倍数据线宽异步FIFO读侧 |
| 19 | async_fifo | `fcip_axi_afifo` | AXI协议异步FIFO，支持AW/W/B/AR/R五通道跨时钟域传输 |
| 20 | async_fifo | `fcip_axi_afifo_slv` | AXI异步FIFO写侧（slave时钟域） |
| 21 | async_fifo | `fcip_axi_afifo_mst` | AXI异步FIFO读侧（master时钟域） |
| 22 | async_fifo | `fcip_req_rsp_afifo` | Request-Response异步FIFO，双向通道（请求+响应）跨时钟域传输 |
| 23 | async_fifo | `fcip_req_rsp_afifo_slv` | Req-Rsp异步FIFO slave侧 |
| 24 | async_fifo | `fcip_req_rsp_afifo_mst` | Req-Rsp异步FIFO master侧 |
| 25 | async_fifo | `fcip_apb_afifo` | APB协议异步FIFO（预留，尚未实现） |
| 26 | basic | `fcip_bin2onehot` | 二进制编码转独热码 |
| 27 | basic | `fcip_onehot2bin` | 独热码转二进制编码 |
| 28 | basic | `fcip_onehot_mux_pld` | 基于独热码选择的多路payload复用器（支持参数化类型） |
| 29 | basic | `fcip_real_mux_onehot` | 基于独热码选择的多路数据复用器（转置+与门实现） |
| 30 | basic | `fcip_onehot_demux` | 基于独热码的数据解复用器（1-to-N），带握手接口 |
| 31 | basic | `fcip_lead_one` | 前导1检测器（LSB优先），输出独热码和二进制索引 |
| 32 | basic | `fcip_lead_one_msb` | 前导1检测器（MSB优先），输出独热码和二进制索引 |
| 33 | basic | `fcip_lead_one_rev` | 反向前导1检测器（高位优先查找），输出独热码和二进制索引 |
| 34 | basic | `fcip_list_lead_one` | 多路前导1检测器（LSB优先），支持连续多个空闲位查找 |
| 35 | basic | `fcip_list_lead_one_rev` | 多路反向前导1检测器（MSB优先），支持连续多个空闲位查找 |
| 36 | basic | `fcip_list_lead_zero` | 多路前导0检测器，支持连续多个空闲条目分配 |
| 37 | basic | `fcip_rob_id_dec` | ROB ID解码器，将二进制索引+使能转换为独热使能向量 |
| 38 | basic | `fcip_rob_prealloc` | ROB预分配器，从空闲位向量中选择一个空闲项分配 |
| 39 | basic | `fcip_lfsr4` | 4位线性反馈移位寄存器，多项式x⁴+x+1 |
| 40 | basic | `fcip_booth_wallace_mul` | Booth-Wallace乘法器，基于Booth编码+Wallace树结构 |
| 41 | basic | `fcip_ip_mimo_queue` | 多入多出(MIMO)队列，支持多端口同时读写 |
| 42 | handshake | `fcip_hs_fanout` | 握手信号扇出模块，将1个slave接口扇出到N个master接口 |
| 43 | mem_model | `fcip_dpram_model` | 双端口RAM仿真模型，支持HEX文件加载和调试输出 |
| 44 | mem_model | `fcip_spram_model` | 单端口RAM仿真模型，支持HEX文件加载和调试输出 |
| 45 | memory | `fcip_mem_ctrl_wrap` | SRAM控制器封装，支持可配置访问延迟、流水线级数、MCP周期 |
| 46 | memory | `fcip_mem_fake_2p_mem` | 伪双端口内存控制器，使用单端口SRAM模拟读写双端口，带写缓冲和读转发 |
| 47 | memory | `fcip_mem_fake_write_buffer` | 伪双端口内存的写缓冲模块，支持地址比对和数据转发 |
| 48 | memory | `fcip_mem_fake_find_new_bit` | 伪双端口内存的最新位查找模块，实现写缓冲中的数据hazard检测 |
| 49 | regslice | `fcip_reg_slice` | 寄存器切片，支持Full/Forward/Backward三种模式的流水线打拍 |
| 50 | regslice | `fcip_reg_slice_full_set` | 带同步置位(set)的Full模式寄存器切片 |
| 51 | stdcell_wrap | `fcip_sync_cell` | CDC同步单元，支持多级同步、异步复位/置位，自动选择arst/aset |
| 52 | stdcell_wrap | `fcip_sync_arst` | 多级同步器（异步低有效复位），支持扫描链 |
| 53 | stdcell_wrap | `fcip_sync_aset` | 多级同步器（异步低有效置位），支持扫描链 |
| 54 | stdcell_wrap | `fcip_clk_marker` | 时钟标记Buffer，用于CDC约束标记，支持多种VT类型 |
| 55 | stdcell_wrap | `fcip_marker` | 数据通路标记Buffer，用于物理约束标记，支持多种VT类型 |
| 56 | stdcell_wrap | `fcip_data_pipe` | 数据流水线打拍模块，可配置流水级数 |
| 57 | sync_fifo | `fcip_sync_fifo_reg` | 基于寄存器的同步FIFO，支持前向转发、almost full/empty |
| 58 | sync_fifo | `fcip_sync_fifo_reg_mimo` | 基于寄存器的多入多出同步FIFO，支持多端口同时读写 |
| 59 | sync_fifo | `fcip_sync_fifo_spram` | 基于SRAM的同步FIFO顶层，支持多SRAM分组、ROB缓冲 |
| 60 | sync_fifo | `fcip_sfifo_spram_ctrl` | SRAM同步FIFO控制器，管理多SRAM组的读写调度和LUT |
| 61 | sync_fifo | `fcip_sfifo_spram_ptr_ctrl` | SRAM同步FIFO指针控制器，管理单组SRAM的读写指针 |
| 62 | sync_fifo | `fcip_sfifo_spram_rob` | SRAM同步FIFO的ROB重排序缓冲，支持乱序写入顺序读出 |

## 分类统计

| 分类 | IP数量 | 说明 |
|------|--------|------|
| arbiter | 12 | 仲裁器相关模块（多种仲裁策略） |
| async_fifo | 12 | 异步FIFO（基础/AXI/Req-Rsp/双倍线宽） |
| basic | 16 | 基础逻辑模块（编码转换/前导检测/MUX/乘法器/队列等） |
| handshake | 1 | 握手信号处理模块 |
| mem_model | 2 | 存储器仿真模型 |
| memory | 4 | 存储器控制封装 |
| regslice | 2 | 寄存器切片（流水线打拍） |
| stdcell_wrap | 6 | 标准单元封装（CDC同步/标记/流水线） |
| sync_fifo | 6 | 同步FIFO（寄存器型/SRAM型） |
| **合计** | **62** | |

## 依赖关系

```
fcip_arb_vrp
├── fcip_real_mux_onehot
├── fcip_grant_gen_fp
├── fcip_grant_gen_rr
├── fcip_mtx_gen_age
│   └── (与fcip_age_matrix相同逻辑)
├── fcip_mtx_gen_plru_tree
└── fcip_arb_matrix

fcip_afifo
├── fcip_afifo_slv
│   ├── fcip_clk_marker
│   ├── fcip_fix_arb
│   ├── fcip_sync_cell
│   │   ├── fcip_sync_arst
│   │   └── fcip_sync_aset
│   └── fcip_marker
└── fcip_afifo_mst
    ├── fcip_clk_marker
    ├── fcip_sync_cell
    └── fcip_marker

fcip_sync_fifo_spram
├── fcip_sfifo_spram_ctrl
│   ├── fcip_sfifo_spram_ptr_ctrl
│   ├── fcip_grant_gen_rr
│   ├── fcip_sync_fifo_reg
│   └── fcip_reg_slice
├── fcip_mem_ctrl_wrap
│   ├── fcip_marker
│   └── fcip_data_pipe
│       └── fcip_sync_arst
└── fcip_sfifo_spram_rob

fcip_lead_one / fcip_list_lead_one / fcip_list_lead_zero
└── fcip_onehot2bin

fcip_rob_prealloc
└── fcip_lead_one

fcip_rob_id_dec
└── fcip_bin2onehot
```
