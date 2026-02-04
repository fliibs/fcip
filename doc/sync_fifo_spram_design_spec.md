# fcip_sync_fifo_spram 设计规格书（Design Specification）

## 1. 概述

`fcip_sync_fifo_spram` 是一个**单时钟域同步 FIFO** 的 SRAM 化实现：在功能层面与 `fcip_sync_fifo_reg` 等价（valid/ready 语义的顺序入队/出队、almost_full/empty 等），但其存储体使用一个或多个 SRAM 组（SPRAM）以获得更优的面积与可扩展性。

由于 SRAM 读写访问具有固定延迟且在物理实现上可能存在 MCP（multi-cycle path）与额外 pipeline 的需求，本模块采用“分层控制”的方式实现：

- **SRAM 访问控制器**：将 FIFO 的逻辑读写转换为对多个 SRAM 组的读写请求，并通过 LUT 维护每条 FIFO entry 存放在哪个 SRAM 组。
- **ROB（Reorder Buffer）**：用于在 SRam 读数据返回存在延迟时仍保持 FIFO 的顺序输出，并在可选配置下提供 forwarding 以实现 0-cycle 额外延迟的读通路。
- **Memory Wrapper**：每个 SRAM 组通过 `fcip_mem_ctrl_wrap` 进行请求/返回 pipeline 与 MCP 反压处理。

## 2. 参考资料

- Memory wrapper：`fcip_mem_ctrl_wrap.md`
- RTL
  - `fcip_sync_fifo_spram.sv`
  - `fcip_sfifo_spram_ctrl.sv`
  - `fcip_sfifo_spram_ptr_ctrl.sv`
  - `fcip_sfifo_spram_rob.sv`

## 3. 模块边界与外部可见行为

### 3.1 FIFO 语义

- 写端：`write_req_vld/write_req_rdy` 握手成功时，将 `write_req_pld` 入队。
- 读端：当 FIFO 非空且内部数据可用时对外拉高 `read_resp_vld`；`read_resp_vld && read_resp_rdy` 握手成功时出队并消费该条目。
- 顺序性：读出的数据顺序与写入顺序一致。

### 3.2 延迟特性（概念性说明）

- 使用 SRAM 实现时，读数据通常在发起 SRAM read 后经过若干拍返回；因此本模块内部通过 ROB 维持输出次序。
- 若配置 `FORWARD_EN=1`，模块在部分场景可将数据直接 forward 到输出，从而将功能 FIFO 的额外延迟降低至 0（但会引入输入到输出的组合/短路径，需关注时序）。

> 注：具体延迟由 `SRAM_ACCESS_LATENCY/SRAM_REQ_PIPE_STAGE/SRAM_RSP_PIPE_STAGE` 等参数共同决定。

## 4. 时钟与复位

- 单时钟：`clk`
- 低有效复位：`rst_n`
- 控制：
   - `stall`：低功耗/节流信号（当前版本顶层未将 `stall` 显式接入子模块的 ready/状态机，使用前建议结合系统低功耗策略进行验证与约束）。
   - `clear`：清空信号（当前版本顶层未将 `clear` 显式接入 LUT/ROB/指针控制等子模块，使用前建议确认系统是否依赖该行为）。
- `idle`：表示模块空闲；实现为 `rob_empty && spram_ctrl_empty`。

## 5. 接口描述（valid/ready 语义）

### 5.1 写请求接口

| 信号 | 方向 | 位宽 | 说明 |
|---|---|---:|---|
| `write_req_vld` | in | 1 | 写入请求有效 |
| `write_req_pld` | in | DATA_WIDTH | 写入 payload |
| `write_req_rdy` | out | 1 | 模块可接收写入 |

写入握手条件：`write_req_vld && write_req_rdy`。

### 5.2 读响应接口

| 信号 | 方向 | 位宽 | 说明 |
|---|---|---:|---|
| `read_resp_vld` | out | 1 | 读响应有效 |
| `read_resp_pld` | out | DATA_WIDTH | 读出的 payload |
| `read_resp_rdy` | in | 1 | 下游可接收读响应 |

读出握手条件：`read_resp_vld && read_resp_rdy`。

### 5.3 状态指示

| 信号 | 方向 | 说明 |
|---|---|---|
| `almost_full` | out | 距离 full 还有阈值 X 时置位 |
| `almost_empty` | out | 距离 empty 还有阈值 X 时置位 |
| `empty` | out | FIFO 为空 |
| `full` | out | FIFO 为满 |
| `idle` | out | 模块空闲（ROB 空且 SRAM 控制层空） |

### 5.4 SRAM 物理端口（多组）

SRAM 以 group 的形式暴露，数量由 `SRAM_GROUP_NUM` 决定。

| 信号 | 方向 | 位宽 | 说明 |
|---|---|---:|---|
| `spram_addr[g]` | out | ADDR_WIDTH | 第 g 组 SRAM 地址 |
| `spram_din[g]` | out | DATA_WIDTH | 第 g 组写数据 |
| `spram_dout[g]` | in | DATA_WIDTH | 第 g 组读数据 |
| `spram_en[g]` | out | 1 | 第 g 组使能 |
| `spram_wren[g]` | out | 1 | 第 g 组写使能（1=write，0=read） |
| `spram_bit_en[g]` | out | DATA_WIDTH | bit enable（当前实现写全 1） |

## 6. 参数与约束

| 参数 | 默认值（参考RTL） | 约束 | 说明 |
|---|---:|---|---|
| `FIFO_DEPTH_PER_GROUP` | 64 | >=4（文档建议 >=32/64） | 每组 SRAM 的深度 |
| `SRAM_GROUP_NUM` | 2 | >=1（MCP=1 时建议 >=2） | SRAM 组数，用于提升吞吐 |
| `DATA_WIDTH` | 16 | >=1 | 数据位宽 |
| `ALMOST_FULL_THRESHOLD` | 2 | >=0 | almost_full 阈值 |
| `ALMOST_EMPTY_THRESHOLD` | 2 | >=0 | almost_empty 阈值 |
| `FORWARD_EN` | 1 | 0/1 | ROB forwarding 开关 |
| `ROB_DEPTH` | 16 | >= SRAM 数据返回总延迟 | ROB 深度，需覆盖 SRAM pipeline 延迟 |
| `SRAM_ACCESS_LATENCY` | 1 | >=1 | SRAM 固有访问延迟 |
| `SRAM_REQ_PIPE_STAGE` | 0 | >=0 | SRAM 请求侧 pipeline |
| `SRAM_RSP_PIPE_STAGE` | 0 | >=0 | SRAM 返回侧 pipeline |
| `MCP_CYCLE` | 1 | >=1 | SRAM MCP 周期，影响反压 |

派生量（顶层使用）：

- `SRAM_DELAY_TOTAL = SRAM_ACCESS_LATENCY + SRAM_REQ_PIPE_STAGE + SRAM_RSP_PIPE_STAGE`
- `ROB_ALMOST_FULL_THRESHOLD = ROB_DEPTH - SRAM_DELAY_TOTAL`

## 7. 内部微架构与关键实现

### 7.1 层次结构

- `fcip_sync_fifo_spram`（顶层）
  - `fcip_sfifo_spram_ctrl`：SRAM 组调度、LUT 维护、生成每组的 memory request
  - `fcip_mem_ctrl_wrap`（每组一个）：请求/返回 pipeline + MCP 反压
  - `fcip_sfifo_spram_rob`：顺序输出与 forwarding
  - 读返回 mux：将多组内存返回（`mem_rsp_*`）按 onehot 选择并送入 ROB

结合 `fcip_sync_fifo_spram.md` 的术语，顶层逻辑可概括为四个部分：

- **ROB**：维护顺序输出与可选的 forwarding。
- **Decode**：决定写请求走 ROB 还是走 SRAM 路径。
- **LUT**：记录每笔数据存放的 SRAM group（本质为不带 forwarding 的 reg FIFO）。
- **FIFO Controller / SRAM R/W Controller**：对每个 group 进行读写指针控制并生成 memory wrapper 的请求。

### 7.2 顶层写入仲裁（ROB vs SRAM）

顶层将写请求分为两条路径：

- **ROB 写入路径**：当“SRAM 控制层为空”且 ROB 允许接收时，优先写 ROB（用于降低延迟/实现 forward）。
- **SRAM 写入路径**：否则写入进入 SRAM 控制器（最终写入某个 SRAM 组）。

RTL 中的关键选择：

- `sel_rob_en = rob_write_rdy && spram_ctrl_empty`
- `sel_ram_en = ram_write_rdy && ~sel_rob_en`
- `write_req_rdy = sel_rob_en || sel_ram_en`

### 7.3 SRAM 控制器（fcip_sfifo_spram_ctrl）

该模块职责：

1. 写请求分配到某个 SRAM group
   - 使用 round-robin grant（`fcip_grant_gen_rr`）在可用组间分配
   - 关键约束：同一组同一周期避免“写与读冲突”（读优先/互斥通过 `sram_write_rdy = ptr_ctrl_write_rdy && ~ptr_ctrl_read_vld` 体现）

2. 读请求从 LUT 获取 group 选择
   - LUT 是一个不带 forwarding 的 reg FIFO（`fcip_sync_fifo_reg`），其每条 entry 记录“该 FIFO 元素位于哪个 SRAM group”（onehot）。
   - 当 LUT 出队得到 `lut_resp_pld` 后，产生 `sram_read_en` 并以 onehot 形式输出 `sram_read_sel`。

3. 背压
   - `write_rdy = ~spram_ctrl_full`（full 来自 LUT 满或资源不可用）
   - `spram_ctrl_empty = ~(|ptr_ctrl_read_rdy) || ram_lut_empty`（没有可读组或 LUT 空即为空）

### 7.4 指针控制（fcip_sfifo_spram_ptr_ctrl）

每个 SRAM group 一份 ptr 控制器：

- 维护 `wptr/rptr/ptr_cnt`
- `ram_ctrl_empty = (ptr_cnt==0)`，`ram_ctrl_full = (ptr_cnt==FIFO_DEPTH_PER_GROUP)`
- 读握手：`read_rdy = ~ram_ctrl_empty && mem_req_rdy`
- 当 `read_vld && read_rdy` 时发起 SRAM 读（`rinc`）

实现注意：`fcip_sfifo_spram_ptr_ctrl.sv` 当前将 `mem_req_addr` 固定连接到 `wptr`（参见 `assign mem_req_addr = wptr;`）。该连接方式是否符合预期需要由设计方确认；若预期为“读使用 `rptr`、写使用 `wptr`”，则该处可能需要修正。本文档在此仅做事实陈述，并在验证章节中建议针对地址相关行为增加定向用例。

### 7.5 ROB（fcip_sfifo_spram_rob）

ROB 的目标：在“SRAM 数据返回有延迟且可能乱到达（相对预分配顺序）”场景下，仍对外提供严格顺序输出。

- ROB 维护两个指针：
  - `rob_rptr`：当前应输出的 entry
  - `rob_wptr`：pre-alloc 指向下一个可分配 entry（`rob_prealloc_id`）
- 每个 entry 具有 `array_vld` 来标记数据是否就绪。

输入通道：

- `rob_req_*`：来自顶层“直接写 ROB”的请求
- `ram_req_*`：来自 SRAM 返回的数据，携带 `ram_req_id`（由 SRAM 读请求的 sideband 传回）

Forwarding（`FORWARD_EN=1`）行为摘要：

- 若 ROB 为空且下游 ready，允许将当前拍输入直接 forward 到输出，以减少额外延迟。
- 同时支持“SRAM 返回命中当前输出指针”的 forward。

## 8. 空闲/低功耗/清空

- `idle = rob_empty && spram_ctrl_empty`
- `stall/clear`：当前顶层 RTL 未将 `stall/clear` 显式接入到 LUT/ROB/ptr_ctrl 等子模块的状态机与指针清零逻辑。
   - 若系统对 `stall` 有“冻结内部状态、不发生对外部 SRAM 访问”的要求，建议补充实现或在验证中覆盖该低功耗场景。
   - 若系统对 `clear` 有“立即清空 FIFO 并丢弃在途返回”的要求，建议补充实现或在系统级规约中禁止在有在途事务时拉起 `clear`。

## 9. 验证建议（Testcase 规划）

### 9.1 基础功能

1. **基本 FIFO 入队/出队**
   - 连续写入 N 条数据，再逐条读出比对顺序与内容。

2. **满/空边界**
   - 写入至 full，确认 `write_req_rdy` 拉低、`full=1`。
   - 读出至 empty，确认 `read_resp_vld` 拉低、`empty=1`。

3. **almost_full / almost_empty 阈值**
   - 构造距离 full/empty 的边界位置，验证阈值行为。

### 9.2 延迟与 forwarding

4. **FORWARD_EN=0/1 对比**
   - 关注空 FIFO 场景的读延迟差异与时序路径。

5. **SRAM latency/pipe 组合覆盖**
   - 覆盖 `SRAM_ACCESS_LATENCY`>=1 以及 `SRAM_REQ_PIPE_STAGE/SRAM_RSP_PIPE_STAGE` 组合，确认 ROB_DEPTH 充足且不会错误输出。

### 9.3 多组 SRAM 与仲裁

6. **SRAM_GROUP_NUM=1/2/多组覆盖**
   - 随机写入与读出，确保 LUT 记录的 group 与实际访问一致。

7. **写入 round-robin 分配公平性（可选）**
   - 长序列写入检查各组写入次数分布近似均衡（仅在资源始终可用时）。

### 9.4 MCP 反压与 backpressure

8. **MCP_CYCLE>1 流控覆盖**
   - 使 `mem_req_rdy` 周期性拉低，验证系统仍能正确反压并最终按序输出。

9. **读侧反压**
   - `read_resp_rdy` 随机拉低，验证无丢失/重复输出。

### 9.5 随机压力与 Scoreboard

10. **随机读写压力**
   - 参考模型采用“理想同步 FIFO”队列。
   - 随机化：写入节奏、读 ready、参数组合（尤其是多组与 MCP）。

## 10. 设计注意事项

1. **ROB_DEPTH 选型**
   - 文档建议 `ROB_DEPTH >= SRAM 数据返回总延迟`，以避免预分配与返回对齐异常。

2. **多组 SRAM 的带宽假设**
   - 当 `MCP_CYCLE=1` 且希望达到较高吞吐时，建议 `SRAM_GROUP_NUM>=2`，以降低同组读写互斥带来的瓶颈。

3. **ptr_ctrl 地址与读写互斥**
   - ptr_ctrl 内 `mem_req_addr` 的赋值策略需与设计意图一致；建议在 review 中重点确认读地址是否正确。

