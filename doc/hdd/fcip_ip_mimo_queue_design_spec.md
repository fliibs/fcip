# FCIP MIMO Queue Design Specification

## 1. 概述

`fcip_ip_mimo_queue` 是一个基于寄存器阵列实现的多入多出 FIFO 队列。模块允许多个写端口和多个读端口在同一拍内并行工作，通过 credit 计数、顺序地址分配和逐 entry 写入映射，完成多端口并发入队和出队。

RTL 文件位于 `ip/basic/fcip_ip_mimo_queue.sv`

- 用 `queue_entry[DEPTH-1:0]` 直接保存所有条目。
- 用 `wr_ptr` / `rd_ptr` 跟踪逻辑队头和队尾。
- 用 `crdt_cnt` 记录当前已占用深度。
- 用端口累计计数决定本拍实际写入/读出个数。
- 用按 entry 展开的写入映射网络把多个写端口分发到具体存储单元。

## 2. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| DEPTH | int unsigned | 128 | 队列深度 |
| WR_WIDTH | int unsigned | 4 | 写端口数量 |
| RD_WIDTH | int unsigned | 4 | 读端口数量 |
| PLD_TYPE | type | logic | 队列条目数据类型，支持 struct |

### 2.1 内部参数

| 参数名 | 计算公式 | 描述 |
|--------|----------|------|
| CRDT_CNT_WIDTH | `$clog2(DEPTH)+1` | 已占用条目计数位宽 |
| DEPTH_WIDTH | `$clog2(DEPTH)` | 存储索引位宽 |
| WRITE_NUM_WIDTH | `$clog2(WR_WIDTH)+1` | 单拍写入数量位宽 |
| READ_NUM_WIDTH | `$clog2(RD_WIDTH)+1` | 单拍读出数量位宽 |
| PTR_WIDTH | `$clog2(DEPTH)+1` | 读写指针位宽，包含回绕位 |

## 3. 接口定义

### 3.1 写请求通道

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| v_req_rdy | output | WR_WIDTH | 每个写端口是否可接受 |
| v_req_vld | input | WR_WIDTH | 每个写端口请求是否有效 |
| v_req_pld | input | WR_WIDTH x PLD_TYPE | 每个写端口写入数据 |

### 3.2 读应答通道

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| v_ack_vld | output | RD_WIDTH | 每个读端口是否有有效数据 |
| v_ack_rdy | input | RD_WIDTH | 每个读端口是否接受数据 |
| v_ack_pld | output | RD_WIDTH x PLD_TYPE | 每个读端口当前读取的数据 |

## 4. 设计思想

模块把一个逻辑 FIFO 展开成以下 4 个相互配合的子系统：

1. 容量管理：通过 `crdt_cnt` 和 `crdt_residue` 判断还可以接收多少写请求。
2. 顺序分配：通过 `wr_ptr + port_index` 与 `rd_ptr + port_index` 给多端口分配逻辑地址。
3. 累计计数：通过前缀和统计本拍真实写入数与读出数。
4. entry 映射：把各写端口数据路由到具体的 `queue_entry[i]`。

这种实现的关键优势是控制路径清晰，且天然支持任意 `PLD_TYPE`；代价是写路径组合逻辑规模与 `DEPTH x WR_WIDTH` 成正比。

## 5. 内部连接关系

### 5.1 顶层连接图

```text
                     +---------------- credit counter ----------------+
                     |                                                |
v_req_vld ------>+--> write acceptance --> v_write_num_acc -------+----+
v_req_pld ------>+                                                |    |
                     |                                                |    v
                     |                                            wr_ptr update
                     |                                                |
                     |                                                v
                     |                               +-----------------------------+
                     |                               | write remap by queue entry   |
                     |                               | wr_entry_en_map[i]           |
                     |                               | wr_entry_data_map[i]         |
                     |                               +-----------------------------+
                     |                                                |
                     |                                                v
                     |                                         queue_entry[0:DEPTH-1]
                     |                                                ^
                     |                                                |
v_ack_rdy ------>+--> read acceptance --> v_read_num_acc ---------+----+
                                                                                  |    |
                                                                                  |    v
                                                                             rd_ptr update
                                                                                  |
                                                                                  v
                                                                         v_ack_pld / v_ack_vld
```

### 5.2 存储阵列连接

每个 `queue_entry[i]` 都有一组独立的写使能和写数据：

- `wr_entry_en_map[i]` 表示第 `i` 个 entry 本拍是否被写。
- `wr_entry_data_map[i]` 表示写入该 entry 的 payload。

模块通过双重循环检查“哪个写端口的目标地址等于当前 entry 编号”，从而完成路由。

### 5.3 读路径连接

每个读端口 `i` 直接读取：

```text
v_ack_pld[i] = queue_entry[(rd_ptr + i) mod DEPTH]
```

因此读数据始终按逻辑队头开始连续展开。`v_ack_vld[i]` 决定这个端口上的数据当前是否有效。

## 6. 握手与容量控制

## 6.1 写侧 ready 生成

剩余容量：

```text
crdt_residue = DEPTH - crdt_cnt
```

第 `i` 个写端口的就绪条件：

```text
v_req_rdy[i] = (crdt_residue >= i + 1)
```

这意味着：

- 端口编号越小，越容易被接受。
- 如果当前只剩 2 个空位，则只允许端口 0 和 1 写入。
- 即使端口 3 单独有效，只要空位不足 4，它也不会越过低编号端口单独占用资源。

这是一种基于端口编号的静态优先策略。

## 6.2 读侧 valid 生成

第 `i` 个读端口的有效条件：

```text
v_ack_vld[i] = (crdt_cnt > i)
```

含义是：

- 当队列中至少有 1 个条目时，端口 0 有效。
- 至少有 2 个条目时，端口 1 也有效。
- 依此类推，读端口自然按 FIFO 顺序展开。

## 6.3 本拍读写使能

- `wren = |(v_req_rdy & v_req_vld)`
- `rden = |(v_ack_rdy & v_ack_vld)`

其中：

- `wren` 表示本拍至少发生一次真实写入。
- `rden` 表示本拍至少发生一次真实读出。

## 7. 单拍累计计数实现

## 7.1 写入数量累计

`v_write_num_acc[i]` 表示从端口 0 到端口 `i` 为止实际被接受的写入数。

例如 `WR_WIDTH=4` 时：

```text
v_req_vld = 4'b1101
v_req_rdy = 4'b1111

端口0: accepted -> acc[0] = 1
端口1: not valid -> acc[1] = 1
端口2: accepted -> acc[2] = 2
端口3: accepted -> acc[3] = 3
```

因此本拍总写入数为 `v_write_num_acc[WR_WIDTH-1] = 3`。

## 7.2 读出数量累计

`v_read_num_acc[i]` 的定义完全对称，表示从端口 0 到端口 `i` 为止真实完成握手的读出数。

例如：

```text
v_ack_vld = 4'b1110
v_ack_rdy = 4'b1010

端口1: 握手成功
端口3: 握手成功
则总读出数 = 2
```

累计计数用于两个地方：

1. 更新 credit 计数。
2. 更新读写指针。

## 8. credit 计数器实现

RTL 中：

- `crdt_add = total_write_num & {WRITE_NUM_WIDTH{wren}}`
- `crdt_sub = total_read_num  & {READ_NUM_WIDTH{rden}}`
- `crdt_cal = crdt_add - crdt_sub`
- `crdt_cnt <= crdt_cnt + crdt_cal`

因此 `crdt_cnt` 始终表示“当前队列中已占用条目数”。

### 8.1 同拍读写

如果某拍同时发生多写多读，则：

```text
crdt_cnt(next) = crdt_cnt + 写入数 - 读出数
```

这保证在 steady state 下可以一边消费旧数据，一边写入新数据。

### 8.2 为什么不会越界

不会上溢：

- 写侧 `v_req_rdy` 已提前用 `crdt_residue` 限制可接受写数。

不会下溢：

- 读侧 `v_ack_vld` 已根据 `crdt_cnt` 限制可见读数。

## 9. 读写指针实现

## 9.1 指针定义

- `wr_ptr`：下一次写入的起始逻辑地址。
- `rd_ptr`：下一次读出的起始逻辑地址。

两者位宽都是 `PTR_WIDTH = $clog2(DEPTH)+1`，比地址索引多 1 位，用于区分回绕前后阶段。

真正访问 `queue_entry` 时只使用低 `DEPTH_WIDTH` 位：

```text
phy_addr = ptr[DEPTH_WIDTH-1:0]
```

## 9.2 写地址分配

第 `i` 个写端口的目标地址：

```text
v_wr_add_ptr[i] = wr_ptr + i
```

注意这里用的是端口索引 `i`，不是“之前已有多少端口成功写入”。这要求上游必须按端口编号提供一个自然顺序的写队列，而实际是否写入仍由 `v_req_vld[i] && v_req_rdy[i]` 决定。

## 9.3 读地址分配

第 `i` 个读端口的读取地址：

```text
v_rd_add_ptr[i] = rd_ptr + i
```

所以读端口天然输出连续条目：队头、队头+1、队头+2。

## 9.4 指针更新

- 若 `wren=1`，`wr_ptr += total_write_num`
- 若 `rden=1`，`rd_ptr += total_read_num`

因此指针增量总是等于本拍真实传输数，而不是端口总宽度。

## 10. 写入映射电路详解

这是本模块最核心的内部电路。

### 10.1 目标

把多写端口请求：

```text
{v_req_vld[j], v_req_rdy[j], v_req_pld[j], v_wr_add_ptr[j]}
```

转换为每个存储条目的：

```text
{wr_entry_en_map[i], wr_entry_data_map[i]}
```

### 10.2 实现方式

RTL 对每个 entry `i` 扫描所有写端口 `j`：

```text
if (v_req_rdy[j] && v_req_vld[j] && v_wr_add_ptr[j][DEPTH_WIDTH-1:0] == i)
```

若命中：

- `wr_entry_en_map[i] = 1`
- `wr_entry_data_map[i] |= v_req_pld[j]`

### 10.3 为什么可以用 OR 合并

正常工作时，不会有两个不同写端口命中同一个 entry，因为：

- `v_wr_add_ptr[j] = wr_ptr + j`
- 各 `j` 不同，故低位地址在同一拍内也不同，除非参数配置不合法或地址空间异常回绕

所以这里的 OR 合并本质上是“默认单一命中”的安全写法，而不是允许多源真实相加。

### 10.4 queue_entry 写入

每个 entry 各有一个独立的 `always_ff`：

```text
if (wr_entry_en_map[i])
     queue_entry[i] <= wr_entry_data_map[i]
```

这说明整个队列实现是 fully-unrolled register array。

## 11. 读出通路详解

读出通路比写入简单很多：

1. 对每个读端口计算 `rd_ptr + i`。
2. 直接索引到对应的 `queue_entry`。
3. 用 `v_ack_vld[i]` 表示该数据是否有效。

这是“读数据提前给出，valid 指示其是否可用”的实现风格。只要消费者遵循 `valid-ready` 协议，就不会误用无效数据。

## 12. 时序示意

## 12.1 单写单读基本时序

```text
clk      : ┌─┐ ┌─┐ ┌─┐ ┌─┐
             └─┘ └─┘ └─┘ └─┘
v_req_vld0: 0───1──────────0
v_req_rdy0: 1───1──────────1
write      : ---- W0 ---------
crdt_cnt   : 0───1──────────0
v_ack_vld0 : 0──────1────────0
v_ack_rdy0 : 0──────1────────0
v_ack_pld0 : ----- D0 --------

说明:
1. 第1次握手把 D0 写入队列。
2. 后续当 `crdt_cnt>0` 时，读口0看到有效数据。
3. 读握手完成后 `crdt_cnt` 回到0。
```

## 12.2 多端口并行写入时序

```text
clk       : ┌─┐ ┌─┐ ┌─┐
               └─┘ └─┘ └─┘
crdt_res  : 4────4────1
v_req_vld : [1,1,1,0]
v_req_rdy : [1,1,1,1]
wr_ptr    : 0────3────3
写入地址   : 0,1,2
queue_entry: Q0=D0 Q1=D1 Q2=D2

说明:
1. 同一拍 3 个写端口同时写入连续地址。
2. `wr_ptr` 下一拍整体加3，而不是逐端口多次更新。
```

## 12.3 并行读写同时发生

```text
clk       : ┌─┐ ┌─┐ ┌─┐
               └─┘ └─┘ └─┘
crdt_cnt  : 3────3────3
写入数     : 2
读出数     : 2
wr_ptr    : 5────7
rd_ptr    : 2────4

说明:
1. 同拍写2读2时，`crdt_cnt` 净变化为0。
2. 队列容量保持不变，但队头队尾同时前移。
```

## 12.4 指针回绕示意

```text
DEPTH = 8
wr_ptr = 7, total_write_num = 2

本拍写地址: 7, 0
下一拍 wr_ptr = 9
访问物理地址时仅取低3位，因此自动回绕。
```

## 13. 使用示例

## 13.1 32位双写双读队列

```systemverilog
fcip_ip_mimo_queue #(
     .DEPTH   (16),
     .WR_WIDTH(2),
     .RD_WIDTH(2),
     .PLD_TYPE(logic [31:0])
) u_mimo_q (
     .clk      (clk),
     .rst_n    (rst_n),
     .v_req_rdy(v_req_rdy),
     .v_req_vld(v_req_vld),
     .v_req_pld(v_req_pld),
     .v_ack_vld(v_ack_vld),
     .v_ack_rdy(v_ack_rdy),
     .v_ack_pld(v_ack_pld)
);
```

使用场景：两个生产者并行入队，两个消费者并行出队，且要求严格保持全局 FIFO 顺序。

## 13.2 结构体 payload 示例

```systemverilog
typedef struct packed {
     logic [7:0]  id;
     logic [31:0] addr;
     logic [63:0] data;
} req_t;

fcip_ip_mimo_queue #(
     .DEPTH   (32),
     .WR_WIDTH(4),
     .RD_WIDTH(2),
     .PLD_TYPE(req_t)
) u_req_queue (...);
```

由于实现基于 `PLD_TYPE` 泛型和寄存器阵列，不需要额外拆字段即可直接缓存结构体数据。

## 13.3 行为示例

假设：

```text
DEPTH = 8
当前 wr_ptr = 3, rd_ptr = 1, crdt_cnt = 4
本拍 v_req_vld = [1,0,1,0]
本拍 v_ack_rdy = [1,1,0,0]
```

则：

- 写入端口0命中地址3，写入端口2命中地址5。
- 读端口0读取地址1，读端口1读取地址2。
- 本拍总写入数 = 2，总读出数 = 2。
- 下一拍 `wr_ptr=5`，`rd_ptr=3`，`crdt_cnt` 保持 4。

## 14. 实现约束与注意事项

- 写侧 acceptance 是按端口编号递增开放的，天然带低编号优先级。
- 读侧 `v_ack_pld` 始终组合连到 `queue_entry`，消费者必须以 `v_ack_vld` 为准采样。
- 存储体是寄存器阵列，深度和写端口数过大时组合面积与时序压力会上升。
- `DEPTH` 非 2 的幂时，低位取址仍可工作，但应特别关注指针截位后的地址覆盖行为与综合实现质量。

## 15. 验证关键点与测试用例

| TC | 场景 | 预期 |
|----|------|------|
| 001 | 单写单读 | 基本 FIFO 正确 |
| 002 | 多端口同时写入 | 所有被接受端口数据写入连续地址 |
| 003 | 多端口同时读出 | 按逻辑队头顺序连续读出 |
| 004 | 满队列时写入 | `v_req_rdy` 全 0 |
| 005 | 空队列时读出 | `v_ack_vld` 全 0 |
| 006 | 剩余容量边界 | 仅低编号若干写端口 ready |
| 007 | 部分端口 valid 空洞 | 地址分配仍按固定端口偏移，指针只按真实数量前进 |
| 008 | 指针回绕 | `wr_ptr`、`rd_ptr` 回绕后数据次序仍正确 |
| 009 | 同拍满带宽读写 | `crdt_cnt` 按净变化更新 |
| 010 | 自定义 `PLD_TYPE` | struct 数据字段完整保持 |
