# FCIP Handshake Fanout Design Specification

## 1. 概述

`fcip_hs_fanout` 是一个1对N的握手扇出模块，将单个valid-ready握手通道的数据广播到多个下游端口。内部缓存数据并跟踪每个端口的消费状态，确保所有端口都接收到数据后才接受下一笔传输。

**所属分类：** handshake  
**文件路径：** `ip/handshake/fcip_hs_fanout.sv`

## 2. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| FANOUT_NUM | integer unsigned | 4 | 扇出端口数量 |
| PLD_TYPE | type | logic | 负载数据类型 |

## 3. 接口信号

### 3.1 从端口（输入）

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 时钟 |
| rst_n | input | 1 | 异步复位（低有效） |
| slv_vld | input | 1 | 从端口数据有效 |
| slv_pld | input | PLD_TYPE | 从端口数据负载 |
| slv_rdy | output | 1 | 从端口就绪 |

### 3.2 主端口（输出，N个）

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| v_mst_vld | output | FANOUT_NUM | 各端口数据有效 |
| mst_pld | output | PLD_TYPE | 共享数据负载 |
| v_mst_rdy | input | FANOUT_NUM | 各端口就绪 |

## 4. 功能描述

### 4.1 数据缓冲
- 上游握手成功时 (`slv_vld && slv_rdy`)，数据写入 `buf_pld`，`buf_vld` 置1
- 所有端口消费完成后，`buf_vld` 清0

### 4.2 逐端口消费跟踪
- 每个端口有独立的 `v_is_consumed[i]` 标志
- 当 `v_mst_vld[i] && v_mst_rdy[i]` 时，标记端口i已消费
- 新数据到来时清除所有消费标志

### 4.3 消费完成判断
```
all_consumed = &v_is_consumed                    // 多周期逐个消费完成
             | (buf_vld && (&v_mst_rdy))         // 单周期全部消费
```

### 4.4 从端口流控
- `slv_rdy = ~buf_vld | all_consumed`
- 缓冲区空或全部消费完成时可接收新数据

### 4.5 主端口流控
- `v_mst_vld[i] = buf_vld && (~v_is_consumed[i])`
- 缓冲区有数据且端口i未消费时输出有效

## 5. 时序特性

- **最短延迟**：所有端口同时ready → 1周期完成扇出
- **最长延迟**：每个端口依次ready → FANOUT_NUM周期
- **输入到输出**：slv → buf_pld → mst_pld，有1周期延迟

## 6. 验证关键点与测试用例

| TC | 场景 | 预期 |
|----|------|------|
| 001 | 所有端口同时ready | 单周期广播完成 |
| 002 | 端口逐个ready | 逐个标记consumed，全部完成后ready |
| 003 | 部分端口永远不ready | slv_rdy保持0（阻塞） |
| 004 | 连续数据流 | 每次all_consumed后接收新数据 |
| 005 | 复位后状态 | buf_vld=0, v_is_consumed全0 |
| 006 | FANOUT_NUM=1 | 退化为register slice功能 |
| 007 | 自定义PLD_TYPE | struct类型数据完整性 |
| 008 | 端口ready交错变化 | consumed状态只增不减直到新数据 |
