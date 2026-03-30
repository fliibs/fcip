# FCIP MIMO Queue Design Specification

## 1. 概述

`fcip_ip_mimo_queue` 是一个多入多出（MIMO）队列，支持多个写端口和多个读端口同时操作。采用基于信用（credit）的流控机制管理队列容量，使用循环指针和位图映射实现高效的多端口并发读写。

**所属分类：** basic  
**文件路径：** `ip/basic/fcip_ip_mimo_queue.sv`

## 2. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| DEPTH | int unsigned | 128 | 队列深度 |
| WR_WIDTH | int unsigned | 4 | 写端口数量 |
| RD_WIDTH | int unsigned | 4 | 读端口数量 |
| PLD_TYPE | type | logic | 负载数据类型 |

### 内部参数

| 参数名 | 计算公式 | 描述 |
|--------|----------|------|
| CRDT_CNT_WIDTH | $\lceil\log_2(DEPTH)\rceil + 1$ | 信用计数器位宽 |
| DEPTH_WIDTH | $\lceil\log_2(DEPTH)\rceil$ | 深度索引位宽 |
| WRITE_NUM_WIDTH | $\lceil\log_2(WR\_WIDTH)\rceil + 1$ | 写入数量位宽 |
| READ_NUM_WIDTH | $\lceil\log_2(RD\_WIDTH)\rceil + 1$ | 读出数量位宽 |
| PTR_WIDTH | $\lceil\log_2(DEPTH)\rceil + 1$ | 指针位宽（含溢出位） |

## 3. 接口信号

### 3.1 写入请求通道

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| v_req_rdy[i] | output | WR_WIDTH | 写端口i就绪（剩余容量≥i+1） |
| v_req_vld[i] | input | WR_WIDTH | 写端口i有效 |
| v_req_pld[i] | input | PLD_TYPE | 写端口i数据 |

### 3.2 读取应答通道

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| v_ack_vld[i] | output | RD_WIDTH | 读端口i有效（已用容量>i） |
| v_ack_rdy[i] | input | RD_WIDTH | 读端口i就绪 |
| v_ack_pld[i] | output | PLD_TYPE | 读端口i数据 |

## 4. 功能描述

### 4.1 信用流控机制
- `crdt_cnt`：记录队列中已占用的条目数
- `crdt_residue = DEPTH - crdt_cnt`：剩余可用容量
- 写端口i仅当 `crdt_residue >= i+1` 时允许写入（低编号端口优先）
- 读端口i仅当 `crdt_cnt > i` 时有数据可读（低编号端口优先）

### 4.2 写入数量累计
- `v_write_num_acc[i]`：端口0到端口i实际写入的累计数量
- 用于更新写指针和信用计数器

### 4.3 读出数量累计
- `v_read_num_acc[i]`：端口0到端口i实际读出的累计数量
- 用于更新读指针和信用计数器

### 4.4 读写指针管理
- `wr_ptr`：按累计写入量递增
- `rd_ptr`：按累计读出量递增
- 读端口i的地址 = `rd_ptr + i`（自然顺序）
- 写端口i的地址 = `wr_ptr + i`

### 4.5 位图映射写入
- 每个队列条目检查所有写端口，找到匹配地址的数据进行写入
- `wr_entry_en_map[i]`：条目i的写使能
- `wr_entry_data_map[i]`：条目i的写数据（多端口OR合并）

## 5. 架构

```
v_req_pld[0..WR-1] --> [地址映射] --> queue_entry[0..DEPTH-1] --> [指针读取] --> v_ack_pld[0..RD-1]
                         ^                                            ^
                         |                                            |
                    wr_ptr + offset                             rd_ptr + offset
                         ^                                            ^
                         |                                            |
                    credit counter <------- crdt_add / crdt_sub ------+
```

## 6. 验证关键点与测试用例

| TC | 场景 | 预期 |
|----|------|------|
| 001 | 单写单读 | 基本FIFO功能正确 |
| 002 | 多端口同时写入 | 所有有效端口数据正确写入 |
| 003 | 多端口同时读出 | 按FIFO顺序读出 |
| 004 | 满队列时写入 | v_req_rdy全0 |
| 005 | 空队列时读出 | v_ack_vld全0 |
| 006 | 信用边界：剩余容量=2 | 仅v_req_rdy[0:1]有效 |
| 007 | 端口优先级检查 | 低编号端口始终优先分配 |
| 008 | 循环指针回绕 | 指针越过DEPTH后正确回绕 |
| 009 | 满带宽读写 | 同时写WR_WIDTH个+读RD_WIDTH个 |
| 010 | 自定义PLD_TYPE | struct类型数据完整性 |
