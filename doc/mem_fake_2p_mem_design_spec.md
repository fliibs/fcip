# 伪双端口存储器设计规范

## 文档信息

| 项目 | 描述 |
|------|-------------|
| 文档标题 | 伪双端口存储器设计规范 |
| 模块名称 | fcip_mem_fake_2p_mem |
| 版本 | 1.0 |
| 日期 | 2026年2月3日 |
| 作者 | jiaoyadi |

## 1. 概述

### 1.1 简介

`fcip_mem_fake_2p_mem` 是一个使用单端口SRAM模拟双端口存储器行为的设计。该模块对外提供一读一写两个独立端口，均采用valid-ready握手协议。由于底层使用单端口SRAM，在非MCP（Multi-Cycle Path）情况下，最大读写带宽仅为每周期1次读或写操作。为了缓解峰值带宽冲突问题，设计内置了写缓冲区（Write Buffer）用于缓冲写数据，同时支持读写冲突检测和数据转发（Forwarding）功能。

### 1.2 主要特性

- **伪双端口接口**：对外提供独立的读端口和写端口
- **单端口SRAM后端**：使用单端口SRAM作为存储介质
- **写缓冲区**：可配置大小的写缓冲区，缓解读写带宽冲突
- **读写仲裁**：支持读优先或写优先两种仲裁策略
- **位掩码支持**：可选的位级写使能控制
- **读缓冲区**：支持可配置的读响应缓冲
- **数据转发优化**：可选的零延迟读取转发路径
- **可配置流水线**：支持请求和响应流水线级数配置
- **MCP支持**：支持多周期路径时序优化
- **lowpower**：支持stall和clear控制

### 1.3 设计层次结构

```
fcip_mem_fake_2p_mem (顶层模块)
├── fcip_mem_fake_write_buffer (写缓冲区)
│   ├── 写请求队列管理
│   ├── RAW冲突检测逻辑
│   ├── fcip_mem_fake_find_new_bit (位级冲突检测)
│   └── fcip_lead_one_msb (优先级编码器)
│
├── 读写仲裁器
│   ├── 读优先仲裁模式
│   └── 写优先仲裁模式
│
├── fcip_mem_ctrl_wrap (SRAM控制器包装)
│   ├── MCP控制逻辑
│   ├── SRAM接口控制
│   ├── fcip_marker (CDC标记)
│   └── fcip_data_pipe (流水线延迟)
│
└── fcip_sync_fifo_reg (读缓冲FIFO)
    └── 可选的数据转发逻辑
```

## 2. 模块功能说明

### 2.1 顶层模块：fcip_mem_fake_2p_mem

顶层模块实现伪双端口存储器的完整功能，协调写缓冲、读写仲裁、SRAM控制和读缓冲等子模块。

**主要功能：**
- 接收独立的读写请求
- 管理写缓冲区以提高写带宽利用率
- 仲裁读写请求到单端口SRAM
- 处理RAW冲突，提供正确的读数据
- 缓冲读响应数据
- 支持可选的数据转发以降低延迟

### 2.2 写缓冲区模块：fcip_mem_fake_write_buffer

写缓冲区模块接收写请求并暂存，允许读请求优先访问SRAM，从而提高整体带宽利用率。

**主要功能：**
- **写请求队列**：使用环形缓冲区结构存储待写入数据
- **容量管理**：跟踪写指针和读指针，生成满/空状态
- **顺序写入**：按FIFO顺序将缓冲的写请求发送到SRAM
- **RAW冲突检测**：检测读地址是否命中写缓冲区中的数据
- **数据转发**：当检测到RAW冲突时，直接转发缓冲区数据
- **位级冲突处理**：支持位掩码时的细粒度冲突检测
- **延迟匹配**：匹配SRAM访问延迟，确保转发数据时序正确

**冲突检测机制：**
1. **地址比较**：读地址与写缓冲区所有有效条目地址比较
2. **优先级编码**：当多个条目命中时，选择最新的写入数据
3. **位级合并**：如果启用位掩码，合并多个部分写的结果
4. **前向/后向搜索**：从写指针位置前后搜索，确保获取最新数据

### 2.3 RAW冲突处理：fcip_mem_fake_find_new_bit

该模块专门处理启用位掩码时的细粒度RAW冲突检测。

**主要功能：**
- **逐位冲突检测**：针对每一位数据检测是否有写操作
- **多次写入合并**：当同一地址有多次部分写入时，合并所有有效位
- **最新数据选择**：使用前向/后向优先级编码器选择最新写入的位
- **位使能跟踪**：记录每一位是否在缓冲区中有有效数据

**算法流程：**
```
对于每一位 i (0 到 DATA_WIDTH-1):
    1. 检查所有缓冲条目是否命中该地址且该位使能
    2. 前向搜索：从写指针向前查找最近的命中
    3. 后向搜索：从写指针向后查找最近的命中
    4. 选择前向或后向结果（前向优先）
    5. 输出该位的数据和使能状态
```

### 2.4 SRAM控制器包装：fcip_mem_ctrl_wrap

该模块封装SRAM访问控制逻辑，处理时序和流水线。

**主要功能：**
- **MCP控制**：支持多周期路径，控制访问间隔
- **请求流水线**：在SRAM输入端添加可配置流水线级
- **响应流水线**：在SRAM输出端添加可配置流水线级
- **Sideband传递**：保持读请求的sideband信息与数据同步
- **读使能生成**：生成与数据延迟匹配的读使能信号
- **CDC标记**：插入标记单元用于时序约束

**MCP控制机制：**
- 当 MCP_CYCLE = 1：每周期可发起一次访问，无等待
- 当 MCP_CYCLE > 1：使用计数器控制，每 MCP_CYCLE 周期可发起一次访问
- 通过 mem_req_rdy 信号应用背压

### 2.5 读写仲裁器

仲裁器决定当读写请求同时到达时，优先处理哪一个。

**读优先模式（RW_ARBITER_TYPE = 0）：**
```
if (read_req_vld) {
    访问SRAM进行读操作
    同时检测RAW冲突
} else if (write_buffer_vld) {
    访问SRAM进行写操作
}
```

**写优先模式（RW_ARBITER_TYPE = 1）：**
```
if (write_buffer_vld) {
    访问SRAM进行写操作
} else if (read_req_vld) {
    访问SRAM进行读操作
    同时检测RAW冲突
}
```

**选择建议：**
- **读优先**：适合读多写少的场景，保证读延迟低且稳定
- **写优先**：适合写多读少的场景，防止写缓冲区溢出

### 2.6 读缓冲区

读缓冲区使用同步FIFO实现，用于解耦SRAM读延迟和用户读响应。

**主要功能：**
- **深度缓冲**：缓冲多个读响应，吸收突发读请求
- **阈值控制**：通过 almost_full 阈值控制读请求发起
- **数据转发**：可选的零延迟转发路径（READ_FORWARD_EN = 1）
- **流控管理**：通过 ready 信号应用背压

**转发机制：**
```
if (READ_FORWARD_EN == 1) {
    if (read_buffer_empty && read_resp_rdy) {
        直接转发 SRAM 读数据到输出
    } else {
        数据写入 FIFO，从 FIFO 读出
    }
} else {
    所有数据经过 FIFO
}
```

## 3. 接口描述

### 3.1 顶层模块参数

| 参数 | 类型 | 默认值 | 范围 | 描述 |
|------|------|--------|------|------|
| SRAM_ACCESS_LATENCY | integer unsigned | 1 | ≥1 | SRAM访问延迟（周期数） |
| SRAM_REQ_PIPE_STAGE | integer unsigned | 0 | ≥0 | SRAM请求端流水线级数 |
| SRAM_RSP_PIPE_STAGE | integer unsigned | 0 | ≥0 | SRAM响应端流水线级数 |
| SIDEBAND_WIDTH | integer unsigned | 1 | ≥1 | Sideband数据位宽 |
| DATA_WIDTH | integer unsigned | 128 | ≥1 | 数据位宽 |
| ADDR_WIDTH | integer unsigned | 10 | ≥1 | 地址位宽 |
| MCP_CYCLE | integer unsigned | 1 | ≥1 | 多周期路径周期数 |
| WRITE_BUFFER_SIZE | integer unsigned | 4 | ≥0 | 写缓冲区大小（0表示禁用） |
| RW_ARBITER_TYPE | integer unsigned | 0 | 0或1 | 仲裁类型：0=读优先，1=写优先 |
| READ_FORWARD_EN | integer unsigned | 1 | 0或1 | 读转发使能：0=禁用，1=启用 |
| READ_BUFFER_SIZE | integer unsigned | 4 | ≥延迟+1 | 读缓冲区大小 |
| WRITE_BIT_MASK_EN | integer unsigned | 1 | 0或1 | 位掩码使能：0=禁用，1=启用 |

### 3.2 端口定义

#### 3.2.1 时钟和复位

| 端口名称 | 方向 | 位宽 | 描述 |
|----------|------|------|------|
| clk | input | 1 | 系统时钟 |
| rst_n | input | 1 | 低电平有效异步复位 |

#### 3.2.2 写端口接口

| 端口名称 | 方向 | 位宽 | 协议 | 描述 |
|----------|------|------|------|------|
| write_req_vld | input | 1 | Valid-Ready | 写请求有效 |
| write_req_data | input | DATA_WIDTH | Valid-Ready | 写数据 |
| write_req_addr | input | ADDR_WIDTH | Valid-Ready | 写地址 |
| write_req_bit_en | input | DATA_WIDTH | Valid-Ready | 位使能（当WRITE_BIT_MASK_EN=1时有效） |
| write_req_rdy | output | 1 | Valid-Ready | 写请求就绪 |

**握手协议：**
- 写事务在 `write_req_vld && write_req_rdy` 时完成
- 写缓冲满时 `write_req_rdy` 取消断言
- `write_req_data`、`write_req_addr` 和 `write_req_bit_en` 必须在 `write_req_vld` 断言时保持稳定

#### 3.2.3 读端口接口

**读请求：**

| 端口名称 | 方向 | 位宽 | 协议 | 描述 |
|----------|------|------|------|------|
| read_req_vld | input | 1 | Valid-Ready | 读请求有效 |
| read_req_addr | input | ADDR_WIDTH | Valid-Ready | 读地址 |
| read_req_sideband | input | SIDEBAND_WIDTH | Valid-Ready | 读请求附带信息 |
| read_req_rdy | output | 1 | Valid-Ready | 读请求就绪 |

**读响应：**

| 端口名称 | 方向 | 位宽 | 协议 | 描述 |
|----------|------|------|------|------|
| read_resp_vld | output | 1 | Valid-Ready | 读响应有效 |
| read_resp_data | output | DATA_WIDTH | Valid-Ready | 读数据 |
| read_resp_sideband | output | SIDEBAND_WIDTH | Valid-Ready | 读响应附带信息 |
| read_resp_rdy | input | 1 | Valid-Ready | 读响应就绪 |

**握手协议：**
- 读请求在 `read_req_vld && read_req_rdy` 时接受
- 读响应在 `read_resp_vld && read_resp_rdy` 时完成
- Sideband 信息与对应的读数据一起返回

#### 3.2.4 SRAM接口

| 端口名称 | 方向 | 位宽 | 描述 |
|----------|------|------|------|
| spram_addr | output | ADDR_WIDTH | SRAM地址 |
| spram_din | output | DATA_WIDTH | SRAM写数据 |
| spram_dout | input | DATA_WIDTH | SRAM读数据 |
| spram_en | output | 1 | SRAM使能 |
| spram_wren | output | 1 | SRAM写使能：1=写，0=读 |
| spram_bit_en | output | DATA_WIDTH | SRAM位使能 |

**时序要求：**
- `spram_en` 为高时，SRAM执行操作
- `spram_wren` 决定读写方向
- 读数据在 SRAM_ACCESS_LATENCY 个周期后在 `spram_dout` 上有效

#### 3.2.5 控制端口

| 端口名称 | 方向 | 位宽 | 描述 |
|----------|------|------|------|
| stall | input | 1 | 暂停控制：1=阻塞新请求 |
| clear | input | 1 | 清除控制：1=清空内部状态 |
| idle | output | 1 | 空闲状态：1=所有缓冲区为空 |

## 4. 时序和时钟结构

### 4.1 时钟域

该设计为单时钟域设计，所有逻辑工作在同一时钟 `clk` 下。

### 4.2 延迟计算

**总SRAM访问延迟：**
```
MEM_LATENCY = SRAM_ACCESS_LATENCY + SRAM_REQ_PIPE_STAGE + SRAM_RSP_PIPE_STAGE
```

**读请求到读响应延迟：**
- 无转发（READ_FORWARD_EN = 0）：
  ```
  延迟 = MEM_LATENCY + 1（FIFO延迟）
  ```
- 有转发（READ_FORWARD_EN = 1）：
  ```
  最小延迟 = 0（直接转发）
  最大延迟 = MEM_LATENCY + 1（通过FIFO）
  ```

**写请求到SRAM延迟：**
- 写缓冲未满时：立即接受，延迟取决于仲裁和缓冲区排空
- 写缓冲满时：等待缓冲区有空闲空间

### 4.3 流水线配置建议

流水线配置需要在延迟和时序之间权衡：

**场景1：SRAM延迟大，需要优化时序**
```
SRAM_ACCESS_LATENCY = 2
SRAM_REQ_PIPE_STAGE = 1    // 在SRAM输入端打一拍
SRAM_RSP_PIPE_STAGE = 1    // 在SRAM输出端打一拍
READ_FORWARD_EN = 1        // 可以安全启用转发
```

**场景2：SRAM延迟小，追求低延迟**
```
SRAM_ACCESS_LATENCY = 1
SRAM_REQ_PIPE_STAGE = 0
SRAM_RSP_PIPE_STAGE = 0
READ_FORWARD_EN = 0        // 关闭转发以避免时序路径过长
```

**场景3：使用MCP进行时序优化**
```
MCP_CYCLE = 2              // 放松到2周期
SRAM_ACCESS_LATENCY = 1
SRAM_REQ_PIPE_STAGE = 0
SRAM_RSP_PIPE_STAGE = 0
```

### 4.4 时序约束建议

```tcl
# 时钟定义
create_clock -name clk -period <PERIOD> [get_ports clk]

# SRAM接口时序
set_output_delay -clock clk <SRAM_SETUP> [get_ports spram_*]
set_input_delay -clock clk <SRAM_CQ> [get_ports spram_dout]

# MCP约束（如果MCP_CYCLE > 1）
set_multicycle_path <MCP_CYCLE> -setup \
    -from [get_pins u_mem_ctrl_wrap/*] \
    -to [get_ports spram_*]
set_multicycle_path <MCP_CYCLE-1> -hold \
    -from [get_pins u_mem_ctrl_wrap/*] \
    -to [get_ports spram_*]

# 转发路径约束（如果READ_FORWARD_EN = 1）
set_max_delay <PERIOD> \
    -from [get_ports read_req_*] \
    -to [get_ports read_resp_*]
```

## 5. 功能行为

### 5.1 正常操作流程

#### 5.1.1 写操作流程

1. **接收写请求**
   - 用户断言 `write_req_vld`
   - 如果写缓冲未满，`write_req_rdy` 为高
   - 握手完成，写请求进入写缓冲

2. **缓冲管理**
   - 写请求按FIFO顺序排列
   - 写指针递增，记录下一个可用位置

3. **仲裁和SRAM写入**
   - 根据仲裁策略，写缓冲头部请求参与仲裁
   - 获得SRAM访问权后，执行写操作
   - 写完成后，读指针递增，释放缓冲空间

#### 5.1.2 读操作流程

1. **接收读请求**
   - 用户断言 `read_req_vld`
   - 如果读缓冲未接近满，`read_req_rdy` 为高
   - 握手完成，读请求进入处理

2. **RAW冲突检测**
   - 读地址与写缓冲所有有效条目比较
   - 如果命中，记录命中信息和数据
   - 命中信息延迟 MEM_LATENCY-1 周期，与SRAM数据对齐

3. **仲裁和SRAM读取**
   - 根据仲裁策略，读请求参与仲裁
   - 获得SRAM访问权后，执行读操作
   - SRAM数据经过 MEM_LATENCY 周期返回

4. **数据选择**
   - 如果有RAW冲突命中：
     - 无位掩码：使用写缓冲数据
     - 有位掩码：合并SRAM数据和写缓冲数据
   - 如果无冲突：使用SRAM数据

5. **读响应输出**
   - 数据进入读缓冲FIFO
   - 如果启用转发且FIFO为空：直接转发到输出
   - 否则：经过FIFO后输出

### 5.2 RAW冲突处理

**场景1：无位掩码（WRITE_BIT_MASK_EN = 0）**

```
时刻T0: 写请求 addr=0x100, data=0xAA (进入写缓冲)
时刻T1: 读请求 addr=0x100 (检测到冲突)
时刻T1+MEM_LATENCY: 输出 data=0xAA (来自写缓冲)
```

**场景2：有位掩码（WRITE_BIT_MASK_EN = 1）**

```
时刻T0: 写请求 addr=0x100, data=0xFF, bit_en=0x0F (低4位)
时刻T1: 写请求 addr=0x100, data=0xAA, bit_en=0xF0 (高4位)
时刻T2: 读请求 addr=0x100
假设SRAM原有数据=0x00
结果: data = (0x00 & ~0xFF) | (0xAA & 0xF0) | (0xFF & 0x0F)
     = 0x00 | 0xA0 | 0x0F = 0xAF
```

### 5.3 流控和背压

**写端背压：**
- 写缓冲满时，`write_req_rdy` 取消断言
- 用户必须等待直到有空间
- 建议写缓冲大小 ≥ 4，以吸收突发写入

**读端背压：**
- 读缓冲接近满时，`read_req_rdy` 取消断言
- 用户必须等待直到有空间
- 通过 `almost_full` 阈值提前应用背压

**下游背压：**
- 下游 `read_resp_rdy` 为低时，读响应暂停
- 读缓冲可能填满，进而阻塞新的读请求

### 5.4 特殊场景

#### 5.4.1 连续读写同一地址

```
周期1: 写 addr=A, data=D1
周期2: 读 addr=A
周期3: 写 addr=A, data=D2
周期4: 读 addr=A
```

- 周期2的读请求会检测到周期1的写在缓冲中，返回D1
- 周期4的读请求会检测到周期3的写在缓冲中，返回D2
- 即使周期1的写可能尚未写入SRAM，数据一致性仍能保证

#### 5.4.2 写缓冲溢出避免

- 写缓冲大小应根据读写比例和峰值写带宽设计
- 建议 WRITE_BUFFER_SIZE ≥ 平均写突发长度
- 如果写入持续大于读取，最终会导致写缓冲满

#### 5.4.3 MCP使用场景

- 当SRAM时序无法满足单周期访问时使用
- 设置 MCP_CYCLE = 2 或更大
- 代价是带宽减半或更少
- 需要相应增加缓冲区大小以维持吞吐量

## 6. 验证策略

### 6.1 验证目标

#### 6.1.1 主要目标

- **数据完整性**：所有写入的数据能正确读出
- **RAW一致性**：读后写冲突能正确处理，返回最新数据
- **协议合规**：Valid-Ready握手正确实现
- **缓冲区管理**：写缓冲和读缓冲正确管理，无溢出/下溢
- **仲裁公平性**：读写仲裁符合配置的策略
- **位掩码功能**：位级写入和合并逻辑正确
- **边界条件**：满、空、单条目等边界情况正确处理

#### 6.1.2 覆盖率目标

- 代码覆盖率：>95%
- 功能覆盖率：100%
- 断言覆盖率：所有断言被触发
- 参数覆盖率：所有参数组合测试

### 6.2 测试平台架构

```
TB Top
├── 时钟和复位生成器
├── 写端驱动器（BFM）
│   ├── 随机写请求生成
│   ├── 地址和数据生成器
│   ├── 位掩码生成器
│   └── 流控管理
├── 读端驱动器（BFM）
│   ├── 随机读请求生成
│   ├── 地址生成器
│   ├── Sideband生成器
│   └── 流控管理
├── 读响应监控器
│   ├── 数据捕获
│   └── Sideband校验
├── SRAM模型
│   ├── 单端口SRAM行为模型
│   ├── 可配置延迟
│   └── 读写操作模拟
├── 参考模型
│   ├── 理想双端口存储器模型
│   ├── 写操作记录
│   ├── 读操作预测
│   └── RAW冲突处理
├── 记分板
│   ├── 写数据记录
│   ├── 读数据比较
│   └── 统计信息
└── 覆盖率收集器
    ├── 功能覆盖率
    └── 代码覆盖率
```

### 6.3 测试计划

#### 6.3.1 基本功能测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|--------|----------|------|----------|
| BF001 | 单次写后读 | 写一个地址，然后读同一地址 | 读出的数据与写入的数据匹配 |
| BF002 | 连续写入 | 连续写多个地址 | 所有写入成功，无丢失 |
| BF003 | 连续读取 | 连续读多个地址 | 所有读取返回正确数据 |
| BF004 | 写缓冲填满 | 写入直到缓冲满 | write_req_rdy正确取消断言 |
| BF005 | 读缓冲填满 | 读取直到缓冲满 | read_req_rdy正确取消断言 |
| BF006 | 随机读写混合 | 随机地址和操作 | 所有数据一致性保持 |
| BF007 | 地址扫描 | 遍历所有地址空间 | 所有地址可访问 |
| BF008 | 数据模式测试 | 全0、全1、行走1等 | 所有数据模式正确 |

#### 6.3.2 RAW冲突测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|--------|----------|------|----------|
| RAW001 | 立即RAW | 写后立即读同一地址 | 返回写入的新数据 |
| RAW002 | 延迟RAW | 写后延迟N周期读 | 正确检测冲突或从SRAM读 |
| RAW003 | 多次写后读 | 多次写同一地址，然后读 | 返回最后一次写入的数据 |
| RAW004 | 交错RAW | 写A、读A、写A、读A | 每次读返回对应的写数据 |
| RAW005 | 无位掩码RAW | 完整字写入和读取 | 完整数据替换 |
| RAW006 | 位掩码RAW单次 | 部分位写入后读取 | 正确合并SRAM和缓冲数据 |
| RAW007 | 位掩码RAW多次 | 多次部分位写入后读取 | 正确合并多次写入结果 |
| RAW008 | 交叉位掩码 | 写不同位，然后读取 | 所有写入位正确合并 |
| RAW009 | 重叠位掩码 | 写重叠位，然后读取 | 最新写入覆盖旧数据 |
| RAW010 | 缓冲区满RAW | 写缓冲满时的RAW | 仍能正确检测和转发 |

#### 6.3.3 仲裁测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|--------|----------|------|----------|
| ARB001 | 读优先仲裁 | 读写同时到达，读优先模式 | 读请求先处理 |
| ARB002 | 写优先仲裁 | 读写同时到达，写优先模式 | 写请求先处理 |
| ARB003 | 持续读压力 | 持续读请求，偶尔写入 | 写入能获得服务 |
| ARB004 | 持续写压力 | 持续写请求，偶尔读取 | 读取能获得服务 |
| ARB005 | 交替读写 | 交替发起读写请求 | 按仲裁策略正确处理 |

#### 6.3.4 流控测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|--------|----------|------|----------|
| FC001 | 写端背压 | 写缓冲满时持续写 | 不接受新请求，无溢出 |
| FC002 | 读端背压 | 读缓冲满时持续读 | 不接受新请求，无溢出 |
| FC003 | 下游背压 | read_resp_rdy持续为低 | 正确传播背压 |
| FC004 | Stall控制 | 断言stall信号 | 停止接受新请求 |
| FC005 | Clear控制 | 断言clear信号 | 清空内部状态 |
| FC006 | Idle检测 | 所有缓冲空闲 | idle信号正确断言 |

#### 6.3.5 参数化测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|--------|----------|------|----------|
| PAR001 | SRAM延迟扫描 | 测试不同SRAM_ACCESS_LATENCY | 所有延迟配置正常工作 |
| PAR002 | 流水线级数扫描 | 测试不同REQ/RSP_PIPE_STAGE | 所有流水线配置正常工作 |
| PAR003 | 写缓冲大小扫描 | 测试不同WRITE_BUFFER_SIZE | 包括0（禁用）在内都正常 |
| PAR004 | 读缓冲大小扫描 | 测试不同READ_BUFFER_SIZE | 所有大小配置正常工作 |
| PAR005 | MCP周期扫描 | 测试不同MCP_CYCLE | 所有MCP配置正常工作 |
| PAR006 | 数据位宽扫描 | 测试不同DATA_WIDTH | 从小到大都正常工作 |
| PAR007 | 地址位宽扫描 | 测试不同ADDR_WIDTH | 所有地址空间正常 |
| PAR008 | 转发使能切换 | 测试READ_FORWARD_EN=0/1 | 两种模式都正常工作 |
| PAR009 | 位掩码使能切换 | 测试WRITE_BIT_MASK_EN=0/1 | 两种模式都正常工作 |
| PAR010 | 仲裁类型切换 | 测试RW_ARBITER_TYPE=0/1 | 两种仲裁策略都正常 |

#### 6.3.6 压力和性能测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|--------|----------|------|----------|
| STR001 | 满带宽写入 | 持续最大速率写入 | 达到理论带宽，无错误 |
| STR002 | 满带宽读取 | 持续最大速率读取 | 达到理论带宽，无错误 |
| STR003 | 读写均衡 | 50%读50%写 | 带宽分配合理 |
| STR004 | 突发写入 | 短时间大量写入 | 写缓冲正确吸收 |
| STR005 | 突发读取 | 短时间大量读取 | 读缓冲正确缓冲 |
| STR006 | 长时间运行 | 运行1M+周期 | 无死锁，数据一致 |
| STR007 | 地址局部性 | 集中访问少量地址 | RAW检测高效工作 |
| STR008 | 地址随机性 | 完全随机地址 | 正常工作，无特殊问题 |

#### 6.3.7 边界和错误场景

| 测试ID | 测试名称 | 描述 | 通过标准 |
|--------|----------|------|----------|
| EDG001 | 最小地址 | 访问地址0 | 正常工作 |
| EDG002 | 最大地址 | 访问地址2^ADDR_WIDTH-1 | 正常工作 |
| EDG003 | 单条目缓冲 | WRITE_BUFFER_SIZE=1 | 正常工作 |
| EDG004 | 最小读缓冲 | READ_BUFFER_SIZE=延迟+1 | 正常工作 |
| EDG005 | 禁用写缓冲 | WRITE_BUFFER_SIZE=0 | 正常工作（无RAW保护） |
| EDG006 | 最小数据位宽 | DATA_WIDTH=1 | 正常工作 |
| EDG007 | 大数据位宽 | DATA_WIDTH=512+ | 正常工作 |
| EDG008 | 复位期间操作 | 复位撤销前后的请求 | 正确处理，无非法状态 |

### 6.4 覆盖率计划

#### 6.4.1 功能覆盖率定义

```systemverilog
covergroup cg_write_buffer;
    cp_size: coverpoint write_buffer_entries {
        bins empty = {0};
        bins partial = {[1:WRITE_BUFFER_SIZE-1]};
        bins full = {WRITE_BUFFER_SIZE};
    }
    cp_write: coverpoint write_req_vld && write_req_rdy;
    cp_drain: coverpoint write_buffer_drain;
    cross cp_size, cp_write;
endgroup

covergroup cg_raw_hazard;
    cp_raw_hit: coverpoint read_cmp_hit;
    cp_bit_mask: coverpoint WRITE_BIT_MASK_EN;
    cp_multiple_hit: coverpoint multiple_entries_hit;
    cross cp_raw_hit, cp_bit_mask;
endgroup

covergroup cg_arbiter;
    cp_read_req: coverpoint read_req_vld;
    cp_write_req: coverpoint write_sram_vld;
    cp_arb_type: coverpoint RW_ARBITER_TYPE;
    cross cp_read_req, cp_write_req, cp_arb_type;
endgroup

covergroup cg_forwarding;
    cp_forward_en: coverpoint READ_FORWARD_EN;
    cp_forward_active: coverpoint forward_path_used;
    cp_buffer_empty: coverpoint read_buffer_empty;
    cross cp_forward_en, cp_forward_active;
endgroup
```

#### 6.4.2 断言计划

```systemverilog
// 写缓冲不溢出
property p_write_buffer_no_overflow;
    @(posedge clk) disable iff (!rst_n)
    write_req_vld && !write_req_rdy |-> $past(buffer_full);
endproperty

// 读响应数据正确性（简化检查）
property p_read_data_valid;
    @(posedge clk) disable iff (!rst_n)
    read_resp_vld |-> !$isunknown(read_resp_data);
endproperty

// RAW命中时数据来自写缓冲
property p_raw_hit_data_source;
    @(posedge clk) disable iff (!rst_n)
    read_cmp_hit_delay && !WRITE_BIT_MASK_EN 
    |-> read_out_data == read_hit_data_delay;
endproperty

// MCP周期控制正确
property p_mcp_cycle_control;
    @(posedge clk) disable iff (!rst_n)
    (MCP_CYCLE > 1) && mem_req_handshake 
    |-> ##[1:MCP_CYCLE-1] !mem_req_rdy ##1 mem_req_rdy;
endproperty

// Sideband保持一致
property p_sideband_consistency;
    logic [SIDEBAND_WIDTH-1:0] sb;
    @(posedge clk) disable iff (!rst_n)
    (read_req_vld && read_req_rdy, sb = read_req_sideband)
    ##MEM_LATENCY read_resp_vld |-> read_resp_sideband == sb;
endproperty
```

### 6.5 回归测试策略

#### 6.5.1 快速回归（<10分钟）

- 基本功能测试（BF001-BF008）
- 简单RAW测试（RAW001-RAW003）
- 基本流控测试（FC001-FC003）
- 运行频率：每次提交

#### 6.5.2 每日回归（2-4小时）

- 所有基本功能测试
- 所有RAW冲突测试
- 所有仲裁和流控测试
- 关键参数配置测试
- 运行频率：每日

#### 6.5.3 每周回归（24小时）

- 所有测试用例
- 参数扫描测试
- 压力测试
- 长时间运行测试
- 运行频率：每周

#### 6.5.4 发布回归（多日）

- 所有测试用例
- 多随机种子
- 详尽参数组合
- 极限压力测试
- 运行频率：发布前

### 6.6 调试和分析

#### 6.6.1 关键波形信号

**写路径：**
- `write_req_vld`, `write_req_rdy`, `write_req_addr`, `write_req_data`
- `wr_ptr`, `rd_ptr`, `write_buffer_full`, `write_buffer_empty`
- `write_sram_vld`, `write_sram_rdy`

**读路径：**
- `read_req_vld`, `read_req_rdy`, `read_req_addr`
- `read_resp_vld`, `read_resp_rdy`, `read_resp_data`
- `read_cmp_vld`, `read_cmp_hit`, `read_hit_data`

**SRAM接口：**
- `spram_en`, `spram_wren`, `spram_addr`
- `spram_din`, `spram_dout`

**仲裁和控制：**
- `mem_req_vld`, `mem_req_rdy`, `mem_req_opcode`
- `fifo_almost_full`, `read_buffer_empty`

#### 6.6.2 常见问题诊断

**问题1：读出的数据不正确**
- 检查写请求是否成功（write_req_vld && write_req_rdy）
- 检查RAW冲突检测（read_cmp_hit）
- 查看SRAM写入时序
- 验证数据合并逻辑（如果有位掩码）

**问题2：死锁**
- 检查流控信号（ready信号是否组合依赖）
- 查看缓冲区状态（是否满且无法排空）
- 验证仲裁逻辑

**问题3：性能不达预期**
- 查看仲裁策略是否合适
- 检查缓冲区大小是否足够
- 分析写缓冲命中率

## 7. 设计约束和限制

### 7.1 参数约束

| 参数 | 约束 | 说明 |
|------|------|------|
| WRITE_BUFFER_SIZE | ≥0 | 0表示禁用写缓冲 |
| READ_BUFFER_SIZE | ≥ MEM_LATENCY+1 | 必须能容纳流水线中的数据 |
| SRAM_ACCESS_LATENCY | ≥1 | 至少1周期延迟 |
| MCP_CYCLE | ≥1 | 1表示无MCP |

### 7.2 使用建议

- **小存储器（<512字节）**：考虑使用寄存器阵列方案
- **中等存储器**：本设计最适用
- **大存储器**：评估SRAM宏单元，可能需要真双端口
- **写多读少**：使用写优先仲裁，增大写缓冲
- **读多写少**：使用读优先仲裁，可以减小写缓冲
- **低延迟要求**：启用READ_FORWARD_EN，减少流水线级数
- **高频率要求**：增加流水线级数，考虑MCP

### 7.3 已知限制

- 最大带宽为单端口SRAM带宽（1次操作/周期，或1/MCP_CYCLE）
- 写缓冲禁用时无RAW保护，需要软件保证
- 位掩码功能会增加组合路径深度，可能影响时序
- 大写缓冲会增加面积和功耗

## 8. 附录

### 8.1 缩写和术语

| 术语 | 定义 |
|------|------|
| RAW | Read-After-Write，读后写冲突 |
| MCP | Multi-Cycle Path，多周期路径 |
| SRAM | Static Random Access Memory，静态随机存取存储器 |
| SPRAM | Single-Port RAM，单端口RAM |
| FIFO | First-In-First-Out，先进先出 |
| BFM | Bus Functional Model，总线功能模型 |

### 8.2 参考文档

- 内部SRAM规格书
- FCIP设计规范
- SystemVerilog IEEE 1800标准

### 8.3 修订历史

| 版本 | 日期 | 作者 | 描述 |
|------|------|------|------|
| 1.0 | 2026-02-03 | jiaoyadi | 初始版本 |

---

**文档结束**