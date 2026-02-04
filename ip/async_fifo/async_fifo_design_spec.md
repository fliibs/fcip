# Async FIFO 设计规格书（Design Specification）

## 1. 概述

本文档描述异步 FIFO（Asynchronous FIFO）模块 `fcip_afifo` 及其子模块 `fcip_afifo_slv`（写端/Slave）与 `fcip_afifo_mst`（读端/Master）的设计规格，包括功能、时钟与复位结构、接口定义、内部实现要点、参数化能力，以及验证建议与测试用例规划。

该异步 FIFO 用于在 **写时钟域（wclk）** 与 **读时钟域（rclk）** 之间安全传递数据，支持可选的阈值指示（almost_full/almost_empty）、stall/clear 控制，并在实现层面采用指针 CDC 同步与跨域载荷传递结构。

## 2. 模块组成与层次结构

### 2.1 顶层模块：`fcip_afifo`

`fcip_afifo` 为封装模块，负责：

- 对外提供标准的写入端（s_vld/s_rdy/s_pld）和读出端（m_vld/m_rdy/m_pld）接口。
- 将写域与读域的 reset、stall、clear 信号分别连接至写端/读端子模块。
- 在内部连接写指针、读指针以及载荷跨域通路。

内部例化：

- `fcip_afifo_slv`：工作在 `wclk` 域，负责写入、full 判断、write_full_zero、almost_full 生成。
- `fcip_afifo_mst`：工作在 `rclk` 域，负责读出、empty 判断、read_full_zero/read_idle、almost_empty 生成。

### 2.2 写端模块：`fcip_afifo_slv`

主要职责：

- 产生写域同步指针 `wptr_sync` 以及写域传播到读域用于比较的异步指针 `wptr_async`。
- 对来自读域的 `rptr_async` 进行同步（`fcip_sync_cell`），实现跨域 full 判定。
- 将写入数据存入本地寄存阵列 `mem_array[FIFO_DEPTH]`。
- 通过跨域标记/采样链路将当前读指针位置的数据（含有效位）组合为 `pld_sync` 输出，供读域使用。
- 支持可选阈值 `almost_full`。
- 可选支持 AUTO_CLEAR 的“bubble”注入通路（当前实现中 bubble 注入条件存在，但实际写入端口在 AUTO_CLEAR_EN=0 时为直通）。

### 2.3 读端模块：`fcip_afifo_mst`

主要职责：

- 产生读域同步指针 `rptr_sync` 以及读域传播到写域用于比较的异步指针 `rptr_async`。
- 对来自写域的 `wptr_async` 进行同步（`fcip_sync_cell`），实现跨域 empty 判定。
- 从跨域传入的 `pld_sync`（含有效位）采样得到 `pld_sync_marker`，并通过寄存切片（reg slice）对外输出。
- 支持可选阈值 `almost_empty`。
- 当 `AUTO_CLEAR_EN==1` 时，支持对 bubble（有效位为 0）或 stall 情况进行输出屏蔽。

## 3. 功能描述

### 3.1 数据通路

- 写端在 `wclk` 域接受输入握手：
  - 当 `s_vld==1` 且 FIFO 未 full 且未被 `write_stall` 屏蔽时，写入一次。
  - 写入数据在内部扩展为 `{payload, vld_bit}`，其中 `vld_bit` 固定为 1（正常数据）。
- 读端在 `rclk` 域接受输出握手：
  - 当 FIFO 非 empty 且 `m_rdy==1` 时，读出一次，并更新读指针。
  - 读出路径包含寄存切片，使得 `m_vld` 在一次读握手后可保持，直到 `m_rdy` 消耗。

### 3.2 满/空判定

本实现使用“单热（one-hot）指针/环形指针”形式：

- 写指针 `wptr_sync` 初值为 `...0001`，每次写入循环左移一位。
- 读指针 `rptr_sync` 初值为 `...0001`，每次读出循环左移一位。

跨域比较：

- 写端通过同步后的读域异步指针 `wq2_rptr_sync1` 与本地写指针状态比较，生成 `full`。
- 读端通过同步后的写域异步指针 `rq2_wptr_sync1` 与本地读指针状态比较，生成 `empty`。

该比较逻辑基于位运算形式：

- 写端：`full = |((wptr_async_inner_SIZE_ONLY ^ wq2_rptr_sync1) & wptr_sync)`
- 读端：`empty = ~(|((rptr_async_inner_SIZE_ONLY ^ rq2_wptr_sync1) & rptr_sync_inner_SIZE_ONLY))`

### 3.3 stall/clear 行为

- `write_stall`（写域）：
  - 认为是写端输入侧的节流/停写控制。
  - 当 `write_stall==1` 时，写端将 `s_vld_ext = s_vld && ~stall`，从而抑制写入。

- `read_stall`（读域）：
  - 与输出屏蔽相关。在 `AUTO_CLEAR_EN==1` 时，`read_stall==1` 会导致 `m_vld` 被掩蔽；在 `AUTO_CLEAR_EN==0` 时不影响 `m_vld`，但 `read_idle` 仍由 empty 决定。

- `write_clear` / `read_clear`：
  - 分别作用于写域、读域指针相关寄存器（同步/异步指针内部状态），并影响 full_zero 计算。
  - clear 后指针回到初始位置（同步指针为 one-hot 初值；异步 size-only 指针清 0）。

### 3.4 full_zero / idle 信号

- `write_full_zero`（写域输出）和 `read_full_zero`（读域输出）用于表征理解为「两侧指针均处于初始/空状态」的条件。

写域计算（`fcip_afifo_slv`）：

- `full_zero = (rptr_async 同步值为全 0 或全 1) && (wptr_sync == onehot 初值)`

读域计算（`fcip_afifo_mst`）：

- `full_zero = (wptr_async 同步值为全 0 或全 1) && (rptr_sync 为 onehot 初值)`

- `read_idle`：
  - 直接等价于 `empty`，表示读端空闲（无可读数据）。

## 4. 时钟与复位结构

### 4.1 时钟域

- 写时钟域：`wclk`，对应子模块 `fcip_afifo_slv.clk`。
- 读时钟域：`rclk`，对应子模块 `fcip_afifo_mst.clk`。

子模块内部均使用 `fcip_clk_marker` 生成 `clk_marker`，后续绝大多数时序逻辑在 `posedge clk_marker` 上采样。

### 4.2 复位

- 写域异步复位：`wrst_n`（低有效），传入 `fcip_afifo_slv.rst_n`。
- 读域异步复位：`rrst_n`（低有效），传入 `fcip_afifo_mst.rst_n`。

复位后：

- 同步 one-hot 指针恢复为 `...0001`。
- 用于跨域比较的 “SIZE_ONLY” 指针向量清零。
- 各类寄存切片与阈值计数器清零。

## 5. 接口描述

本节描述 `fcip_afifo` 顶层接口。子模块接口为内部信号连接的展开形式，其语义由顶层接口映射而来。

### 5.1 顶层端口列表（`fcip_afifo`）

#### 5.1.1 时钟与复位

| 端口 | 方向 | 位宽 | 时钟域 | 描述 |
|---|---|---:|---|---|
| `wclk` | in | 1 | 写域 | 写端时钟 |
| `rclk` | in | 1 | 读域 | 读端时钟 |
| `wrst_n` | in | 1 | 写域 | 写端异步低有效复位 |
| `rrst_n` | in | 1 | 读域 | 读端异步低有效复位 |

#### 5.1.2 控制信号

| 端口 | 方向 | 位宽 | 时钟域 | 描述 |
|---|---|---:|---|---|
| `write_stall` | in | 1 | 写域 | 写端停写/节流；为 1 时阻止 s_vld 进入写入路径 |
| `read_stall` | in | 1 | 读域 | 读端停读（主要影响 AUTO_CLEAR_EN==1 时的输出屏蔽） |
| `write_clear` | in | 1 | 写域 | 写端清零，重置写指针相关状态 |
| `read_clear` | in | 1 | 读域 | 读端清零，重置读指针相关状态 |

#### 5.1.3 状态/阈值信号

| 端口 | 方向 | 位宽 | 时钟域 | 描述 |
|---|---|---:|---|---|
| `write_full_zero` | out | 1 | 写域 | 写域侧“空/初始状态”指示 |
| `read_full_zero` | out | 1 | 读域 | 读域侧“空/初始状态”指示 |
| `read_idle` | out | 1 | 读域 | 读端空闲（`empty`） |
| `almost_full` | out | 1 | 写域 | FIFO 将满阈值指示（THRESHOLD_EN=1 时有效） |
| `almost_empty` | out | 1 | 读域 | FIFO 将空阈值指示（THRESHOLD_EN=1 时有效） |

#### 5.1.4 写入端口（Source / S-Port）

| 端口 | 方向 | 位宽 | 时钟域 | 描述 |
|---|---|---:|---|---|
| `s_vld` | in | 1 | 写域 | 写入有效 |
| `s_pld` | in | DATA_WIDTH | 写域 | 写入数据 |
| `s_rdy` | out | 1 | 写域 | 写入就绪；内部等价于 `~full`（且在 AUTO_CLEAR_DISABLE 下直接输出） |

握手规则：当 `s_vld && s_rdy` 时，发生一次写入。

#### 5.1.5 读出端口（Master / M-Port）

| 端口 | 方向 | 位宽 | 时钟域 | 描述 |
|---|---|---:|---|---|
| `m_vld` | out | 1 | 读域 | 读出有效 |
| `m_pld` | out | DATA_WIDTH | 读域 | 读出数据 |
| `m_rdy` | in | 1 | 读域 | 下游就绪 |

握手规则：当 `m_vld && m_rdy` 时，发生一次读出消耗。

## 6. 参数说明

### 6.1 公共参数（顶层透传）

| 参数 | 默认值 | 描述 |
|---|---:|---|
| `FIFO_DEPTH` | 16 | FIFO 深度；当前实现中也被用作指针向量宽度（one-hot 形式） |
| `DATA_WIDTH` | 16 | 数据位宽 |
| `AUTO_CLEAR_EN` | 0 | 自动清空/插入 bubble 支持开关；对读侧输出屏蔽与写侧仲裁结构有影响 |
| `THRESHOLD_EN` | 0（顶层默认） | 阈值统计开关；子模块默认值为 1，但由顶层参数覆盖 |
| `ALMOST_FULL_THRESHOLD` | 12 | almost_full 阈值（写域计数达到/越过该值置位） |
| `ALMOST_EMPTY_THRESHOLD` | 4 | almost_empty 阈值（读域计数达到/低于该值置位） |
| `SYNC_STAGE` | 2 | 指针跨域同步级数（2 或 3）；通过 `fcip_sync_cell` 实现 |
| `VT_TYPE` | 1 | 工艺相关标记参数，透传给 marker/sync cell |

## 7. 内部实现要点

### 7.1 指针形式与存储结构

- 同步指针 `wptr_sync` / `rptr_sync_inner_SIZE_ONLY` 为 one-hot 环形指针。
- 用于跨域比较的异步指针 `wptr_async_inner_SIZE_ONLY` / `rptr_async_inner_SIZE_ONLY` 以“翻转 MSB + 循环移位”的形式产生，用于避免跨域比较时的歧义。
- 写域存储体为寄存数组 `mem_array[FIFO_DEPTH]`，每个 entry 存储 `DATA_WIDTH+1` 位，其中 LSB（bit0）作为有效位。

### 7.2 数据跨域方式

该实现不是传统的“双口 RAM + Gray 指针 + 读写独立寻址”架构，而是：

- 写域持有完整数据阵列。
- 读域通过跨域传入的 `pld_sync`（由 write domain 根据 read pointer marker 选出的 entry）获取数据。

写域用 `rptr_sync_marker`（由 `rptr_sync` 经 marker 处理后得到）选择当前读指针指向的 entry，组合出 `pld_sync_marker`，再经 `fcip_marker` 输出到 `pld_sync`。

读域对 `pld_sync` 进行 marker 化得到 `pld_sync_marker`，并在本域寄存切片中输出。

### 7.3 阈值统计（THRESHOLD_EN）

阈值逻辑基于对跨域同步指针变化的检测，粗略维护“写入次数 - 读出次数”的计数 `ptr_cnt`：

- 写域通过 `rinc_fake = |(wq2_rptr_r ^ wq2_rptr_sync1)` 推断读指针发生变化。
- 读域通过 `winc_fake = |(rq2_wptr_r ^ rq2_wptr_sync1)` 推断写指针发生变化。

当同时发生写入与对端指针变化时计数保持；仅发生写入则加一；仅对端变化则减一。

### 7.4 AUTO_CLEAR_EN 行为

- 写域：当 `AUTO_CLEAR_EN==1` 时，存在 bubble 请求 `bubble_req_vld` 与正常写入输入通过 `fcip_fix_arb` 的固定仲裁。
  - bubble 的 payload 全 0，且有效位为 0。
  - bubble 生成条件为 `bubble_gen_rdy = ~full_zero`。
- 读域：当 `AUTO_CLEAR_EN==1` 时，对 bubble（`~reg_slice_pld_r[0]`）以及 `stall` 情况进行 `m_vld` 屏蔽。

注：当前写域 bubble 插入是否能实现“自动清空”效果依赖系统对 `full_zero` 的定义与对 bubble 的理解方式，建议在验证中重点覆盖。

## 8. 验证建议与 Testcase 规划

本节给出面向功能与 CDC 可靠性的验证建议。建议采用 SystemVerilog/UVM 或轻量级自检 testbench 均可。

### 8.1 基础功能类用例

1. **单写单读（同频）**
   - wclk=rclk，同相位或不同相位。
   - 连续写入 N 笔，连续读出 N 笔，检查顺序一致。

2. **写快读慢/读快写慢（异频）**
   - wclk 频率高于 rclk（例如 2:1）、低于 rclk（1:2）。
   - 验证数据完整性与顺序。

3. **Full/Empty 边界**
   - 填满 FIFO 到 full 状态（s_rdy 拉低），随后读空到 empty 状态（read_idle=1）。
   - 验证 full/empty 切换无毛刺（按本域采样）。

4. **复位行为**
   - 单独复位写域/读域/同时复位。
   - 验证复位后指针、full_zero、idle、阈值输出符合预期。

### 8.2 控制信号类用例

5. **write_stall 拉高**
   - 在持续写入过程中拉高 write_stall，确认写入暂停（s_rdy 行为与 full 关系一致）。
   - 解除 stall 后继续写入，数据不丢失、不重复。

6. **read_stall 拉高**
   - 在持续读出过程中拉高 read_stall。
   - 当 `AUTO_CLEAR_EN==0`：确认仅 m_rdy 侧可控读出节奏，read_stall 不应破坏输出协议。
   - 当 `AUTO_CLEAR_EN==1`：确认 m_vld 被屏蔽，解除后可恢复。

7. **write_clear/read_clear**
   - 在 FIFO 非空状态触发 clear。
   - 检查指针回到初始，full_zero 最终回到 1（在同步完成后）。
   - 触发 clear 后，旧数据是否应视为丢弃需在系统级规格中明确；建议验证中以“清空 FIFO”为语义。

### 8.3 阈值相关用例（THRESHOLD_EN）

8. **almost_full/empty 阈值覆盖**
   - 写到接近满（>=ALMOST_FULL_THRESHOLD）检查 almost_full 置位。
   - 读到接近空（<=ALMOST_EMPTY_THRESHOLD）检查 almost_empty 置位。
   - 覆盖阈值附近的 +1/-1 边界（例如阈值-1 写入、阈值 写入）。

### 8.4 AUTO_CLEAR_EN 相关用例

9. **bubble 注入与屏蔽**
   - 配置 `AUTO_CLEAR_EN==1`。
   - 观察 bubble（有效位 0）在读侧被屏蔽是否符合预期。
   - 结合 clear/full_zero，确认 bubble 的注入不会破坏正常数据流顺序。

### 8.5 CDC 与鲁棒性类用例

10. **随机异步时钟 + 随机 backpressure**
   - wclk/rclk 采用无公因数频率或随机抖动时钟。
   - s_vld 随机、m_rdy 随机，长期运行，检查数据一致性。

11. **同步级数覆盖**
   - `SYNC_STAGE=2` 与 `SYNC_STAGE=3` 均运行上述关键用例。

12. **X/稳定性检查**
   - 对跨域信号链路（wptr_async、rptr_async、pld_sync）做 X-prop/unknown 检测。
   - 在 reset、clear、stall 切换边界观察是否存在短时不确定态传播。

## 9. 约束与注意事项

1. 当前设计的指针宽度使用 `FIFO_DEPTH` 作为向量长度（one-hot），因此 `FIFO_DEPTH` 需要是合理的深度常量；与传统 `PTR_WIDTH=$clog2(FIFO_DEPTH)` 的二进制计数方式不同。
2. `pld_sync` 为跨域数据路径，若目标工艺/实现对跨域大位宽信号敏感，建议评估 marker 的实现与 CDC 策略是否满足项目 CDC 收敛要求。
3. `AUTO_CLEAR_EN` 的语义涉及 bubble 注入与输出屏蔽，建议在系统级进一步定义：bubble 是否代表“空读”、是否需要触发读指针动作等。

