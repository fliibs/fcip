# FCIP Memory Controller Wrapper Design Specification

## 1. 概述

`fcip_mem_ctrl_wrap` 是SRAM控制器封装模块，在逻辑接口和物理SRAM之间提供统一的valid-ready握手协议，支持可配置的SRAM访问延迟、请求/响应流水线级数以及多周期端口（MCP）访问。

**所属分类：** memory  
**文件路径：** `ip/memory/fcip_mem_ctrl_wrap/fcip_mem_ctrl_wrap.sv`

## 2. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| SRAM_ACCESS_LATENCY | integer unsigned | 1 | SRAM内部访问延迟（周期） |
| SRAM_REQ_PIPE_STAGE | integer unsigned | 0 | 请求路径流水线级数 |
| SRAM_RSP_PIPE_STAGE | integer unsigned | 0 | 响应路径流水线级数 |
| SIDEBAND_WIDTH | integer unsigned | 1 | 旁路信息位宽（如ROB ID等） |
| DATA_WIDTH | integer unsigned | 32 | 数据位宽 |
| ADDR_WIDTH | integer unsigned | 10 | 地址位宽 |
| MCP_CYCLE | integer unsigned | 1 | 多周期端口访问周期数（1=单周期） |

### 内部参数

| 参数名 | 计算公式 | 描述 |
|--------|----------|------|
| DATA_PIPE_LATENCY | SRAM_ACCESS_LATENCY + REQ_PIPE + RSP_PIPE | 总数据通路延迟 |

## 3. 接口信号

### 3.1 逻辑侧（请求-响应）

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| mem_req_vld | input | 1 | 请求有效 |
| mem_req_rdy | output | 1 | 请求就绪 |
| mem_req_opcode | input | 1 | 操作码（0=读，1=写） |
| mem_req_addr | input | ADDR_WIDTH | 请求地址 |
| mem_req_data | input | DATA_WIDTH | 写数据 |
| mem_req_bit_en | input | DATA_WIDTH | 写位掩码 |
| mem_req_sideband | input | SIDEBAND_WIDTH | 旁路信息 |
| mem_rsp_en | output | 1 | 读响应使能 |
| mem_rsp_sideband | output | SIDEBAND_WIDTH | 响应旁路信息 |
| mem_rsp_data | output | DATA_WIDTH | 读响应数据 |

### 3.2 物理SRAM侧

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| spram_addr | output | ADDR_WIDTH | SRAM地址 |
| spram_din | output | DATA_WIDTH | SRAM写数据 |
| spram_dout | input | DATA_WIDTH | SRAM读数据 |
| spram_bit_en | output | DATA_WIDTH | SRAM位使能 |
| spram_en | output | 1 | SRAM使能 |
| spram_wren | output | 1 | SRAM写使能 |

## 4. 功能描述

### 4.1 多周期端口（MCP）流控
- MCP_CYCLE=1：`mem_req_rdy` 恒为1
- MCP_CYCLE>1：使用计数器 `mcp_cnt`，仅 `mcp_cnt==0` 时 ready
  - 握手成功后计数器递增，达到 MCP_CYCLE-1 后重置

### 4.2 SRAM接口映射
- 读操作：`spram_bit_en = 全1`
- 写操作：`spram_bit_en = mem_req_bit_en`

### 4.3 响应路径
- `mem_rsp_data` 经过 `fcip_marker` 缓冲（CDC/STA约束标记点）
- `mem_rsp_en` 和 `mem_rsp_sideband` 经过 `fcip_data_pipe` 延迟 DATA_PIPE_LATENCY 周期

### 4.4 依赖模块
- `fcip_marker`：数据路径标记缓冲
- `fcip_data_pipe`：多级流水线延迟

## 5. 验证关键点与测试用例

| TC | 场景 | 预期 |
|----|------|------|
| 001 | 单周期读（MCP=1） | 下一周期rsp_en=1 |
| 002 | 单周期写 | spram_wren=1, spram_en=1 |
| 003 | MCP=2多周期访问 | 每2周期才能接受新请求 |
| 004 | 读响应延迟验证 | mem_rsp_en 延迟 DATA_PIPE_LATENCY 周期 |
| 005 | sideband透传 | 请求的sideband与响应匹配 |
| 006 | 位掩码写入 | spram_bit_en 仅在写时使用req的bit_en |
| 007 | 连续读写混合 | 读写交替时rsp数据正确 |

---

# FCIP Fake 2-Port Memory Design Specification

## 1. 概述

`fcip_mem_fake_2p_mem` 使用单端口SRAM模拟双端口存储器行为，通过写缓冲（write buffer）实现读写端口分离，支持写缓冲转发（forwarding）和位级hazard检测。

**所属分类：** memory  
**文件路径：** `ip/memory/mem_fake_2p_sram/fcip_mem_fake_2p_mem.sv`

## 2. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| SRAM_ACCESS_LATENCY | integer unsigned | 1 | SRAM访问延迟 |
| SRAM_REQ_PIPE_STAGE | integer unsigned | 0 | 请求流水线级数 |
| SRAM_RSP_PIPE_STAGE | integer unsigned | 0 | 响应流水线级数 |
| SIDEBAND_WIDTH | integer unsigned | 1 | 旁路信息位宽 |
| DATA_WIDTH | integer unsigned | 128 | 数据位宽 |
| ADDR_WIDTH | integer unsigned | 10 | 地址位宽 |
| MCP_CYCLE | integer unsigned | 1 | 多周期端口周期数 |
| WRITE_BUFFER_SIZE | integer unsigned | 4 | 写缓冲深度（0=无缓冲） |
| RW_ARBITER_TYPE | integer unsigned | 0 | 读写仲裁（0=读优先，1=写优先） |
| READ_FORWARD_EN | integer unsigned | 1 | 读转发使能 |
| READ_BUFFER_SIZE | integer unsigned | 4 | 读缓冲深度 |
| WRITE_BIT_MASK_EN | integer unsigned | 1 | 写位掩码使能 |

## 3. 接口信号

### 3.1 写请求

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| write_req_vld | input | 1 | 写请求有效 |
| write_req_data | input | DATA_WIDTH | 写数据 |
| write_req_addr | input | ADDR_WIDTH | 写地址 |
| write_req_rdy | output | 1 | 写就绪 |
| write_req_bit_en | input | DATA_WIDTH | 写位掩码 |

### 3.2 读请求

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| read_req_vld | input | 1 | 读请求有效 |
| read_req_addr | input | ADDR_WIDTH | 读地址 |
| read_req_sideband | input | SIDEBAND_WIDTH | 旁路信息 |
| read_req_rdy | output | 1 | 读就绪 |

### 3.3 读响应

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| read_resp_vld | output | 1 | 读响应有效 |
| read_resp_data | output | DATA_WIDTH | 读数据 |
| read_resp_sideband | output | SIDEBAND_WIDTH | 旁路信息 |
| read_resp_rdy | input | 1 | 读响应就绪 |

### 3.4 SRAM端口和控制

| 信号名 | 方向 | 说明 |
|--------|------|------|
| spram_* | output/input | 物理SRAM端口 |
| stall | input | 暂停 |
| clear | input | 清除 |
| idle | output | 空闲状态 |

## 4. 架构

```
写请求 --> [Write Buffer] --> 
                               [RW Arbiter] --> [mem_ctrl_wrap] --> SRAM
读请求 ----------------------->       |
   |                                  |
   +--[地址比较/Hazard检测]--+         |
                              |        |
                              v        v
                        [Data Merge] --> [Read Buffer FIFO] --> 读响应
```

### 4.1 写缓冲
- WRITE_BUFFER_SIZE=0：直接透传
- WRITE_BUFFER_SIZE>0：循环缓冲，缓存写请求等待SRAM空闲

### 4.2 读写仲裁
- RW_ARBITER_TYPE=0：读优先，写仅在无读时提交
- RW_ARBITER_TYPE=1：写优先，读仅在无写时提交

### 4.3 写缓冲转发（Hazard处理）
- 读请求地址与写缓冲中条目地址比较
- WRITE_BIT_MASK_EN=0：整字转发
- WRITE_BIT_MASK_EN=1：位级合并（write buffer数据 | SRAM数据）

### 4.4 读缓冲
- `fcip_sync_fifo_reg` 缓存读响应
- READ_FORWARD_EN=1：空FIFO时直接转发到输出

### 4.5 依赖模块
- `fcip_mem_fake_write_buffer`：写缓冲及地址比较
- `fcip_mem_fake_find_new_bit`：位级hazard检测
- `fcip_mem_ctrl_wrap`：SRAM控制器
- `fcip_sync_fifo_reg`：读缓冲FIFO

## 5. 验证关键点与测试用例

| TC | 场景 | 预期 |
|----|------|------|
| 001 | 写后读相同地址 | 读到最新写入数据 |
| 002 | 读写同时请求（读优先） | 读先执行 |
| 003 | 读写同时请求（写优先） | 写先执行 |
| 004 | 写缓冲转发 | 读命中写缓冲时数据正确合并 |
| 005 | 位级转发 | 部分bit来自写缓冲，部分来自SRAM |
| 006 | 写缓冲满 | write_req_rdy=0 |
| 007 | 读缓冲满 | read_req_rdy=0 |
| 008 | WRITE_BUFFER_SIZE=0 | 写直接进入SRAM |
| 009 | 连续随机读写 | 数据一致性 |
| 010 | stall/clear功能 | 暂停和清除状态正确 |

---

# FCIP Fake Write Buffer Design Specification

## 1. 概述

`fcip_mem_fake_write_buffer` 是fake 2-port memory的写缓冲模块，使用循环缓冲区缓存待写入SRAM的数据，同时支持读地址比较以实现写缓冲转发。

**文件路径：** `ip/memory/mem_fake_2p_sram/fcip_mem_fake_write_buffer.sv`

## 2. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| ADDR_WIDTH | integer unsigned | 8 | 地址位宽 |
| DATA_WIDTH | integer unsigned | 128 | 数据位宽 |
| WRITE_BUFFER_SIZE | integer unsigned | 16 | 缓冲区深度 |
| MEM_LATENCY | integer unsigned | 1 | 存储器总延迟 |
| WRITE_BIT_MASK_EN | integer unsigned | 1 | 位掩码使能 |

## 3. 关键功能

### 3.1 循环缓冲区
- `wr_ptr`/`rd_ptr`：含MSB溢出位的读写指针
- `full = (rd==wr) && (MSB不同)`，`empty = (rd==wr)`

### 3.2 写入
- 数据结构：`{write_data, write_addr, write_bit_en}` 存入 `write_array_data[wr_ptr]`

### 3.3 读出提交
- FIFO顺序读出最旧条目提交到SRAM
- `rel_write_entry = ~empty && write_buffer_rdy`

### 3.4 地址比较（Hazard检测）
- `read_cmp_vld`/`read_cmp_addr` 延迟1拍后与缓冲区所有条目地址比较
- WRITE_BIT_MASK_EN=1：使用 `fcip_mem_fake_find_new_bit` 做位级转发
- WRITE_BIT_MASK_EN=0：使用 `fcip_lead_one_msb` 找最新命中条目（前向/后向分区）

---

# FCIP Fake Find New Bit Design Specification

## 1. 概述

`fcip_mem_fake_find_new_bit` 是位级hazard检测模块，在写缓冲中逐bit查找最新写入的数据，支持细粒度的写缓冲转发。

**文件路径：** `ip/memory/mem_fake_2p_sram/fcip_mem_fake_find_new_bit.sv`

## 2. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| ADDR_WIDTH | integer unsigned | 8 | 地址位宽 |
| DATA_WIDTH | integer unsigned | 128 | 数据位宽 |
| WRITE_BUFFER_SIZE | integer unsigned | 16 | 写缓冲深度 |
| PTR_WIDTH | integer unsigned | 6 | 指针位宽 |

## 3. 关键功能

### 3.1 逐位Hazard检测
- 对每个数据bit：检查写缓冲中所有条目，找到最新的写入该bit的条目
- `cmp_hit_bit[i][j]`：bit i在条目j有命中（地址匹配 && 条目有效 && bit_en[i]有效）

### 3.2 前向/后向分区
- 以 `wr_ptr` 为分界：`mask_en[j] = (j <= wr_ptr-1)`
- 前向区（更新）优先于后向区（更旧）

### 3.3 最新bit选择
- 每个bit使用 `fcip_lead_one_msb` 选择前向区最新，无前向命中则选后向区最新
- 输出 `cmp_hit_data[i]`：第i个bit的最新数据值

## 4. 验证关键点

| TC | 场景 | 预期 |
|----|------|------|
| 001 | 单条目命中 | 直接转发 |
| 002 | 多条目同地址，不同bit位 | 逐bit取最新 |
| 003 | 前向后向分区边界 | 跨wr_ptr的条目正确选择 |
| 004 | 无命中 | cmp_hit=0 |
