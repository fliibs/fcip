# fcip_mem_fake_2p_mem 设计规格书（Design Specification）

## 1. 概述

`fcip_mem_fake_2p_mem` 旨在使用**单口 SRAM（SPRAM）**构建对上层等价于“1 写 1 读”（近似 DPRAM/2P SRAM）的访问语义：

- 写端口：valid/ready 握手写请求（支持 bit mask）。
- 读端口：valid/ready 握手读请求（携带 sideband），读响应同样使用 valid/ready。
- 内部通过**读写仲裁 + 写缓冲（可选） + 读缓冲（可选） + forward/旁路（可选）**等机制，在受限的单口 SRAM 带宽（同一周期最多完成一次 memory op）下尽量平滑读写冲突及峰值带宽。

该模块适用于：

- 功能层希望以双口方式访问存储，但物理实现仅可提供单口 SRAM 时；
- 读写存在峰值冲突，允许引入缓冲与一定出入延迟；
- 需要通过配置参数在 latency、带宽与时序收敛之间做权衡。

## 2. 参考资料

- RTL：
  - `fcip_mem_fake_2p_mem.sv`
  - `fcip_mem_fake_write_buffer.sv`
  - `fcip_mem_fake_find_new_bit.sv`
  - `fcip_mem_ctrl_wrap.sv`

## 3. 模块边界与外部可见行为

### 3.1 上层可见的“伪双口”语义

- 上层同时可以发起写请求与读请求；但由于内部单口 SRAM 的限制，读/写会通过仲裁**串行化**进入 SRAM。
- 当出现读写冲突时：
  - 若启用写缓冲：写可先进入 buffer，后续由模块择机写入 SRAM；读在必要时可从写缓冲中做 forwarding，以保证读到“最新值”。
  - 若不启用写缓冲：写请求会直接参与仲裁，读写冲突时通过 ready 反压进行节流。

### 3.2 读一致性与写后读（Read-After-Write）

模块提供写后读一致性能力，典型场景：

- 当读请求命中尚未落入 SRAM 的写缓冲条目时，读响应可以返回写缓冲中的数据，以避免读到旧值。
- 若启用 bit mask（`WRITE_BIT_MASK_EN=1`）：
  - forwarding 会以“每 bit 最新写入”为粒度，按写缓冲中更“新”的 bit 选择数据进行合并。

> 说明：该一致性特性服务于“单端口 SRAM 虚拟双口”的功能正确性，上层不需要额外插入写后读屏障。

## 4. 时钟与复位

- 单时钟域：`clk`。
- 低有效异步复位：`rst_n`。
- `clear`：同步清空内部状态（写缓冲指针/读缓冲 FIFO 等复位到空）。
- `stall`：低功耗/节流输入，模块会反压请求并尽可能保持内部状态不前进。

## 5. 接口定义与握手语义

### 5.1 端口列表

#### 写请求接口

| 信号 | 方向 | 位宽 | 说明 |
|---|---|---:|---|
| `write_req_vld` | in | 1 | 写请求有效 |
| `write_req_rdy` | out | 1 | 写请求就绪（允许接收） |
| `write_req_addr` | in | ADDR_WIDTH | 写地址 |
| `write_req_data` | in | DATA_WIDTH | 写数据 |
| `write_req_bit_en` | in | DATA_WIDTH | 写 bit mask（1 表示该 bit 有效写入） |

写握手条件：`write_req_vld && write_req_rdy`。

#### 读请求接口

| 信号 | 方向 | 位宽 | 说明 |
|---|---|---:|---|
| `read_req_vld` | in | 1 | 读请求有效 |
| `read_req_rdy` | out | 1 | 读请求就绪（允许接收） |
| `read_req_addr` | in | ADDR_WIDTH | 读地址 |
| `read_req_sideband` | in | SIDEBAND_WIDTH | 读请求 sideband（与该笔读响应绑定） |

读握手条件：`read_req_vld && read_req_rdy`。

#### 读响应接口

| 信号 | 方向 | 位宽 | 说明 |
|---|---|---:|---|
| `read_resp_vld` | out | 1 | 读响应有效 |
| `read_resp_rdy` | in | 1 | 读响应就绪（对端可接收） |
| `read_resp_data` | out | DATA_WIDTH | 读数据 |
| `read_resp_sideband` | out | SIDEBAND_WIDTH | 返回与请求匹配的 sideband |

读响应握手条件：`read_resp_vld && read_resp_rdy`。

#### SRAM 物理端口

| 信号 | 方向 | 位宽 | 说明 |
|---|---|---:|---|
| `spram_addr` | out | ADDR_WIDTH | SRAM 地址 |
| `spram_din` | out | DATA_WIDTH | SRAM 写数据 |
| `spram_dout` | in | DATA_WIDTH | SRAM 读数据 |
| `spram_en` | out | 1 | SRAM 使能（访问请求） |
| `spram_wren` | out | 1 | SRAM 写使能（1=write，0=read） |
| `spram_bit_en` | out | DATA_WIDTH | SRAM bit enable（读时强制全 1） |

#### 低功耗/控制

| 信号 | 方向 | 位宽 | 说明 |
|---|---|---:|---|
| `stall` | in | 1 | 节流/低功耗暂停 |
| `clear` | in | 1 | 清空内部状态 |
| `idle` | out | 1 | 模块空闲指示（读缓冲 idle 且写缓冲为空） |

### 5.2 Backpressure 规则摘要

- `stall=1` 时：
  - 写请求：`write_req_rdy` 将被拉低（通过 write buffer/或仲裁实现），避免接受新写。
  - 读请求：`read_req_rdy` 将被拉低（逻辑中显式包含 `~stall` 约束）。
- `clear=1` 时：内部 FIFO/指针清零，`idle` 将在各缓冲排空后返回 1。

## 6. 参数与约束

| 参数 | 默认值 | 约束 | 说明 |
|---|---:|---|---|
| `SRAM_ACCESS_LATENCY` | 1 | >=1 | 外部 SRAM 固有访问延迟 |
| `SRAM_REQ_PIPE_STAGE` | 0 | >=0 | 发往 SRAM 的请求侧额外 pipeline 级数 |
| `SRAM_RSP_PIPE_STAGE` | 0 | >=0 | SRAM 返回侧额外 pipeline 级数 |
| `SIDEBAND_WIDTH` | 1 | >=1 | 读请求/响应 sideband 位宽 |
| `DATA_WIDTH` | 128 | >=1 | 数据位宽 |
| `ADDR_WIDTH` | 10 | >=1 | 地址位宽 |
| `MCP_CYCLE` | 1 | >=1 | SRAM 多周期访问间隔（Flow Control 产生反压） |
| `WRITE_BUFFER_SIZE` | 4 | >=0 | 写缓冲深度；为 0 时禁用写缓冲 |
| `RW_ARBITER_TYPE` | 0 | 0/1 | 仲裁类型：0=读优先；1=写优先 |
| `READ_FORWARD_EN` | 1 | 0/1 | 是否启用读响应“空 FIFO 直通”forwarding（减少延迟） |
| `READ_BUFFER_SIZE` | 4 | 需满足设计选型 | 读缓冲 FIFO 深度（用于吸收 read_resp 反压与 mem latency） |
| `WRITE_BIT_MASK_EN` | 1 | 0/1 | 是否启用 bit mask 与按 bit forwarding（性能/时序开销较大） |

派生参数：

- `MEM_LATENCY = SRAM_ACCESS_LATENCY + SRAM_REQ_PIPE_STAGE + SRAM_RSP_PIPE_STAGE`

约束提示（来自实现中的用法）：

- `READ_BUFFER_SIZE` 与 `MEM_LATENCY` 直接影响 `ALMOST_FULL_THRESHOLD = READ_BUFFER_SIZE - MEM_LATENCY`，因此应保证 `READ_BUFFER_SIZE >= MEM_LATENCY`，以避免阈值为负导致的综合/仿真异常。

## 7. 内部微架构（实现要点）

### 7.1 总体数据通路

1. 写请求进入：
   - `WRITE_BUFFER_SIZE==0`：写请求直达仲裁器。
   - `WRITE_BUFFER_SIZE>0`：写请求先进入写缓冲 `fcip_mem_fake_write_buffer`。

2. 读请求进入仲裁：
   - 读请求 `read_req_rdy` 受以下因素约束：
     - 读缓冲接近满（`fifo_almost_full`）
     - `stall`
     - 下游读输出是否可推进（`read_out_rdy`）
     - `mem_req_rdy`（来自 `fcip_mem_ctrl_wrap` 的流控/MCP）
     - 写优先模式下：若存在待写（`write_sram_vld`）则读会被挡住（防止同拍冲突）

3. 单口 SRAM 访问：
   - 通过 `fcip_mem_ctrl_wrap` 连接到物理 SRAM 端口，提供：
     - MCP 周期流控：`mem_req_rdy`
     - 请求/返回 pipeline：`SRAM_*` 参数
     - SRAM marker：用于物理侧识别与 MCP 设置

4. 读数据返回：
   - 从 `fcip_mem_ctrl_wrap` 得到 `mem_rsp_en / mem_rsp_data / mem_rsp_sideband`。
   - 若开启写缓冲：可进行 read-after-write forwarding/merge。
   - 最终进入读缓冲 `fcip_sync_fifo_reg`，并按 `READ_FORWARD_EN` 决定是否“空 FIFO 直通”。

### 7.2 读写仲裁（RW_ARBITER_TYPE）

- `RW_ARBITER_TYPE=0`（读优先）：
  - `read_req_rdy = ~(fifo_almost_full || stall) && read_out_rdy && mem_req_rdy`
  - `write_sram_rdy = ~read_req_vld && mem_req_rdy`
  - 当同周期同时有读/写请求时，优先服务读（写端通过 rdy 被反压或停留在写缓冲）。

- `RW_ARBITER_TYPE=1`（写优先）：
  - 读端额外约束 `~write_sram_vld`，即只要存在待写，读就不被接受。

### 7.3 写缓冲（fcip_mem_fake_write_buffer）

启用方式：`WRITE_BUFFER_SIZE>0`。

要点：

- buffer 内保存 `{write_addr, write_data, write_bit_en}`。
- 使用环形队列通过 `wr_ptr/rd_ptr` 管理；`full/empty` 基于指针 MSB 翻转判定。
- `write_req_rdy = ~(full || stall)`，`stall` 会暂停接受新写。
- buffer 向 SRAM 侧输出采用 `write_buffer_vld/write_buffer_rdy` 握手；当 `write_buffer_rdy` 为 1 时释放队头条目。

写后读旁路支持：

- 在读请求握手后（读优先模式中产生 `read_cmp_vld/read_cmp_addr`），写缓冲对读地址进行比较。
- `WRITE_BIT_MASK_EN=1`：使用 `fcip_mem_fake_find_new_bit`，按 bit 选择最新写入的值与有效 bit。
- `WRITE_BIT_MASK_EN=0`：按条目粒度选择最新写（不考虑 bit 层次覆盖）。
- 若 `MEM_LATENCY>1`：旁路命中与数据会通过 `fcip_data_pipe` 延迟对齐到 SRAM 返回拍。

### 7.4 Bit mask “最新写 bit”选择（fcip_mem_fake_find_new_bit）

该模块在“读地址命中写缓冲时”，为每个 bit 选择最近一次写入（bit_en=1）的数据来源，输出：

- `cmp_hit`：地址维度是否命中任一条目
- `cmp_hit_data`：按 bit 选出的写数据
- `cmp_hit_bit_en`：每 bit 是否命中（用于 merge）

实现思想：

- 将写缓冲按 bit 展开为二维矩阵。
- 根据 `wr_ptr` 将条目分为“顺序更新的前半段/后半段”，分别做 lead-one 以找到“最新”的条目（forward/backward）。
- 对于命中的 bit，仅从被选中的条目抽取该 bit 的数据。

### 7.5 读数据选择与 merge

在写缓冲启用场景下（`WRITE_BUFFER_SIZE>0`）：

- `WRITE_BIT_MASK_EN=0`：若命中则读数据选择写缓冲数据，否则选择 SRAM 数据。
- `WRITE_BIT_MASK_EN=1`：
  - `rsp_vld_data = mem_rsp_data & ~read_hit_data_bit_en_delay`
  - `data_merge = rsp_vld_data | read_hit_data_delay`
  - 命中时返回 `data_merge`，即：
    - 命中的 bit 使用写缓冲数据
    - 未命中的 bit 使用 SRAM 返回数据

### 7.6 读缓冲与 read forwarding

读缓冲使用 `fcip_sync_fifo_reg` 实现，功能包括：

- 吸收 `read_resp_rdy` 反压，避免直接阻塞 SRAM 返回。
- 通过 `almost_full` 对读请求提供预防性反压，避免 FIFO 溢出。

`READ_FORWARD_EN=1` 时：

- 若读缓冲为空且下游 `read_resp_rdy=1`，则读数据可“直通”输出，绕开 FIFO 增加的 1 拍延迟。
- 直通使能：`forward_enable = read_resp_rdy && read_buffer_empty`。

## 8. 低功耗与空闲指示

- `stall`：在请求入口与内部流控处参与 ready 生成。当 `stall=1` 时模块停止接收新事务并尽量保持静止。
- `clear`：清空写缓冲、读缓冲等内部状态。
- `idle`：
  - 实现为 `idle = read_buffer_idle && write_buffer_empty`。
  - 表征读缓冲已进入 idle 状态且写缓冲为空。

> 注：`WRITE_BUFFER_SIZE==0` 时写缓冲不存在，但实现中仍声明了 `write_buffer_empty` 信号；集成时需确保该模式下 `idle` 的综合/仿真语义正确（通常依赖未启用分支不会引用/或信号在上层被 tie-off）。建议在最终交付前对 `WRITE_BUFFER_SIZE==0` 配置做一次 lint/仿真确认。

## 9. 验证建议（Testcase 规划）

### 9.1 基础功能类

1. **单写单读基本功能**
   - 连续写 N 笔不同地址，再逐笔读回。
   - 覆盖：`READ_FORWARD_EN=0/1`。

2. **读 sideband 对齐**
   - 读请求 sideband 取递增序列，检查 `read_resp_sideband` 与返回数据一一对应。
   - 在 `read_resp_rdy` 随机拉低下验证顺序不乱。

3. **写 bit mask 基本功能（WRITE_BIT_MASK_EN=1）**
   - 对同一地址做多次写，每次仅更新部分 bit；最终读回应为各次写合并后的值。

### 9.2 冲突与一致性类

4. **写后读（RAW）一致性：命中写缓冲**
   - `WRITE_BUFFER_SIZE>0`：写入后立即对相同地址发起读，且让写缓冲中条目暂时不落 SRAM（通过制造读优先/或 mem_req_rdy 节流）。
   - 期望：读返回为最新值。

5. **同地址多次写 + 按 bit 最新值选择**
   - 多次写相同地址，每次更新不同 bit 的 bit_en，穿插读。
   - 期望：读出每 bit 均来自最后一次写该 bit 的事务。

6. **读写冲突仲裁覆盖（RW_ARBITER_TYPE=0/1）**
   - 同拍同时施加读/写请求，检查：
     - 读优先：读成功握手，写被 backpressure。
     - 写优先：写被接受/推进时读被 backpressure。

### 9.3 流控与吞吐类

7. **`MCP_CYCLE>1` 反压覆盖**
   - 设置 `MCP_CYCLE=2/3`，使 `mem_req_rdy` 周期性无效。
   - 检查：
     - 模块能正确反压读写入口
     - `read_resp` 最终按顺序返回
     - 无 overflow/underflow

8. **读缓冲 almost_full 行为**
   - 让 `read_resp_rdy` 长时间拉低，持续发起读请求直到 `read_req_rdy` 被拉低。
   - 期望：`fifo_almost_full` 生效，读请求被挡住，系统不溢出。

9. **READ_FORWARD_EN 直通正确性**
   - FIFO 空、下游 ready=1 时，检查读响应延迟是否按预期减少；同时保证在 ready 抖动时无丢包。

### 9.4 低功耗/清空类

10. **stall 功能**
   - 事务进行中随机插入 `stall=1` 若干周期，再释放。
   - 期望：不破坏返回顺序，无重复/丢失握手。

11. **clear 功能**
   - 在写缓冲非空、读缓冲非空时拉高 `clear`。
   - 期望：内部状态回到空；后续新事务功能正确；不产生错误的残留响应。

### 9.5 随机压力与对拍模型

12. **随机读写压力（推荐）**
   - 可构建参考模型（scoreboard）：
     - 以“逻辑双口存储”为金标准
     - 写按 bit_en 更新模型
     - 读按接收顺序出队比对
   - 随机化：地址、数据、bit_en、读写节奏、`read_resp_rdy`、`stall/clear` 插入点。

## 10. 设计与集成注意事项

1. **参数组合与时序权衡**
   - `SRAM_RSP_PIPE_STAGE` 与 `READ_FORWARD_EN` 具有强关联：当不打 RSP pipe 时开启直通可能会将更多组合逻辑压在同一拍，需要关注时序。

2. **READ_BUFFER_SIZE 选型**
   - `READ_BUFFER_SIZE` 建议至少覆盖 `MEM_LATENCY` 与系统可能出现的下游反压窗口，避免频繁触发 almost_full。

3. **WRITE_BIT_MASK_EN 的代价**
   - 按 bit 的 hazard 选择涉及二维矩阵与 lead-one 逻辑，可能带来面积与时序压力；若系统不需要 bit 级掩码写，建议关闭。

4. **功能边界**
   - 该模块不提供 ECC；未来若需要可在“ECC decode”预留位置扩展。

