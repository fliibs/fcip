# 基于SPRAM的同步FIFO设计规范

## 文档信息

| 项目 | 描述 |
|------|-------------|
| 文档标题 | 基于SPRAM的同步FIFO设计规范 |
| 模块名称 | fcip_sync_fifo_spram |
| 版本 | 1.0 |
| 日期 | 2026年2月3日 |
| 作者 | jiaoyadi |

## 1. 概述

### 1.1 简介

`fcip_sync_fifo_spram` 是一个基于单端口SRAM实现的同步FIFO设计。该设计采用创新的ROB（Reorder Buffer，重排序缓冲区）架构，使用多组SRAM并行工作，实现了在单时钟域内的高带宽FIFO功能。设计支持可选的零延迟数据转发、阈值指示和灵活的流水线配置。

### 1.2 主要特性

- **基于SRAM的存储**：使用单端口SRAM作为主存储介质
- **多组SRAM并行**：支持多个SRAM组并行工作，提高带宽
- **ROB架构**：乱序写入、顺序输出的重排序缓冲区
- **零延迟转发**：可选的数据直通路径，最小延迟为0
- **深度FIFO**：支持大容量存储（推荐≥64深度）
- **阈值指示**：Almost Full和Almost Empty标志
- **可配置流水线**：SRAM请求和响应流水线可配置
- **MCP支持**：支持多周期路径时序优化
- **LUT索引**：使用查找表记录每笔数据的存储位置
- **lowpower管理**：支持stall和clear控制

### 1.3 设计层次结构

```
fcip_sync_fifo_spram (顶层)
├── 写仲裁器
│   └── ROB/SRAM路径选择
│
├── fcip_sfifo_spram_ctrl (SRAM读写控制器)
│   ├── 写分配仲裁器（轮转仲裁）
│   ├── fcip_sfifo_spram_ptr_ctrl x N (指针控制器，每组一个)
│   │   ├── 读写指针管理
│   │   ├── 满/空检测
│   │   └── SRAM接口控制
│   └── fcip_sync_fifo_reg (LUT查找表)
│       └── 记录数据存储位置
│
├── fcip_mem_ctrl_wrap x N (SRAM控制包装器，每组一个)
│   ├── MCP控制
│   ├── 请求流水线
│   ├── 响应流水线
│   └── Sideband传递
│
├── fcip_sfifo_spram_rob (重排序缓冲区)
│   ├── 预分配逻辑
│   ├── 乱序写入
│   ├── 顺序读出
│   └── 数据转发逻辑
│
└── 数据多路复用器
    └── SRAM组数据选择
```

### 1.4 核心架构概念

#### 1.4.1 ROB工作原理

ROB维护一个顺进顺出模型，但内部实现乱序写入：

**三态模型：**
每个ROB条目有三个状态：
1. **空闲（Idle）**：条目可被分配
2. **已分配等待数据（Allocated）**：已预分配但数据未到
3. **数据有效（Valid）**：数据已到达，可以读出

**指针机制：**
- **预分配指针（Prealloc Pointer）**：顺序分配条目ID给新请求
- **写入指针（Write Pointer）**：数据到达时写入对应条目
- **读出指针（Read Pointer）**：顺序读出有效数据

**工作流程：**
```
周期0: 预分配ID=0给请求A
周期1: 预分配ID=1给请求B
周期2: 请求B的数据到达，写入ROB[1]
周期3: 请求A的数据到达，写入ROB[0]
周期4: ROB[0]有效，输出请求A的数据
周期5: ROB[1]有效，输出请求B的数据
```

#### 1.4.2 解码路由策略

设计采用智能路由决策：

```
if (SRAM为空) {
    if (启用转发且下游就绪) {
        数据直接转发到输出（零延迟）
    } else {
        数据写入SRAM
    }
} else {
    数据写入SRAM
}
```

这确保在FIFO空闲时可以实现零延迟直通，在有数据积压时则使用SRAM缓冲。

### 1.5 典型应用场景

- **数据缓冲**：在生产者和消费者速率不匹配时缓冲数据
- **流水线解耦**：解耦不同频率或延迟的流水线阶段
- **突发吸收**：吸收短时间的数据突发
- **深度存储**：需要大容量FIFO但不想使用大量寄存器

## 2. 模块功能说明

### 2.1 顶层模块：fcip_sync_fifo_spram

顶层模块整合所有子模块，实现完整的FIFO功能。

**主要功能：**
- 接收写请求，决定写入ROB还是SRAM
- 协调多个SRAM组的并行访问
- 管理ROB预分配和数据回填
- 仲裁和多路复用SRAM读取数据
- 输出顺序正确的读响应

### 2.2 写仲裁器

决定输入数据的路由路径。

**决策逻辑：**
```verilog
sel_rob_en  = rob_write_rdy && spram_ctrl_empty
sel_ram_en  = ram_write_rdy && ~sel_rob_en
write_req_rdy = sel_rob_en || sel_ram_en
```

**路由规则：**
- ROB优先：当SRAM为空时，数据通过ROB快速通道
- SRAM路径：当SRAM非空或ROB不可用时，数据写入SRAM
- 互斥选择：同一周期只选一条路径

### 2.3 SRAM读写控制器：fcip_sfifo_spram_ctrl

管理多个SRAM组的读写操作。

**主要功能：**

**2.3.1 写分配（Write Allocation）**
- 使用轮转仲裁器在SRAM组间分配写请求
- 确保负载均衡
- 避免单个SRAM组过载

```verilog
fcip_grant_gen_rr u_write_alloc(
    .v_vld(sram_write_rdy),
    .v_grant(sram_write_alloc)
);
```

**2.3.2 指针控制器（Per-Group）**
- 每个SRAM组独立的读写指针
- 独立的满/空状态
- 生成SRAM访问请求

**2.3.3 LUT查找表**
- 记录每笔写入数据所在的SRAM组
- 使用寄存器FIFO实现
- 深度 = FIFO_DEPTH_PER_GROUP × SRAM_GROUP_NUM
- 存储格式：one-hot编码的组选择信号

**工作流程：**
```
写入时: LUT入队 = {group_select_onehot}
读取时: LUT出队，得到group_select
       根据group_select向对应SRAM组发起读请求
```

### 2.4 指针控制器：fcip_sfifo_spram_ptr_ctrl

每个SRAM组的独立控制器。

**主要功能：**
- **读写指针管理**：维护独立的rptr和wptr
- **容量跟踪**：使用ptr_cnt跟踪使用条目数
- **满/空检测**：
  ```verilog
  ram_ctrl_empty = (ptr_cnt == 0)
  ram_ctrl_full  = (ptr_cnt == FIFO_DEPTH_PER_GROUP)
  ```
- **SRAM请求生成**：
  - 写请求：`mem_req_opcode = 1, mem_req_addr = wptr`
  - 读请求：`mem_req_opcode = 0, mem_req_addr = rptr`
- **Sideband传递**：将ROB的预分配ID传递到响应端

**关键逻辑：**
```verilog
// 写操作
winc = write_vld && write_rdy
wptr <= wptr + 1 when winc

// 读操作
rinc = read_vld && read_rdy
rptr <= rptr + 1 when rinc

// 计数器
ptr_cnt更新：
  winc && rinc: 不变
  winc: +1
  rinc: -1
```

### 2.5 重排序缓冲区：fcip_sfifo_spram_rob

ROB实现乱序写入、顺序读出。

**主要功能：**

**2.5.1 预分配管理**
```verilog
rob_prealloc_id = rob_wptr  // 顺序分配ID
sram_pre_winc = sram_read_en  // SRAM读时预分配
```

**2.5.2 写入控制**
- **ROB直接写**：`rob_req_vld && rob_req_rdy`
  - 数据直接写入rob_wptr位置
  - rob_wptr递增
- **SRAM回填写**：`ram_req_vld && ram_req_rdy`
  - 数据写入ram_req_id指定的位置
  - 不递增rob_wptr（ID已预分配）

**2.5.3 读出控制**
- 检查rob_rptr位置的条目是否有效
- 如果有效且下游就绪，输出数据
- rob_rptr递增

**2.5.4 数据转发（FORWARD_EN = 1）**

转发有两种情况：

**直接转发（Direct Forward）：**
```verilog
direct_forward_en = rob_empty && read_rdy
```
- ROB为空时，ROB写入的数据直接转发到输出
- 实现零延迟
- 数据不写入ROB

**SRAM转发（SRAM Forward）：**
```verilog
sram_forward_en = ram_req_rdy && read_rdy && (ram_req_id == rob_rptr)
```
- SRAM读回的数据正好是下一个要输出的
- 直接转发到输出
- 不写入ROB，但rob_rptr递增

**条目状态管理：**
```verilog
array_vld[i] 状态转换：
  0 → 1: 写入时（rob_winc或sram_winc到该位置）
  1 → 0: 读出时（rinc且rptr==i）或转发时
```

**2.5.5 阈值管理**
```verilog
rob_almost_full = (ptr_cnt >= ALMOST_FULL_THRESHOLD)
rob_almost_empty = (ptr_cnt <= ALMOST_EMPTY_THRESHOLD)
```

### 2.6 SRAM控制包装器：fcip_mem_ctrl_wrap

封装单个SRAM组的访问逻辑（与mem_fake_2p_mem中的模块相同）。

**主要功能：**
- MCP周期控制
- 请求流水线
- 响应流水线
- Sideband延迟匹配
- CDC标记插入

### 2.7 数据多路复用器

选择正确SRAM组的读数据。

**工作原理：**
```verilog
1. sram_read_sel指示读取的SRAM组（one-hot）
2. 延迟SRAM_DELAY_TOTAL周期，与数据对齐
3. 使用one-hot选择器从N个SRAM输出中选择
4. 输出到ROB进行重排序
```

**关键信号：**
- `sram_read_sel[N-1:0]`：读请求时的组选择
- `sram_read_sel_delay[N-1:0]`：延迟后的组选择
- `mem_rsp_data[N-1:0][DATA_WIDTH-1:0]`：N组SRAM数据
- `sram_req_pld`：选中的数据

## 3. 接口描述

### 3.1 顶层模块参数

| 参数 | 类型 | 默认值 | 约束 | 描述 |
|------|------|--------|------|------|
| FIFO_DEPTH_PER_GROUP | integer unsigned | 64 | ≥4，建议≥32 | 每个SRAM组的深度 |
| SRAM_GROUP_NUM | integer unsigned | 2 | ≥1，MCP=1时建议≥2 | SRAM组数量 |
| DATA_WIDTH | integer unsigned | 16 | ≥1 | 数据位宽 |
| ALMOST_FULL_THRESHOLD | integer unsigned | 2 | ≥0 | Almost Full阈值 |
| ALMOST_EMPTY_THRESHOLD | integer unsigned | 2 | ≥0 | Almost Empty阈值 |
| FORWARD_EN | integer unsigned | 1 | 0或1 | 转发使能：1=启用，0=禁用 |
| ROB_DEPTH | integer unsigned | 16 | ≥ MEM延迟 | ROB深度 |
| SRAM_ACCESS_LATENCY | integer unsigned | 1 | ≥1 | SRAM访问延迟 |
| SRAM_REQ_PIPE_STAGE | integer unsigned | 0 | ≥0 | 请求流水线级数 |
| SRAM_RSP_PIPE_STAGE | integer unsigned | 0 | ≥0 | 响应流水线级数 |
| MCP_CYCLE | integer unsigned | 1 | ≥1 | 多周期路径周期数 |

### 3.2 端口定义

#### 3.2.1 时钟和复位

| 端口名称 | 方向 | 位宽 | 描述 |
|----------|------|------|------|
| clk | input | 1 | 系统时钟 |
| rst_n | input | 1 | 低电平有效异步复位 |

#### 3.2.2 控制端口

| 端口名称 | 方向 | 位宽 | 描述 |
|----------|------|------|------|
| stall | input | 1 | 暂停控制：1=阻塞新写入 |
| clear | input | 1 | 清除控制：1=清空FIFO |
| idle | output | 1 | 空闲状态：1=ROB和SRAM都为空 |

#### 3.2.3 写端口

| 端口名称 | 方向 | 位宽 | 协议 | 描述 |
|----------|------|------|------|------|
| write_req_vld | input | 1 | Valid-Ready | 写请求有效 |
| write_req_pld | input | DATA_WIDTH | Valid-Ready | 写数据 |
| write_req_rdy | output | 1 | Valid-Ready | 写请求就绪 |

#### 3.2.4 读端口

| 端口名称 | 方向 | 位宽 | 协议 | 描述 |
|----------|------|------|------|------|
| read_resp_vld | output | 1 | Valid-Ready | 读响应有效 |
| read_resp_pld | output | DATA_WIDTH | Valid-Ready | 读数据 |
| read_resp_rdy | input | 1 | Valid-Ready | 读响应就绪 |

#### 3.2.5 状态端口

| 端口名称 | 方向 | 位宽 | 描述 |
|----------|------|------|------|
| almost_full | output | 1 | 接近满：距满还有ALMOST_FULL_THRESHOLD个空位 |
| almost_empty | output | 1 | 接近空：距空还有ALMOST_EMPTY_THRESHOLD个条目 |
| empty | output | 1 | 空状态：FIFO为空 |
| full | output | 1 | 满状态：FIFO为满 |

#### 3.2.6 SRAM接口（每组）

| 端口名称 | 方向 | 位宽 | 描述 |
|----------|------|------|------|
| spram_addr[i] | output | $clog2(FIFO_DEPTH_PER_GROUP) | 第i组SRAM地址 |
| spram_din[i] | output | DATA_WIDTH | 第i组SRAM写数据 |
| spram_dout[i] | input | DATA_WIDTH | 第i组SRAM读数据 |
| spram_en[i] | output | 1 | 第i组SRAM使能 |
| spram_wren[i] | output | 1 | 第i组SRAM写使能 |
| spram_bit_en[i] | output | DATA_WIDTH | 第i组SRAM位使能 |

其中 i ∈ [0, SRAM_GROUP_NUM-1]

## 4. 时序和时钟结构

### 4.1 时钟域

该设计为单时钟同步设计，所有逻辑工作在同一时钟下。

### 4.2 延迟分析

**SRAM总延迟：**
```
SRAM_DELAY_TOTAL = SRAM_ACCESS_LATENCY + SRAM_REQ_PIPE_STAGE + SRAM_RSP_PIPE_STAGE
```

**写入到读出延迟：**

**情况1：直接转发（FORWARD_EN=1，FIFO为空）**
```
延迟 = 0周期（组合路径）
```

**情况2：通过ROB但SRAM为空（FORWARD_EN=1）**
```
延迟 = 0周期（直接转发到ROB输出）
```

**情况3：通过SRAM（正常路径）**
```
延迟 = SRAM_DELAY_TOTAL + 1（ROB输出）
```

**情况4：无转发（FORWARD_EN=0）**
```
最小延迟 = SRAM_DELAY_TOTAL + 1
```

### 4.3 带宽分析

**理论最大带宽：**
```
写带宽 = 1次写入/周期
读带宽 = 1次读出/周期（前提：数据可用）
```

**SRAM带宽：**
```
单组带宽 = 1次操作/(MCP_CYCLE周期)
总SRAM带宽 = SRAM_GROUP_NUM × 单组带宽
```

**持续吞吐量：**
- 当 SRAM_GROUP_NUM × (1/MCP_CYCLE) ≥ 1：可以支持满带宽读写
- 当 SRAM_GROUP_NUM × (1/MCP_CYCLE) < 1：持续吞吐量受限

**示例：**
```
MCP_CYCLE=1, SRAM_GROUP_NUM=2:
  每组带宽=1次/周期，总带宽=2次/周期
  可以同时1写1读，满带宽

MCP_CYCLE=2, SRAM_GROUP_NUM=1:
  总带宽=0.5次/周期
  不能满带宽，需要时分复用
```

### 4.4 ROB深度设计

**最小ROB深度：**
```
ROB_DEPTH_min = SRAM_DELAY_TOTAL + 2
```

**推荐ROB深度：**
```
ROB_DEPTH = 2 × SRAM_DELAY_TOTAL
或
ROB_DEPTH = 16（经验值）
```

**原因：**
- 需要缓冲SRAM流水线中的所有请求
- 需要额外空间处理SRAM响应等待
- 过小会导致频繁背压

### 4.5 FIFO深度设计

**每组深度建议：**
```
FIFO_DEPTH_PER_GROUP:
  小型：64-128
  中型：256-512
  大型：1024+
```

**总容量：**
```
总FIFO深度 = FIFO_DEPTH_PER_GROUP × SRAM_GROUP_NUM
有效容量 = 总FIFO深度 - ALMOST_FULL_THRESHOLD
```

### 4.6 时序约束

```tcl
# 时钟定义
create_clock -name clk -period <PERIOD> [get_ports clk]

# SRAM接口约束
for {set i 0} {$i < $SRAM_GROUP_NUM} {incr i} {
    set_output_delay -clock clk <SETUP> [get_ports spram_addr[$i]*]
    set_output_delay -clock clk <SETUP> [get_ports spram_din[$i]*]
    set_input_delay -clock clk <CQ> [get_ports spram_dout[$i]*]
}

# MCP约束（如果MCP_CYCLE > 1）
if {$MCP_CYCLE > 1} {
    set_multicycle_path $MCP_CYCLE -setup \
        -from [get_pins */u_fifo_spram_mem_ctrl*/*] \
        -to [get_ports spram_*]
    set_multicycle_path [expr $MCP_CYCLE - 1] -hold \
        -from [get_pins */u_fifo_spram_mem_ctrl*/*] \
        -to [get_ports spram_*]
}

# 转发路径约束（如果FORWARD_EN=1）
if {$FORWARD_EN == 1} {
    set_max_delay <PERIOD> \
        -from [get_ports write_req_pld] \
        -to [get_ports read_resp_pld]
}

# Almost Full/Empty组合路径
set_max_delay [expr <PERIOD> * 0.8] \
    -from [all_registers] \
    -to [get_ports almost_*]
```

## 5. 功能行为

### 5.1 正常操作流程

#### 5.1.1 FIFO为空时的写入

**场景：FORWARD_EN=1**
```
周期0: FIFO空，write_req_vld=1
       → 选择ROB路径
       → 数据直接转发到read_resp（如果read_resp_rdy=1）
       → 延迟=0

周期0: FIFO空，write_req_vld=1，read_resp_rdy=0
       → 选择SRAM路径
       → 数据写入SRAM组0
       → LUT记录组0
       → 预分配ROB[0]
```

**场景：FORWARD_EN=0**
```
周期0: FIFO空，write_req_vld=1
       → 选择SRAM路径
       → 后续流程同上
```

#### 5.1.2 FIFO非空时的写入

```
周期N: FIFO非空，write_req_vld=1
       → 必须选择SRAM路径
       → 轮转仲裁选择SRAM组i
       → 写入SRAM[i]
       → LUT记录组i
       → 预分配ROB[k]
```

#### 5.1.3 读出流程

```
周期M: FIFO非空
       → SRAM控制器检测到有数据
       → 从LUT读出组选择
       → 向对应SRAM组发起读请求
       → 经过SRAM_DELAY_TOTAL周期
       → 数据返回，附带ROB_ID
       → 写入ROB[ROB_ID]
       → 当ROB[rob_rptr]有效时输出
```

#### 5.1.4 转发场景

**直接转发：**
```
前提: ROB空 && SRAM空 && read_resp_rdy=1 && FORWARD_EN=1

周期0: write_req_vld=1, write_req_pld=DATA
周期0: read_resp_vld=1, read_resp_pld=DATA（同周期）
```

**SRAM转发：**
```
前提: ROB[rob_rptr]等待数据 && SRAM读回ID==rob_rptr && read_resp_rdy=1

周期N: SRAM返回数据，ID=rob_rptr
周期N: 数据直接转发到read_resp
       ROB[rob_rptr]不存储数据
       rob_rptr递增
```

### 5.2 满和空状态

**空状态：**
```
empty = spram_ctrl_empty && rob_empty
```
- 所有SRAM组都为空
- ROB中无有效数据

**满状态：**
```
full = spram_ctrl_full || rob_full
```
- 任一SRAM组满
- 或ROB满

**Almost Full：**
```
almost_full = (total_entries >= TOTAL_DEPTH - ALMOST_FULL_THRESHOLD)
```

**Almost Empty：**
```
almost_empty = (total_entries <= ALMOST_EMPTY_THRESHOLD)
```

### 5.3 流控行为

**写端背压：**
```
write_req_rdy = 0 当：
  - SRAM满
  - ROB满
  - stall=1
```

**读端控制：**
```
read_resp_vld = 0 当：
  - FIFO空
  - ROB输出位置无有效数据
```

**下游背压：**
```
read_resp_rdy = 0 时：
  - ROB输出暂停
  - 可能导致ROB填满
  - 进而导致SRAM读取暂停
  - 最终导致写入背压
```

### 5.4 复位和清除

**复位（rst_n=0）：**
- 所有指针复位到0
- 所有有效位清零
- FIFO变为空状态

**清除（clear=1）：**
- 功能与复位相同
- 但是同步清除
- 用于运行时清空FIFO

**Stall（stall=1）：**
- 阻止新的写入
- 允许现有数据排空
- 读取不受影响

### 5.5 特殊场景

#### 5.5.1 单SRAM组配置

```
SRAM_GROUP_NUM = 1, MCP_CYCLE = 1:
  - 带宽受限：不能同时读写
  - SRAM需要在读写间时分复用
  - ROB缓冲更加重要
```

#### 5.5.2 高MCP配置

```
MCP_CYCLE = 2:
  - SRAM访问间隔2周期
  - 需要增加SRAM组数补偿带宽
  - 或接受降低的吞吐量
```

#### 5.5.3 转发禁用的影响

```
FORWARD_EN = 0:
  - 最小延迟增加
  - 时序更宽松（无组合路径）
  - 适合高频率设计
```

## 6. 验证策略

### 6.1 验证目标

#### 6.1.1 主要目标

- **FIFO语义正确**：先进先出顺序保持
- **数据完整性**：所有写入数据正确读出
- **ROB功能**：乱序写入、顺序读出正确
- **转发正确性**：转发数据与正常路径数据一致
- **满/空检测**：边界条件正确处理
- **多组SRAM**：负载均衡，无冲突
- **协议合规**：Valid-Ready握手正确

#### 6.1.2 覆盖率目标

- 代码覆盖率：>95%
- 功能覆盖率：100%
- 所有参数组合测试
- 所有转发路径测试

### 6.2 测试平台架构

```
TB Top
├── 时钟和复位生成器
├── 写驱动器
│   ├── 随机/定向数据生成
│   ├── 可变写入速率
│   └── 数据序号标记
├── 读监控器
│   ├── 数据捕获
│   ├── 顺序校验
│   └── 数据完整性检查
├── SRAM模型（N组）
│   ├── 行为级模型
│   ├── 可配置延迟
│   └── 读写操作模拟
├── 参考模型
│   ├── 理想FIFO行为
│   ├── 写入记录
│   └── 顺序校验
├── 记分板
│   ├── 数据比较
│   ├── 顺序验证
│   └── 统计信息
└── 覆盖率收集器
```

### 6.3 测试计划

#### 6.3.1 基本功能测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|--------|----------|------|----------|
| BF001 | 简单读写 | 写N个数据，读N个数据 | 数据和顺序都正确 |
| BF002 | 连续写入 | 持续写入到满 | 正确检测满状态 |
| BF003 | 连续读取 | 持续读取到空 | 正确检测空状态 |
| BF004 | 交替读写 | 交替进行读写操作 | 数据正确，无死锁 |
| BF005 | 突发写入 | 短时间大量写入 | 缓冲正确，无丢失 |
| BF006 | 突发读取 | 短时间大量读取 | 输出正确，无错误 |
| BF007 | FIFO回卷 | 多次填满排空 | 指针正确回卷 |
| BF008 | 随机读写 | 随机速率读写 | 数据一致性保持 |

#### 6.3.2 ROB功能测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|--------|----------|------|----------|
| ROB001 | 顺序输出 | 乱序写入ROB | 输出保持写入顺序 |
| ROB002 | ROB满 | 填满ROB | 正确背压 |
| ROB003 | ROB预分配 | 验证ID预分配 | ID顺序连续 |
| ROB004 | 延迟回填 | 后发数据先到达 | 仍按序输出 |
| ROB005 | ROB阈值 | 测试almost_full/empty | 阈值正确触发 |

#### 6.3.3 转发功能测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|--------|----------|------|----------|
| FWD001 | 直接转发 | FIFO空时写入 | 零延迟输出 |
| FWD002 | SRAM转发 | SRAM读回正好匹配输出位置 | 直接转发无等待 |
| FWD003 | 转发与正常路径 | 对比转发和非转发数据 | 数据一致 |
| FWD004 | 转发禁用 | FORWARD_EN=0 | 无直通路径 |
| FWD005 | 转发背压 | 转发时下游不就绪 | 转发取消，数据缓冲 |

#### 6.3.4 多SRAM组测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|--------|----------|------|----------|
| MG001 | 负载均衡 | 观察写分配 | 各组负载接近 |
| MG002 | 并发读写 | 多组同时读写 | 无冲突，数据正确 |
| MG003 | 单组 | SRAM_GROUP_NUM=1 | 正常工作 |
| MG004 | 多组 | SRAM_GROUP_NUM=4+ | 正常工作，带宽提升 |
| MG005 | LUT功能 | 验证LUT记录和查找 | 组选择正确 |

#### 6.3.5 边界和压力测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|--------|----------|------|----------|
| STR001 | 满带宽写 | 持续满速写入 | 达到理论带宽 |
| STR002 | 满带宽读 | 持续满速读取 | 达到理论带宽 |
| STR003 | 同时满带宽 | 同时满速读写 | 根据配置达到带宽 |
| STR004 | 长时间运行 | 运行1M+周期 | 无错误，无泄漏 |
| STR005 | 最小深度 | FIFO_DEPTH=4 | 正常工作 |
| STR006 | 最小ROB | ROB_DEPTH=SRAM_DELAY+2 | 正常工作 |
| STR007 | 大深度 | FIFO_DEPTH=2048+ | 正常工作 |

#### 6.3.6 参数扫描测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|--------|----------|------|----------|
| PAR001 | SRAM延迟扫描 | 不同SRAM_ACCESS_LATENCY | 所有配置正常 |
| PAR002 | 流水线扫描 | 不同REQ/RSP_PIPE_STAGE | 所有配置正常 |
| PAR003 | MCP扫描 | 不同MCP_CYCLE | 所有配置正常 |
| PAR004 | 组数扫描 | 不同SRAM_GROUP_NUM | 1-8组都正常 |
| PAR005 | ROB深度扫描 | 不同ROB_DEPTH | 所有深度正常 |
| PAR006 | 数据位宽扫描 | 不同DATA_WIDTH | 8-512位都正常 |

### 6.4 覆盖率计划

```systemverilog
covergroup cg_fifo_status;
    cp_empty: coverpoint empty;
    cp_full: coverpoint full;
    cp_almost_empty: coverpoint almost_empty;
    cp_almost_full: coverpoint almost_full;
endgroup

covergroup cg_rob_operation;
    cp_direct_fwd: coverpoint direct_forward_en;
    cp_sram_fwd: coverpoint sram_forward_en;
    cp_rob_write: coverpoint rob_winc;
    cp_sram_write: coverpoint sram_winc;
    cp_rob_read: coverpoint rinc;
    cross cp_direct_fwd, cp_rob_write;
    cross cp_sram_fwd, cp_sram_write;
endgroup

covergroup cg_sram_groups;
    cp_group_sel: coverpoint sram_write_alloc {
        bins groups[] = {[0:2**SRAM_GROUP_NUM-1]};
    }
    cp_concurrent: coverpoint $countones(mem_req_vld);
endgroup

covergroup cg_forwarding;
    cp_forward_type: coverpoint {direct_forward_en, sram_forward_en} {
        bins none = {2'b00};
        bins direct = {2'b10};
        bins sram = {2'b01};
        illegal_bins both = {2'b11};
    }
endgroup
```

### 6.5 断言计划

```systemverilog
// FIFO顺序保持
property p_fifo_order;
    logic [DATA_WIDTH-1:0] data_queue[$];
    @(posedge clk) disable iff (!rst_n)
    (write_req_vld && write_req_rdy, data_queue.push_back(write_req_pld))
    ##[0:$] (read_resp_vld && read_resp_rdy) 
    |-> (read_resp_pld == data_queue.pop_front());
endproperty

// ROB顺序输出
property p_rob_inorder;
    @(posedge clk) disable iff (!rst_n)
    rinc |=> rob_rptr == $past(rob_rptr) + 1;
endproperty

// 满时不接受新写入
property p_full_no_write;
    @(posedge clk) disable iff (!rst_n)
    full |-> !write_req_rdy;
endproperty

// 空时不输出
property p_empty_no_read;
    @(posedge clk) disable iff (!rst_n)
    empty |-> !read_resp_vld;
endproperty

// 转发一致性
property p_forward_consistency;
    @(posedge clk) disable iff (!rst_n)
    (FORWARD_EN && direct_forward_en && rob_req_vld)
    |-> (read_resp_vld && read_resp_pld == rob_req_pld);
endproperty

// ROB不溢出
property p_rob_no_overflow;
    @(posedge clk) disable iff (!rst_n)
    ptr_cnt <= ROB_DEPTH;
endproperty

// SRAM组选择有效
property p_sram_sel_onehot;
    @(posedge clk) disable iff (!rst_n)
    sram_write_alloc != 0 |-> $onehot(sram_write_alloc);
endproperty
```

### 6.6 回归策略

- **快速回归**：基本功能测试（<10分钟）
- **每日回归**：所有功能测试（2-4小时）
- **每周回归**：包括压力和参数扫描（24小时）
- **发布回归**：完整测试+多随机种子（多日）

## 7. 设计约束和限制

### 7.1 参数约束

| 参数 | 约束 | 原因 |
|------|------|------|
| FIFO_DEPTH_PER_GROUP | ≥4，建议≥32 | 太小失去SRAM意义 |
| SRAM_GROUP_NUM | ≥1，MCP=1时建议≥2 | 带宽考虑 |
| ROB_DEPTH | ≥ SRAM_DELAY_TOTAL+2 | 缓冲流水线 |
| ALMOST_FULL_THRESHOLD | < TOTAL_DEPTH | 逻辑约束 |

### 7.2 使用建议

**场景选择：**
- **小容量（<512）**：使用寄存器FIFO
- **中等容量（512-4K）**：本设计最合适
- **大容量（>4K）**：考虑外部存储器

**参数配置建议：**
```
高性能配置：
  SRAM_GROUP_NUM = 2-4
  MCP_CYCLE = 1
  FORWARD_EN = 1
  ROB_DEPTH = 16-32

高频率配置：
  SRAM_REQ_PIPE_STAGE = 1
  SRAM_RSP_PIPE_STAGE = 1
  FORWARD_EN = 0
  MCP_CYCLE = 2

低延迟配置：
  FORWARD_EN = 1
  SRAM_REQ_PIPE_STAGE = 0
  SRAM_RSP_PIPE_STAGE = 0
  ROB_DEPTH = 16+
```

### 7.3 已知限制

- 单SRAM组+MCP>1时带宽受限
- 转发路径可能成为时序关键路径
- ROB过小会导致频繁背压
- LUT深度线性增长，大容量时面积显著

## 8. 附录

### 8.1 术语表

| 术语 | 定义 |
|------|------|
| ROB | Reorder Buffer，重排序缓冲区 |
| LUT | Look-Up Table，查找表 |
| SPRAM | Single-Port RAM，单端口RAM |
| MCP | Multi-Cycle Path，多周期路径 |

### 8.2 参考文档

- FCIP设计规范
- SRAM宏单元规格
- SystemVerilog IEEE 1800

### 8.3 修订历史

| 版本 | 日期 | 作者 | 描述 |
|------|------|------|------|
| 1.0 | 2026-02-03 | jiaoyadi | 初始版本 |

---

**文档结束**