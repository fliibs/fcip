# FCIP Standard Cell Wrapper Design Specification

## 1. 概述

本文档涵盖所有标准单元封装模块，为CDC（跨时钟域）同步、时钟/数据路径标记以及多级流水线提供统一接口。这些模块在综合时映射到工艺库特定标准单元，仿真时使用RTL行为模型。

**所属分类：** stdcell_wrap  
**文件路径：** `ip/stdcell_wrap/`

---

## 2. fcip_sync_cell — CDC同步单元（顶层封装）

### 2.1 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| DATA_WIDTH | integer unsigned | 1 | 数据位宽 |
| SYN_STAGE | integer unsigned | 2 | 同步级数（≥2） |
| VT_TYPE | integer unsigned | 0 | 电压阈值类型 |
| RST_VALUE | logic [DATA_WIDTH-1:0] | 全0 | 复位值（逐bit选择arst/aset） |

### 2.2 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 目标时钟域时钟 |
| rst_n | input | 1 | 异步复位 |
| d | input | DATA_WIDTH | 源时钟域数据 |
| q | output | DATA_WIDTH | 同步后数据 |

### 2.3 功能
- **逐bit选择同步器类型**：
  - `RST_VALUE[i] == 0` → 使用 `fcip_sync_arst`（异步复位清零）
  - `RST_VALUE[i] == 1` → 使用 `fcip_sync_aset`（异步置位）
- 支持通过 `` `define `` 宏替换同步器实现：
  - `` `FCIP_SYNC_CELL_ARST_MODULE_NAME ``
  - `` `FCIP_SYNC_CELL_ASET_MODULE_NAME ``

---

## 3. fcip_sync_arst — 异步复位多级同步器

### 3.1 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| SYN_NUM | integer unsigned | 2 | 同步级数（≥2） |
| VT_TYPE | integer unsigned | 0 | 电压阈值类型 |

### 3.2 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| D | input | 1 | 数据输入 |
| SI | input | 1 | 扫描链输入 |
| SE | input | 1 | 扫描使能 |
| CP | input | 1 | 时钟 |
| CDN | input | 1 | 异步复位（低有效） |
| Q | output | 1 | 同步输出 |

### 3.3 功能
- SYN_NUM 级移位寄存器，`Q = meta[SYN_NUM-1]`
- `CDN=0` → 所有级清零
- `SE=1` → 扫描模式（SI输入）
- `SE=0` → 正常模式（D输入）

---

## 4. fcip_sync_aset — 异步置位多级同步器

### 4.1 参数与接口
- 与 `fcip_sync_arst` 完全对称
- `SDN`（代替CDN）：异步置位（低有效）
- `SDN=0` → 所有级置1（而非清零）

---

## 5. fcip_clk_marker — 时钟缓冲标记单元

### 5.1 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| VT_TYPE | integer unsigned | 1 | 电压阈值类型（0:SVT 1:LVT 2:ULVT 3:ELVT 4:LVTLL 5:ULVTLL） |

### 5.2 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| I | input | 1 | 时钟输入 |
| Z | output | 1 | 时钟输出 |

### 5.3 功能
- 仿真：`Z = I`（透传）
- 综合：映射到工艺库时钟缓冲器
  - N4A H280工艺：`CKBKBD4BWP280H6P57CNOD{VT}` 系列
  - N4A H210工艺：`CKBMZD4BWP210H6P51CNOD{VT}` 系列
- 用途：为CDC约束工具提供时钟路径标记点

---

## 6. fcip_marker — 数据缓冲标记单元

### 6.1 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| DATA_WIDTH | integer unsigned | 1 | 数据位宽 |
| VT_TYPE | integer unsigned | 1 | 电压阈值类型 |

### 6.2 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| I | input | DATA_WIDTH | 数据输入 |
| Z | output | DATA_WIDTH | 数据输出 |

### 6.3 功能
- 仿真：`Z[i] = I[i]`（逐bit透传）
- 综合：映射到工艺库数据缓冲器
  - N4A H280工艺：`BUFFKBD5BWP280H6P57CNOD{VT}` 系列
  - N4A H210工艺：`BUFFMZD4BWP210H6P51CNOD{VT}` 系列
- 用途：为STA/CDC工具提供数据路径标记点

---

## 7. fcip_data_pipe — 数据流水线

### 7.1 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| DATA_WIDTH | integer unsigned | 1 | 数据位宽 |
| PIPE_STAGE | integer unsigned | 2 | 流水线级数 |
| VT_TYPE | integer unsigned | 0 | 电压阈值类型 |

### 7.2 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 时钟 |
| rst_n | input | 1 | 异步复位 |
| d | input | DATA_WIDTH | 输入数据 |
| q | output | DATA_WIDTH | 延迟PIPE_STAGE拍输出 |

### 7.3 功能
- PIPE_STAGE ≥ 2：复用 `fcip_sync_arst`（每bit独立的SYN_NUM级移位） 
- PIPE_STAGE = 1：简单寄存器（`always_ff`）
- 输出 q 延迟 PIPE_STAGE 个时钟周期

---

## 8. VT_TYPE 电压阈值类型映射

| VT_TYPE | 类型 | 说明 |
|---------|------|------|
| 0 | SVT/LVT* | 标准/低阈值 |
| 1 | LVT/SVT* | 低/标准阈值 |
| 2 | ULVT | 超低阈值 |
| 3 | ELVT | 极低阈值 |
| 4/7 | LVTLL | 低阈值长沟道 |
| 5/8 | ULVTLL | 超低阈值长沟道 |

*注：不同模块的VT_TYPE编号含义略有差异，需参照各模块参数注释。

---

## 9. 验证关键点与测试用例

| TC | 场景 | 预期 |
|----|------|------|
| 001 | sync_cell: RST_VALUE混合01 | 不同bit使用不同同步器 |
| 002 | sync_arst: 复位后同步 | CDN释放后SYN_NUM拍输出稳定 |
| 003 | sync_aset: 复位后同步 | SDN释放后SYN_NUM拍输出稳定 |
| 004 | sync_arst: 扫描模式 | SE=1时SI数据移入 |
| 005 | clk_marker: 仿真透传 | Z==I |
| 006 | marker: 多bit透传 | 每bit独立 |
| 007 | data_pipe: PIPE_STAGE=1 | 延迟1拍 |
| 008 | data_pipe: PIPE_STAGE=4 | 延迟4拍 |
| 009 | data_pipe: 复位 | 输出清零 |
| 010 | CDC场景：异步信号同步 | 亚稳态收敛（仿真gate-level） |
