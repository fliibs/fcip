# 异步FIFO设计规范

## 文档信息

| 项目 | 描述 |
|------|-------------|
| 文档标题 | 异步FIFO设计规范 |
| 模块名称 | fcip_afifo |
| 版本 | 1.0 |
| 日期 | 2026年2月3日 |
| 作者 | jiaoyadi |

## 1. 概述

### 1.1 简介

`fcip_afifo` 是一个完整的异步FIFO（先进先出）设计，用于在两个独立时钟域之间实现安全的数据传输。该设计采用基于指针的架构，使用johnson counter编码转换确保CDC（跨时钟域）安全性。基于寄存器的存储方式，在slv端选择数据，减少slv和mst之间的数据连线。

### 1.2 主要特性

- **双时钟域支持**：独立的写时钟（wclk）和读时钟（rclk）
- **可配置深度**：参数化的FIFO深度，支持2的幂次方大小
- **可配置数据宽度**：参数化的数据宽度，支持任意位宽
- **johnson counter编码指针同步**：使用johnson counter编码编码的CDC安全指针同步机制
- **自动清零功能**：可选的空闲期间自动指针恢复到零状态
- **阈值指示器**：可选的almost_full和almost_empty阈值标志
- **Lowpower管理**：读写两侧独立的stall和clear控制
- **全零检测**：FIFO指针复位到初始状态时的状态指示
- **基于寄存器的存储**：并行寄存器阵列实现，低延迟

### 1.3 设计层次结构

```
fcip_afifo (顶层模块)
├── fcip_afifo_slv (写侧/从设备)
│   ├── fcip_clk_marker (写时钟标记)
│   ├── fcip_fix_arb (固定仲裁器 - 自动清零模式)
│   ├── fcip_sync_cell (读指针同步器)
│   ├── fcip_marker (CDC标记 x4)
│   └── 寄存器阵列 [FIFO_DEPTH-1:0]
│
└── fcip_afifo_mst (读侧/主设备)
    ├── fcip_clk_marker (读时钟标记)
    ├── fcip_sync_cell (写指针同步器)
    └── fcip_marker (CDC标记 x4)
```

## 2. 模块功能说明

### 2.1 顶层模块：fcip_afifo

顶层模块 `fcip_afifo` 实例化并连接写侧从设备模块（`fcip_afifo_slv`）和读侧主设备模块（`fcip_afifo_mst`）。它提供数据传输和控制信号的外部接口。

**主要功能：**
- 写时钟域和读时钟域的接口聚合
- 写侧和读侧之间异步控制信号的连接
- 参数传递到子模块

### 2.2 写侧模块：fcip_afifo_slv

写侧从设备模块在写时钟域中处理数据写操作。

**主要功能：**
- **数据写控制**：通过valid-ready握手协议接收输入数据
- **写指针管理**：维护独热编码的写指针用于地址解码
- **满状态检测**：比较本地写指针与同步的读指针以确定满状态
- **自动清零气泡生成**：当AUTO_CLEAR_EN启用时，生成空entry来重置指针
- **读指针同步**：将读侧指针同步到写时钟域
- **数据存储**：使用独热写使能将数据写入并行寄存器阵列
- **Almost Full阈值**：可选的流控阈值检测
- **全零状态**：指示写指针和读指针都已返回零状态

**操作流程：**
1. 通过 `s_vld/s_pld` 接口接收数据，配合就绪信号 `s_rdy`
2. 当AUTO_CLEAR_EN启用时，在正常数据和气泡包之间进行仲裁
3. 每次写事务时递增写指针（sync和async）
4. 通过比较写指针与同步的读指针生成满信号
5. 使用独热写指针索引将数据存储在寄存器阵列中

### 2.3 读侧模块：fcip_afifo_mst

读侧主设备模块在读时钟域中处理数据读操作。

**主要功能：**
- **数据读控制**：通过valid-ready握手协议提供输出数据
- **读指针管理**：维护独热编码的读指针用于数据选择
- **空状态检测**：比较本地读指针与同步的写指针以确定空状态
- **写指针同步**：将写侧指针同步到读时钟域
- **数据多路复用**：使用独热读指针从寄存器阵列中选择数据
- **自动清零气泡过滤**：当AUTO_CLEAR_EN启用时过滤气泡条目
- **Almost Empty阈值**：可选的流控阈值检测
- **空闲状态**：指示FIFO为空（无可用数据）

**操作流程：**
1. 基于读指针和同步的写指针监控空状态
2. 当数据可用且下游就绪时，递增读指针
3. 基于独热读指针从寄存器阵列多路复用数据
4. 在寄存器切片中缓冲读取的数据以优化时序
5. 当AUTO_CLEAR_EN启用时，在输出前过滤气泡包

### 2.4 指针架构

#### 2.4.1 指针编码

设计使用双指针表示方式：

1. **同步指针（wptr_sync/rptr_sync）**：独热编码指针
   - 在本地时钟域内使用
   - 直接地址解码用于写使能和数据多路复用
   - 初始值：`{(FIFO_DEPTH-1){1'b0}, 1'b1}` （位置0处为独热）

2. **异步指针（wptr_async/rptr_async）**：johnson counter编码指针
   - 用于跨域同步
   - 改进的johnson counter编码，在回卷时反转MSB
   - 初始值：`{FIFO_DEPTH{1'b0}}`

#### 2.4.2 指针更新规则

**写指针更新：**
```
wptr_sync_next = {wptr_sync[FIFO_DEPTH-2:0], wptr_sync[FIFO_DEPTH-1]}  // 循环左移
wptr_async_next = {wptr_async[FIFO_DEPTH-2:0], ~wptr_async[FIFO_DEPTH-1]}  // 循环左移并反转MSB
```

**读指针更新：**
```
rptr_sync_next = {rptr_sync[FIFO_DEPTH-2:0], rptr_sync[FIFO_DEPTH-1]}  // 循环左移
rptr_async_next = {rptr_async[FIFO_DEPTH-2:0], ~rptr_async[FIFO_DEPTH-1]}  // 循环左移并反转MSB
```

#### 2.4.3 满/空检测

**满条件（写侧）：**
```
full = |((wptr_async ^ rptr_sync_from_read) & wptr_sync)
```

**空条件（读侧）：**
```
empty = ~(|((rptr_async ^ wptr_sync_from_write) & rptr_sync))
```

### 2.5 自动清零功能

当 `AUTO_CLEAR_EN` 设置为1时，FIFO实现自动指针恢复：

**写侧：**
- 气泡生成器连续请求写入空条目（pld[0] = 0）
- 固定仲裁器优先处理正常数据而不是气泡包
- 仅当FIFO未满且无正常数据时才写入气泡包
- 在空闲期间逐渐将指针推回零位置

**读侧：**
- 读操作过滤掉气泡包
- 仅将有效数据包（pld[0] = 1）转发到输出
- 气泡包被消耗但不在主接口上呈现

**全零状态：**
- 写侧监控：`rd_async_ptr_zero && wr_ptr_zero`
- 读侧监控：`wr_async_ptr_zero && rd_ptr_zero`
- 指示成功将指针恢复到初始状态

## 3. 接口描述

### 3.1 顶层模块端口：fcip_afifo

#### 3.1.1 参数

| 参数 | 类型 | 默认值 | 范围 | 描述 |
|-----------|------|---------|-------|-------------|
| FIFO_DEPTH | integer unsigned | 16 | 必须是2的幂 | FIFO深度（条目数量） |
| DATA_WIDTH | integer unsigned | 16 | ≥1 | 数据总线宽度（位数） |
| AUTO_CLEAR_EN | integer unsigned | 0 | 0或1 | 启用自动指针恢复：0=禁用，1=启用 |
| THRESHOLD_EN | integer unsigned | 0 | 0或1 | 启用阈值指示器：0=禁用，1=启用 |
| ALMOST_FULL_THRESHOLD | integer unsigned | 12 | <FIFO_DEPTH | almost_full断言阈值（条目数） |
| ALMOST_EMPTY_THRESHOLD | integer unsigned | 4 | <FIFO_DEPTH | almost_empty断言阈值（条目数） |
| SYNC_STAGE | integer unsigned | 2 | 2或3 | CDC同步级数 |
| VT_TYPE | integer unsigned | 1 | 0-5 | 单元电压阈值类型：0=SVT, 1=LVT, 2=ULVT, 3=ELVT, 4=LVTLL, 5=ULVTLL |

#### 3.1.2 时钟和复位端口

| 端口名称 | 方向 | 位宽 | 时钟域 | 描述 |
|-----------|-----------|-------|--------------|-------------|
| wclk | input | 1 | - | 写时钟 |
| rclk | input | 1 | - | 读时钟 |
| wrst_n | input | 1 | wclk | 写域低电平有效异步复位 |
| rrst_n | input | 1 | rclk | 读域低电平有效异步复位 |

#### 3.1.3 控制端口

| 端口名称 | 方向 | 位宽 | 时钟域 | 描述 |
|-----------|-----------|-------|--------------|-------------|
| write_stall | input | 1 | wclk | 写暂停控制：1=阻塞正常写入（允许自动清零气泡） |
| read_stall | input | 1 | rclk | 读暂停控制：1=阻塞读数据输出（允许内部读取用于自动清零） |
| write_clear | input | 1 | wclk | 写侧同步清除：1=立即复位写指针 |
| read_clear | input | 1 | rclk | 读侧同步清除：1=立即复位读指针 |
| write_full_zero | output | 1 | wclk | 写侧全零状态：1=指针已复位到零状态 |
| read_full_zero | output | 1 | rclk | 读侧全零状态：1=指针已复位到零状态 |
| read_idle | output | 1 | rclk | 读空闲状态：1=FIFO为空，无可用数据 |

#### 3.1.4 阈值端口

| 端口名称 | 方向 | 位宽 | 时钟域 | 描述 |
|-----------|-----------|-------|--------------|-------------|
| almost_full | output | 1 | wclk | Almost full指示器：1=条目数量 ≥ ALMOST_FULL_THRESHOLD |
| almost_empty | output | 1 | rclk | Almost empty指示器：1=条目数量 ≤ ALMOST_EMPTY_THRESHOLD |

#### 3.1.5 数据接口 - 从端口（写侧）

| 端口名称 | 方向 | 位宽 | 时钟域 | 协议 | 描述 |
|-----------|-----------|-------|--------------|----------|-------------|
| s_vld | input | 1 | wclk | Valid-Ready | 从设备有效：1=s_pld上的数据有效 |
| s_pld | input | DATA_WIDTH | wclk | Valid-Ready | 从设备载荷：写数据 |
| s_rdy | output | 1 | wclk | Valid-Ready | 从设备就绪：1=FIFO可以接收数据 |

**握手协议：**
- 当 `s_vld && s_rdy` 为真时发生写事务
- FIFO满时 `s_rdy` 取消断言
- `s_vld` 必须保持断言直到握手完成
- 当 `s_vld` 断言时，`s_pld` 必须保持稳定直到握手

#### 3.1.6 数据接口 - 主端口（读侧）

| 端口名称 | 方向 | 位宽 | 时钟域 | 协议 | 描述 |
|-----------|-----------|-------|--------------|----------|-------------|
| m_vld | output | 1 | rclk | Valid-Ready | 主设备有效：1=m_pld上的数据有效 |
| m_pld | output | DATA_WIDTH | rclk | Valid-Ready | 主设备载荷：读数据 |
| m_rdy | input | 1 | rclk | Valid-Ready | 主设备就绪：1=下游可以接收数据 |

**握手协议：**
- 当 `m_vld && m_rdy` 为真时发生读事务
- FIFO为空时 `m_vld` 取消断言
- 可以取消断言 `m_rdy` 来应用背压
- 当 `m_vld` 断言时，`m_pld` 保持稳定直到握手

### 3.2 子模块接口

#### 3.2.1 fcip_afifo_slv内部信号

**到读侧的异步接口：**
- `wptr_async[FIFO_DEPTH-1:0]`：用于跨域比较的写指针（输出到读侧）
- `rptr_async[FIFO_DEPTH-1:0]`：来自读侧的读指针（来自读侧的输入）

**到读侧的同步接口：**
- `rptr_sync[FIFO_DEPTH-1:0]`：同步到写时钟的读指针
- `pld_sync[DATA_WIDTH:0]`：从读侧寄存器阵列同步的数据

#### 3.2.2 fcip_afifo_mst内部信号

**到写侧的异步接口：**
- `rptr_async[FIFO_DEPTH-1:0]`：用于跨域比较的读指针（输出到写侧）
- `wptr_async[FIFO_DEPTH-1:0]`：来自写侧的写指针（来自写侧的输入）

**到写侧的同步接口：**
- `rptr_sync[FIFO_DEPTH-1:0]`：用于写侧比较的读指针（输出到写侧）
- `pld_sync[DATA_WIDTH:0]`：来自写侧寄存器阵列的数据（来自写侧的输入）

## 4. 时钟域结构

### 4.1 时钟域概览

该设计包含两个独立的时钟域，彼此异步：

```
┌─────────────────────────────────────────────────────────────┐
│                     写时钟域 (wclk)                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              fcip_afifo_slv                          │   │
│  │  • 写控制逻辑                                         │   │
│  │  • 写指针生成 (wptr_sync, wptr_async)                │   │
│  │  • 满状态检测逻辑                                     │   │
│  │  • 寄存器阵列存储                                     │   │
│  │  • 自动清零气泡生成器和仲裁器                         │   │
│  │  • 读指针同步器 (rptr_async → sync)                  │   │
│  │  • Almost Full阈值逻辑                               │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              ↕ CDC信号
                    ┌─────────────────────────┐
                    │  wptr_async  →          │
                    │  rptr_async  ←          │
                    │  rptr_sync   →          │
                    │  pld_sync    ←          │
                    └─────────────────────────┘
                              ↕ CDC信号
┌─────────────────────────────────────────────────────────────┐
│                     读时钟域 (rclk)                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              fcip_afifo_mst                          │   │
│  │  • 读控制逻辑                                         │   │
│  │  • 读指针生成 (rptr_sync, rptr_async)                │   │
│  │  • 空状态检测逻辑                                     │   │
│  │  • 数据多路复用器（来自寄存器阵列）                   │   │
│  │  • 寄存器切片（响应缓冲）                             │   │
│  │  • 自动清零气泡过滤器                                 │   │
│  │  • 写指针同步器 (wptr_async → sync)                  │   │
│  │  • Almost Empty阈值逻辑                              │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 跨时钟域路径

#### 4.2.1 写时钟域到读时钟域的跨越

| 信号名称 | 源时钟域 | 目标时钟域 | 位宽 | 同步方法 | 用途 |
|-------------|---------------|-------------------|-------|------------------------|---------|
| wptr_async | wclk | rclk | FIFO_DEPTH | 多级同步器（fcip_sync_cell） | 用于空状态检测的写指针 |
| pld_sync | wclk | rclk | DATA_WIDTH+1 | 从寄存器阵列异步读取 + 标记 | 数据载荷传输 |

**同步细节：**
- `wptr_async`：使用2级或3级同步器（通过SYNC_STAGE配置）
- 同步值：`rq2_wptr_sync1` 用于空状态检测
- `pld_sync`：从寄存器阵列组合读取，不需要同步器（当读指针有效时数据稳定）

#### 4.2.2 读时钟域到写时钟域的跨越

| 信号名称 | 源时钟域 | 目标时钟域 | 位宽 | 同步方法 | 用途 |
|-------------|---------------|-------------------|-------|------------------------|---------|
| rptr_async | rclk | wclk | FIFO_DEPTH | 多级同步器（fcip_sync_cell） | 用于满状态检测的读指针 |
| rptr_sync | rclk | wclk | FIFO_DEPTH | 直接连接（仅标记） | 用于数据多路复用的读指针 |

**同步细节：**
- `rptr_async`：使用2级或3级同步器（通过SYNC_STAGE配置）
- 同步值：`wq2_rptr_sync1` 用于满状态检测
- `rptr_sync`：通过CDC标记连接，用于写域中的数据选择

### 4.3 CDC安全机制

#### 4.3.1 指针johnson counter编码编码

设计使用johnson counter编码方案进行指针同步：
- 独热到johnson counter编码转换最小化多位转换
- 回卷时MSB反转确保单位变化
- 同步器使用可配置的2级或3级（SYNC_STAGE参数）

#### 4.3.2 CDC标记

插入特殊标记单元（`fcip_marker`）用于：
- **尺寸隔离**：防止CDC时序路径影响功能逻辑
- **SDC约束应用**：为set_max_delay约束提供锚点
- **电压阈值控制**：VT_TYPE参数用于工艺角优化

**标记位置：**
- 写侧：4个标记（rptr_sync, rptr_async, pld_sync, wptr_async）
- 读侧：4个标记（rptr_sync, rptr_async, pld_sync, wptr_async）

#### 4.3.3 时钟标记

时钟标记单元（`fcip_clk_marker`）用于：
- 为FIFO逻辑创建专用时钟树分支
- 启用独立的时钟约束组
- 支持电压阈值特定的时序优化

### 4.4 复位处理

#### 4.4.1 独立复位域

- 写侧：`wrst_n`（wclk域中的异步复位）
- 读侧：`rrst_n`（rclk域中的异步复位）
- 复位域之间无需同步
- 每个域独立复位到安全空闲状态

#### 4.4.2 复位行为

**写侧复位：**
```
wptr_sync  ← {(FIFO_DEPTH-1){1'b0}, 1'b1}  // 位置0处独热
wptr_async ← {FIFO_DEPTH{1'b0}}             // 全零
full       ← 0
```

**读侧复位：**
```
rptr_sync  ← {(FIFO_DEPTH-1){1'b0}, 1'b1}  // 位置0处独热
rptr_async ← {FIFO_DEPTH{1'b0}}             // 全零
empty      ← 1
```

#### 4.4.3 同步清除

- `write_clear`：写域中的同步清除（覆盖正常操作）
- `read_clear`：读域中的同步清除（覆盖正常操作）
- 清除操作将指针重置为初始值
- 用于无需完全复位的受控FIFO刷新

### 4.5 时序约束要求

#### 4.5.1 时钟约束

```tcl
# 定义独立时钟
create_clock -name wclk -period <WRITE_PERIOD> [get_ports wclk]
create_clock -name rclk -period <READ_PERIOD> [get_ports rclk]

# 时钟异步
set_clock_groups -asynchronous -group wclk -group rclk
```

#### 4.5.2 CDC路径约束

**写域到读域：**
```tcl
# wptr_async同步
set_max_delay -from [get_pins u_afifo_slv/wptr_async_marker_*/Z] \
              -to [get_pins u_afifo_mst/u_*_sync_cell/*/D] \
              <MIN(wclk_period, rclk_period)>

# 数据路径（pld_sync）
set_max_delay -from [get_pins u_afifo_slv/async_pld_sync_marker/Z] \
              -to [get_pins u_afifo_mst/async_pld_sync_marker/I] \
              <MIN(wclk_period, rclk_period)>
```

**读域到写域：**
```tcl
# rptr_async同步
set_max_delay -from [get_pins u_afifo_mst/rptr_async_marker_*/Z] \
              -to [get_pins u_afifo_slv/u_*_sync_cell/*/D] \
              <MIN(wclk_period, rclk_period)>

# rptr_sync路径
set_max_delay -from [get_pins u_afifo_mst/async_rptr_sync_marker/Z] \
              -to [get_pins u_afifo_slv/async_rptr_sync_marker/I] \
              <MIN(wclk_period, rclk_period)>
```

#### 4.5.3 假路径约束

```tcl
# 复位信号安全跨域
set_false_path -from [get_ports wrst_n] -to [get_pins u_afifo_mst/*]
set_false_path -from [get_ports rrst_n] -to [get_pins u_afifo_slv/*]
```

## 5. 功能行为

### 5.1 正常操作模式

#### 5.1.1 标准FIFO模式（AUTO_CLEAR_EN = 0）

**写操作：**
1. 数据呈现在 `s_pld` 上，`s_vld` 断言
2. 如果 `s_rdy` 为高（未满），写操作在wclk上升沿发生
3. 数据存储在 `wptr_sync` 指示位置的寄存器阵列中
4. 写指针递增：`wptr_sync` 和 `wptr_async`
5. 每个周期检查满条件

**读操作：**
1. 当非空时，数据可供读取
2. 如果 `m_rdy` 为高，读操作在rclk上升沿发生
3. 使用 `rptr_sync` 从寄存器阵列多路复用数据
4. 数据在寄存器切片中缓冲
5. 读指针递增：`rptr_sync` 和 `rptr_async`
6. 每个周期检查空条件

#### 5.1.2 自动清零模式（AUTO_CLEAR_EN = 1）

**写侧增强：**
- 在输入和FIFO写控制之间添加固定仲裁器
- 优先级：正常数据（s_vld）> 气泡包
- 当 `full_zero` 未断言时，气泡生成器连续请求
- 气泡包：`{DATA_WIDTH{1'b0}, 1'b0}`（bit[0] = 0表示气泡）
- 正常包：`{s_pld, 1'b1}`（bit[0] = 1表示有效数据）

**读侧增强：**
- 读操作正常进行，从FIFO消耗数据
- 响应掩码过滤气泡包：`bubble_en = ~reg_slice_pld_r[0]`
- 仅在 `m_vld/m_pld` 接口上呈现有效数据（bit[0] = 1）
- 气泡在内部消耗但不输出

**指针恢复过程：**
1. 在空闲期间（无正常写入），气泡被写入FIFO
2. 读侧消耗气泡（和任何剩余数据）
3. 指针逐渐向回卷方向推进
4. 最终两个指针都返回零状态
5. 完成时 `full_zero` 信号断言

### 5.2 流控

#### 5.2.1 背压处理

**写侧：**
- 检测到满条件时 `s_rdy` 取消断言
- 写暂停输入 `write_stall` 阻塞正常写入（但在自动清零模式下允许气泡）
- 上游必须遵守就绪信号，在 `s_rdy` 为低时不写入

**读侧：**
- 检测到空条件时 `m_vld` 取消断言
- `m_rdy` 背压通过停止指针推进来遵守
- 读暂停输入 `read_stall` 屏蔽输出数据（但在自动清零模式下允许内部读取）

#### 5.2.2 基于阈值的流控

当 `THRESHOLD_EN = 1` 时：

**Almost Full（写侧）：**
- 跟踪条目计数：写时递增，同步读递增时递减
- 当 `entry_count >= ALMOST_FULL_THRESHOLD` 时断言
- 向上游提供早期警告以节流写入
- 对于防止流水线系统溢出很有用

**Almost Empty（读侧）：**
- 跟踪条目计数：同步写递增时递增，读时递减
- 当 `entry_count <= ALMOST_EMPTY_THRESHOLD` 时断言
- 向下游提供早期警告以准备数据饥饿
- 对于维持流水线效率很有用

### 5.3 复位和清除行为

#### 5.3.1 异步复位

**写域复位（wrst_n）：**
- 复位所有写侧寄存器
- 指针复位到初始状态
- 满标志清除
- 同步器级清除

**读域复位（rrst_n）：**
- 复位所有读侧寄存器
- 指针复位到初始状态
- 空标志置位
- 同步器级清除

**复位后状态：**
- FIFO显示为空（安全起始状态）
- 写侧准备接收数据
- 读侧指示无可用数据

#### 5.3.2 同步清除

**写清除（write_clear）：**
- 在wclk上升沿同步复位写指针
- 不影响FIFO中已有数据
- 使用场景：刷新写侧，丢弃待写入数据

**读清除（read_clear）：**
- 在rclk上升沿同步复位读指针
- 有效丢弃FIFO中的所有数据
- 使用场景：刷新读侧，跳到最新数据

#### 5.3.3 暂停行为

**写暂停（write_stall）：**
- 在自动清零模式下阻塞正常数据写入
- 允许气泡生成继续
- 正常数据的写指针不推进
- 使用场景：临时暂停数据流同时维持自动清零

**读暂停（read_stall）：**
- 在自动清零模式下屏蔽输出数据
- 允许内部读取（气泡消耗）继续
- 即使数据可用，`m_vld` 也取消断言
- 使用场景：临时暂停输出同时维持自动清零

### 5.4 特殊场景

#### 5.4.1 同时读写

- 同时读写时维持FIFO深度
- 指针在各自时钟域中独立推进
- 无冲突：写通过 `wptr_sync` 选择，读通过 `rptr_sync` 选择
- 满/空条件基于同步指针更新

#### 5.4.2 时钟频率不匹配

**快写慢读：**
- FIFO快速填满
- 满指示断言，应用背压
- 写入方必须基于 `s_rdy` 节流

**慢写快读：**
- FIFO快速排空
- 空指示断言
- 读取方看到无效的 `m_vld` 直到新数据到达

**最佳平衡：**
- FIFO深度应适应最坏情况突发和时钟比率
- 阈值指示器提供早期警告

#### 5.4.3 单条目操作

- FIFO可以以小至2的FIFO_DEPTH运行（CDC安全的最小值）
- 单条目场景：写入后立即读取
- CDC同步延迟意味着满/空不会立即更新
- 设计保证尽管有同步延迟也不会溢出/下溢

## 6. 验证策略

### 6.1 验证目标

#### 6.1.1 主要目标

- **功能正确性**：验证所有条件下通过FIFO的数据完整性
- **CDC安全性**：确保时钟边界无亚稳态传播或数据损坏
- **协议合规性**：验证valid-ready握手遵守情况
- **边角情况覆盖**：测试边界条件和错误场景
- **参数覆盖**：验证所有参数组合
- **性能**：验证吞吐量和延迟符合规范

#### 6.1.2 覆盖率目标

- 代码覆盖率：>95% 语句、分支、表达式覆盖率
- 功能覆盖率：已定义覆盖点的100%
- 交叉覆盖率：所有相关参数和场景组合
- 断言覆盖率：所有SVA断言被执行

### 6.2 测试平台架构

#### 6.2.1 推荐的测试平台结构

```
TB Top
├── 时钟生成器（wclk、rclk，可配置频率/相位）
├── 复位生成器（独立wrst_n、rrst_n控制）
├── 写侧驱动器（BFM）
│   ├── 可配置流量模式生成器
│   ├── Valid-ready协议驱动器
│   └── 参考模型（记分板输入）
├── 读侧监控器（BFM）
│   ├── Valid-ready协议监控器
│   ├── 数据捕获
│   └── 参考模型（记分板输出）
├── 记分板
│   ├── FIFO参考模型
│   ├── 数据比较
│   └── 协议检查
├── 覆盖率收集器
│   ├── 功能覆盖率
│   └── 代码覆盖率
└── DUT（fcip_afifo）
```

#### 6.2.2 接口代理

**写代理：**
- 生成可配置有效率的随机数据
- 支持突发和稀疏流量模式
- 协议检查：验证 `s_rdy` 被遵守
- 随机间隔注入stall和clear

**读代理：**
- 通过 `m_rdy` 应用可配置背压
- 监控输出数据和时序
- 协议检查：验证 `m_vld` 断言时数据稳定
- 随机间隔注入stall和clear

### 6.3 测试计划

#### 6.3.1 功能测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|---------|-----------|-------------|---------------------|
| FT001 | 基本写读 | 写单个条目，读单个条目 | 数据匹配，指针正确 |
| FT002 | 满FIFO写 | 写到满，验证背压 | s_rdy取消断言，无溢出 |
| FT003 | 空FIFO读 | 尝试从空FIFO读取 | m_vld取消断言，无下溢 |
| FT004 | 连续流 | 持续写和读操作 | 无数据丢失，正确顺序 |
| FT005 | 突发写 | 连续写FIFO_DEPTH个条目 | 所有数据正确存储 |
| FT006 | 突发读 | 连续读FIFO_DEPTH个条目 | 所有数据正确检索 |
| FT007 | 随机流量 | 变化速率的随机写/读 | 维持数据完整性 |
| FT008 | Almost Full | 填充到阈值，验证标志 | almost_full在正确计数断言 |
| FT009 | Almost Empty | 排空到阈值，验证标志 | almost_empty在正确计数断言 |
| FT010 | 写暂停 | 操作期间断言write_stall | 正常写入被阻塞 |
| FT011 | 读暂停 | 操作期间断言read_stall | 输出被屏蔽（自动清零模式） |
| FT012 | 写清除 | FIFO有数据时断言write_clear | 写指针复位 |
| FT013 | 读清除 | FIFO有数据时断言read_clear | 读指针复位，数据丢弃 |
| FT014 | 启用自动清零 | 启用AUTO_CLEAR_EN，验证恢复 | 指针返回零，full_zero断言 |
| FT015 | 气泡过滤 | 验证自动清零中气泡不输出 | 仅在m_pld上输出有效数据 |
| FT016 | 全零状态 | 验证两个域中的full_zero | 清除/自动清零后正确断言 |
| FT017 | 空闲状态 | 空时验证read_idle | 无可用数据时断言 |

#### 6.3.2 跨时钟域测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|---------|-----------|-------------|---------------------|
| CDC001 | 快写慢读 | wclk >> rclk | 数据完整性，无溢出 |
| CDC002 | 慢写快读 | wclk << rclk | 数据完整性，无下溢 |
| CDC003 | 等频时钟 | wclk = rclk | 正确操作，数据完整性 |
| CDC004 | 时钟相位扫描 | 变化相对相位0-360° | 任何相位下无时序违规 |
| CDC005 | 时钟频率比 | 测试比率1:10, 1:5, 1:2, 2:1, 5:1, 10:1 | 所有比率下正确操作 |
| CDC006 | 时钟抖动 | 向两个时钟添加随机抖动 | 无数据损坏 |
| CDC007 | 时钟停启 | 随机停止时钟，重启 | 无数据丢失的恢复 |
| CDC008 | 同时写/读 | 边界处写和读 | 指针正确更新 |
| CDC009 | 亚稳态注入 | 强制同步器输入为X | X不传播到同步级之外 |
| CDC010 | 同步级变化 | 测试SYNC_STAGE = 2和3 | 两种配置都正确运行 |

#### 6.3.3 边角情况测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|---------|-----------|-------------|---------------------|
| CC001 | 最小深度 | FIFO_DEPTH = 2 | 最小尺寸下正确操作 |
| CC002 | 最大深度 | FIFO_DEPTH = 256或更大 | 大尺寸下正确操作 |
| CC003 | 最小数据宽度 | DATA_WIDTH = 1 | 单位数据正确处理 |
| CC004 | 最大数据宽度 | DATA_WIDTH = 512或更大 | 宽数据正确处理 |
| CC005 | 满边界写 | 转换到满时写入 | 无溢出，正确满检测 |
| CC006 | 空边界读 | 转换到空时读取 | 无下溢，正确空检测 |
| CC007 | 指针回卷 | 多次填充和排空 | 指针正确回卷，无损坏 |
| CC008 | 并发复位 | 同时断言wrst_n和rrst_n | 干净复位，无残留状态 |
| CC009 | 异步复位 | 在随机时钟相位断言复位 | 无论时序如何都正确复位 |
| CC010 | 交替单条目 | 写1，读1，重复 | 高转换率下正确操作 |
| CC011 | 阈值边界 | 恰好在阈值处填充/排空 | 标志正确断言/取消断言 |
| CC012 | 自动清零空闲 | 启用自动清零，无流量 | 指针恢复到零 |
| CC013 | 自动清零有流量 | 启用自动清零，零星写入 | 间隙期间插入气泡 |
| CC014 | 满/空时暂停 | 在边界处暂停 | 无意外状态变化 |

#### 6.3.4 参数扫描测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|---------|-----------|-------------|---------------------|
| PS001 | 深度扫描 | 测试FIFO_DEPTH = 2, 4, 8, 16, 32, 64, 128, 256 | 所有深度正确运行 |
| PS002 | 数据宽度扫描 | 测试DATA_WIDTH = 1, 8, 16, 32, 64, 128, 256 | 所有宽度正确运行 |
| PS003 | 同步级扫描 | 测试SYNC_STAGE = 2, 3 | 两种同步深度都工作 |
| PS004 | VT类型扫描 | 测试VT_TYPE = 0到5 | 所有单元类型正确综合 |
| PS005 | 阈值值扫描 | 变化阈值从1到FIFO_DEPTH-1 | 正确阈值行为 |
| PS006 | 自动清零切换 | 测试AUTO_CLEAR_EN = 0和1 | 两种模式正确运行 |
| PS007 | 阈值启用切换 | 测试THRESHOLD_EN = 0和1 | 阈值正确禁用/启用 |

#### 6.3.5 协议和断言测试

| 测试ID | 测试名称 | 描述 | 通过标准 |
|---------|-----------|-------------|---------------------|
| PA001 | 写协议违规 | 驱动s_vld同时改变s_pld | 断言触发 |
| PA002 | 读协议违规 | 不遵守m_vld改变m_rdy | 如果无效则断言触发 |
| PA003 | X传播 | 在数据路径注入X | 断言检测到X |
| PA004 | 满空互斥 | 验证从不同时满和空 | 断言通过 |
| PA005 | 指针一致性 | 验证指针在有效范围内 | 断言通过 |
| PA006 | 数据稳定性 | 验证有效期间数据稳定 | 断言通过 |

### 6.4 覆盖率计划

#### 6.4.1 功能覆盖率定义

**覆盖组：FIFO状态**
```systemverilog
covergroup cg_fifo_status @(posedge wclk);
    cp_full: coverpoint full;
    cp_empty: coverpoint empty;
    cp_almost_full: coverpoint almost_full;
    cp_almost_empty: coverpoint almost_empty;
    cross cp_full, cp_empty; // 不应同时为真
endgroup
```

**覆盖组：FIFO操作**
```systemverilog
covergroup cg_operations;
    cp_write: coverpoint write_event;
    cp_read: coverpoint read_event;
    cp_simultaneous: cross cp_write, cp_read;
endgroup
```

**覆盖组：指针状态**
```systemverilog
covergroup cg_pointers;
    cp_wptr_position: coverpoint wptr_sync {
        bins positions[] = {[0:FIFO_DEPTH-1]};
    }
    cp_rptr_position: coverpoint rptr_sync {
        bins positions[] = {[0:FIFO_DEPTH-1]};
    }
    cp_wraparound_w: coverpoint wptr_wraparound;
    cp_wraparound_r: coverpoint rptr_wraparound;
endgroup
```

**覆盖组：自动清零**
```systemverilog
covergroup cg_autoclear @(posedge wclk);
    cp_bubble_inject: coverpoint bubble_req_vld && bubble_gen_rdy;
    cp_bubble_filtered: coverpoint bubble_detected && !m_vld;
    cp_full_zero_w: coverpoint write_full_zero;
    cp_full_zero_r: coverpoint read_full_zero;
endgroup
```

**覆盖组：时钟频率**
```systemverilog
covergroup cg_clock_ratio;
    cp_wclk_freq: coverpoint wclk_freq {
        bins low = {[1:10]};
        bins med = {[11:100]};
        bins high = {[101:1000]};
    }
    cp_rclk_freq: coverpoint rclk_freq {
        bins low = {[1:10]};
        bins med = {[11:100]};
        bins high = {[101:1000]};
    }
    cross cp_wclk_freq, cp_rclk_freq;
endgroup
```

#### 6.4.2 断言计划

**指针一致性断言：**
```systemverilog
// 写指针独热检查
property p_wptr_onehot;
    @(posedge wclk) disable iff (!wrst_n)
    $onehot(wptr_sync);
endproperty
assert_wptr_onehot: assert property(p_wptr_onehot);

// 读指针独热检查
property p_rptr_onehot;
    @(posedge rclk) disable iff (!rrst_n)
    $onehot(rptr_sync);
endproperty
assert_rptr_onehot: assert property(p_rptr_onehot);
```

**协议断言：**
```systemverilog
// 有效期间写数据稳定性
property p_write_data_stable;
    @(posedge wclk) disable iff (!wrst_n)
    s_vld && !s_rdy |=> $stable(s_pld);
endproperty
assert_write_data_stable: assert property(p_write_data_stable);

// 有效期间读数据稳定性
property p_read_data_stable;
    @(posedge rclk) disable iff (!rrst_n)
    m_vld && !m_rdy |=> $stable(m_pld);
endproperty
assert_read_data_stable: assert property(p_read_data_stable);
```

**满/空断言：**
```systemverilog
// 从不同时满和空
property p_not_full_and_empty;
    @(posedge wclk) disable iff (!wrst_n)
    !(full && empty);
endproperty
assert_not_full_and_empty: assert property(p_not_full_and_empty);

// 满意味着不写
property p_full_no_write;
    @(posedge wclk) disable iff (!wrst_n)
    full |-> !s_rdy;
endproperty
assert_full_no_write: assert property(p_full_no_write);

// 空意味着不读
property p_empty_no_read;
    @(posedge rclk) disable iff (!rrst_n)
    empty |-> !m_vld;
endproperty
assert_empty_no_read: assert property(p_empty_no_read);
```

**CDC安全断言：**
```systemverilog
// 同步器后无X传播
property p_no_x_after_sync;
    @(posedge rclk) disable iff (!rrst_n)
    !$isunknown(rq2_wptr_sync1);
endproperty
assert_no_x_after_sync: assert property(p_no_x_after_sync);
```

### 6.5 回归策略

#### 6.5.1 冒烟测试（快速回归）

- 持续时间：< 5分钟
- 测试：FT001-FT006（基本功能）
- 运行频率：每次提交
- 目的：快速健全性检查

#### 6.5.2 每夜回归

- 持续时间：2-4小时
- 测试：所有FT、CDC001-CDC005、CC001-CC010、PS001-PS003
- 运行频率：每日
- 目的：全面功能覆盖

#### 6.5.3 每周回归

- 持续时间：24+小时
- 测试：所有测试类别，扩展种子
- 运行频率：每周
- 目的：完整覆盖率闭合，长时间运行场景

#### 6.5.4 发布回归

- 持续时间：多日
- 测试：所有测试，多个随机种子，详尽参数扫描
- 运行频率：发布前
- 目的：签核级验证

### 6.6 调试和分析

#### 6.6.1 波形分析

**监控关键信号：**
- 时钟和复位信号：`wclk`、`rclk`、`wrst_n`、`rrst_n`
- 写接口：`s_vld`、`s_rdy`、`s_pld`
- 读接口：`m_vld`、`m_rdy`、`m_pld`
- 指针：`wptr_sync`、`wptr_async`、`rptr_sync`、`rptr_async`
- 状态标志：`full`、`empty`、`almost_full`、`almost_empty`、`full_zero`
- CDC信号：同步指针、数据路径
- 自动清零：气泡注入、气泡过滤

#### 6.6.2 调试检查清单

**数据损坏：**
1. 检查写/读指针值
2. 验证寄存器阵列内容
3. 检查CDC同步器输出是否有X
4. 验证时钟关系（频率、相位）
5. 检查波形中的建立/保持违规

**协议违规：**
1. 检查握手时序（valid-ready）
2. 验证有效期间数据稳定性
3. 检查意外的满/空转换
4. 验证指针推进时序

**性能问题：**
1. 检查意外的停顿
2. 验证时钟频率符合要求
3. 检查阈值设置
4. 分析随时间的FIFO占用率

## 7. 设计约束和限制

### 7.1 参数约束

| 参数 | 约束 | 理由 |
|-----------|-----------|-----------|
| FIFO_DEPTH | 必须 ≥ 2 | CDC安全的最小深度 |
| FIFO_DEPTH | 应为2的幂 | 简化指针逻辑 |
| DATA_WIDTH | 必须 ≥ 1 | 最小数据宽度 |
| SYNC_STAGE | 必须为2或3 | 平衡CDC安全性与延迟 |
| ALMOST_FULL_THRESHOLD | 必须 < FIFO_DEPTH | 逻辑约束 |
| ALMOST_EMPTY_THRESHOLD | 必须 < FIFO_DEPTH | 逻辑约束 |
| AUTO_CLEAR_EN | 仅0或1 | 二进制功能启用 |
| THRESHOLD_EN | 仅0或1 | 二进制功能启用 |
| VT_TYPE | 0-5 | 支持的单元库类型 |

### 7.2 操作约束

**时钟域：**
- 无最大时钟频率比（设计与比率无关）
- 为获得最佳吞吐量，最小FIFO深度随时钟频率比增加而增加
- 时钟占空比应合理平衡（40%-60%）

**复位：**
- 异步复位撤销应与各自时钟同步
- 避免在CDC边界同时断言/撤销两个域复位

**协议：**
- 必须严格遵循valid-ready握手
- 数据必须在有效断言期间保持稳定直到握手

### 7.3 综合约束

**面积：**
- 寄存器阵列增长为FIFO_DEPTH × (DATA_WIDTH + 1)
- 独热编码相比二进制指针增加寄存器计数
- 自动清零模式增加固定仲裁器开销

**时序：**
- 关键路径通常在满/空检测逻辑中
- 数据多路复用器深度随FIFO_DEPTH增加
- CDC标记插入可能增加路径延迟

**功耗：**
- 独热指针减少大多数位的翻转
- 自动清零模式增加功耗（连续气泡生成）
- VT_TYPE选择影响泄漏与性能权衡

## 8. 附录

### 8.1 缩写词和简称

| 术语 | 定义 |
|------|------------|
| CDC | 跨时钟域（Clock Domain Crossing） |
| FIFO | 先进先出（First-In-First-Out） |
| MSB | 最高有效位（Most Significant Bit） |
| LSB | 最低有效位（Least Significant Bit） |
| BFM | 总线功能模型（Bus Functional Model） |
| SVA | SystemVerilog断言（SystemVerilog Assertions） |
| SDC | Synopsys设计约束（Synopsys Design Constraints） |
| VT | 电压阈值（Voltage Threshold） |
| SVT | 标准电压阈值（Standard Voltage Threshold） |
| LVT | 低电压阈值（Low Voltage Threshold） |
| ULVT | 超低电压阈值（Ultra-Low Voltage Threshold） |
| ELVT | 极低电压阈值（Extremely Low Voltage Threshold） |
| LVTLL | 低泄漏低电压阈值（Low Voltage Threshold Low Leakage） |
| ULVTLL | 低泄漏超低电压阈值（Ultra-Low Voltage Threshold Low Leakage） |

### 8.2 参考文档

- IEEE 1800-2017 SystemVerilog语言参考手册
- Clock Domain Crossing (CDC) Design & Verification Techniques Using SystemVerilog (Clifford E. Cummings)
- Simulation and Synthesis Techniques for Asynchronous FIFO Design (Clifford E. Cummings)

### 8.3 修订历史

| 版本 | 日期 | 作者 | 描述 |
|---------|------|--------|-------------|
| 1.0 | 2026-02-03 | jiaoyadi | 初始设计规范发布 |

---

**文档结束**
