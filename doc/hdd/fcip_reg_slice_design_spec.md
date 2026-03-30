# FCIP Register Slice Design Specification

## 1. 概述

本文档涵盖两个寄存器切片模块：
- **`fcip_reg_slice`**：通用寄存器切片，支持三种模式（full/forward/backward）
- **`fcip_reg_slice_full_set`**：带同步复位的全寄存器切片

寄存器切片用于切断组合逻辑路径（timing closure），在valid-ready握手协议中插入流水线级。

**所属分类：** regslice  
**文件路径：** `ip/regslice/fcip_reg_slice.sv`, `ip/regslice/fcip_reg_slice_full_set.sv`

---

## 2. fcip_reg_slice

### 2.1 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| PLD_TYPE | type | logic | 负载数据类型 |
| RS_TYPE | integer | 0 | 模式：0=full, 1=forward, 2=backward |

### 2.2 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 时钟 |
| rst_n | input | 1 | 异步复位 |
| s_vld | input | 1 | 从端valid |
| s_rdy | output | 1 | 从端ready |
| s_pld | input | PLD_TYPE | 从端负载 |
| m_vld | output | 1 | 主端valid |
| m_rdy | input | 1 | 主端ready |
| m_pld | output | PLD_TYPE | 主端负载 |

### 2.3 三种模式详解

#### RS_TYPE=1: Forward Register Slice
- **m_vld/m_pld 为寄存器输出**（切断前向路径）
- `s_rdy = !m_vld || m_rdy`（组合逻辑）
- 容量：1项，延迟：1周期
- **适用场景**：切断valid/data前向时序路径

#### RS_TYPE=2: Backward Register Slice
- **s_rdy 为寄存器输出**（切断后向路径）
- `m_vld = s_vld | vld_r`（组合逻辑）
- `m_pld = vld_r ? pld_r : s_pld`（缓冲优先）
- 容量：1项旁路缓冲
- **适用场景**：切断ready后向时序路径

#### RS_TYPE=0（默认）: Full Register Slice
- **m_vld 和 s_rdy 均为寄存器输出**（完全切断前后向路径）
- 2项环形缓冲：`pld_r[0]`, `pld_r[1]`
- `ptr_w`/`ptr_r`：2-bit指针（含溢出位）
- `s_rdy = ~full`, `m_vld = ~empty`
- 容量：2项，延迟：1周期
- **适用场景**：前后向时序均需切断

## 3. 各模式timing特性对比

| 特性 | Forward | Backward | Full |
|------|---------|----------|------|
| m_vld timing | 寄存器输出 | 组合逻辑 | 寄存器输出 |
| s_rdy timing | 组合逻辑 | 寄存器输出 | 寄存器输出 |
| m_pld timing | 寄存器输出 | MUX输出 | MUX输出 |
| 面积开销 | 1×PLD | 1×PLD | 2×PLD |
| 有效吞吐 | 100% | 100% | 100% |

---

## 4. fcip_reg_slice_full_set

### 4.1 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| PLD_TYPE | type | logic | 负载数据类型 |

### 4.2 额外接口

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| set | input | 1 | 同步复位信号（清空FIFO） |

### 4.3 功能差异
- 与 full reg_slice 相同的2项缓冲结构
- 新增 `set` 信号：同步清零读写指针（`pntr_w = pntr_w_tmp & {~set, ~set}`）
- set有效时：当拍指针强制为0，下一拍恢复正常操作
- 包含调试计数器 `cnt`（统计总写入次数）

## 5. 验证关键点与测试用例

| TC | 场景 | 预期 |
|----|------|------|
| 001 | Forward: 连续流水 | 100%吞吐，m_pld延迟1拍 |
| 002 | Forward: 背压 | m_rdy=0时s_rdy=0 |
| 003 | Backward: 连续流水 | 100%吞吐，s_rdy延迟1拍 |
| 004 | Backward: 缓冲使用 | s_rdy=0时数据缓存在pld_r |
| 005 | Full: 连续流水 | 100%吞吐 |
| 006 | Full: 2项缓冲验证 | 可同时存储2笔数据 |
| 007 | Full: 空/满状态 | 指针环绕正确切换empty/full |
| 008 | Full_set: set信号 | set=1后下一拍FIFO清空 |
| 009 | Full_set: set后重新写入 | 功能恢复正常 |
| 010 | 随机背压随机valid | 数据不丢失不重复 |
