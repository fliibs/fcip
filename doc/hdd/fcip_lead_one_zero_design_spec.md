# FCIP Lead One / Lead Zero Detectors Design Specification

## 1. 概述

前导检测器系列提供从位向量中查找第一个有效位（前导1）或第一个空闲位（前导0）的功能，支持单路和多路批量查找。

**所属分类：** basic  
**目录路径：** `ip/basic/`

---

## 2. fcip_lead_one — 前导1检测器（LSB优先）

**文件：** `ip/basic/fcip_lead_one.sv`

### 参数
| 参数名 | 默认值 | 描述 |
|--------|--------|------|
| ENTRY_NUM | 16 | 条目数 |

### 接口
| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| v_entry_vld | input | ENTRY_NUM | 有效位向量 |
| v_free_idx_oh | output | ENTRY_NUM | 第一个有效位（独热码） |
| v_free_idx_bin | output | $clog2(ENTRY_NUM) | 第一个有效位（二进制） |
| v_free_vld | output | 1 | 存在有效位标志 |

### 功能
从bit 0开始查找第一个为1的位，输出独热码和二进制索引。

### 验证用例
| TC | 场景 | 预期 |
|----|------|------|
| 001 | v_entry_vld=16'h0001 | idx=0 |
| 002 | v_entry_vld=16'h8000 | idx=15 |
| 003 | v_entry_vld=16'h0000 | v_free_vld=0 |
| 004 | v_entry_vld=16'hFFFF | idx=0（最低位） |

---

## 3. fcip_lead_one_msb — 前导1检测器（MSB优先）

**文件：** `ip/basic/fcip_lead_one_msb.sv`

### 参数/接口
与`fcip_lead_one`相同。

### 功能
从最高位（ENTRY_NUM-1）开始查找第一个为1的位。

### 验证用例
| TC | 场景 | 预期 |
|----|------|------|
| 001 | v_entry_vld=16'hFFFF | idx=15（最高位） |
| 002 | v_entry_vld=16'h0003 | idx=1 |

---

## 4. fcip_lead_one_rev — 反向前导1检测器

**文件：** `ip/basic/fcip_lead_one_rev.sv`

### 功能
先将输入向量反转，做LSB优先的lead_one检测，再将结果反转回来。效果等价于MSB优先查找。

---

## 5. fcip_list_lead_one — 多路前导1检测器（LSB优先）

**文件：** `ip/basic/fcip_list_lead_one.sv`

### 参数
| 参数名 | 默认值 | 描述 |
|--------|--------|------|
| ENTRY_NUM | 16 | 条目数 |
| REQ_NUM | 4 | 需要查找的数量 |

### 接口
| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| v_entry_vld | input | ENTRY_NUM | 有效位向量 |
| v_free_idx_oh | output | ENTRY_NUM×REQ_NUM | 各路结果（独热码） |
| v_free_idx_bin | output | $clog2(ENTRY_NUM)×REQ_NUM | 各路结果（二进制） |
| v_free_vld | output | REQ_NUM | 各路有效标志 |

### 功能
级联查找：找到第一个后通过XOR掩码消除该位，再找下一个。可一次找到REQ_NUM个有效位。

### 验证用例
| TC | 场景 | 预期 |
|----|------|------|
| 001 | 4个有效位，REQ_NUM=4 | 全部找到 |
| 002 | 2个有效位，REQ_NUM=4 | 后2个v_free_vld=0 |
| 003 | 无有效位 | 全部v_free_vld=0 |

---

## 6. fcip_list_lead_one_rev — 多路反向前导1检测器

**文件：** `ip/basic/fcip_list_lead_one_rev.sv`

### 功能
与`fcip_list_lead_one`类似，但从MSB优先查找。

---

## 7. fcip_list_lead_zero — 多路前导0检测器

**文件：** `ip/basic/fcip_list_lead_zero.sv`

### 参数/接口
与`fcip_list_lead_one`相同。

### 功能
查找第一个为0的位（空闲位），常用于资源分配场景。
- 判断条件：`~vv_vld[i][j] && (&vv_vld[i][j-1:0])`（所有低位都为1时，当前位为0）

### 验证用例
| TC | 场景 | 预期 |
|----|------|------|
| 001 | v_entry_vld=16'hFFFE | 第一个0在bit 0 |
| 002 | v_entry_vld=16'hFFFF | 无空闲位 |
| 003 | 批量分配REQ_NUM个 | 正确找到多个空闲位 |
