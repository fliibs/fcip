# FCIP Basic Logic Components Design Specification

## 1. 概述

basic分类下包含编码转换、前导检测、复用器、乘法器、队列等基础逻辑组件。本文档涵盖以下IP：

**所属分类：** basic  
**目录路径：** `ip/basic/`

---

## 2. fcip_bin2onehot — 二进制转独热码

**文件：** `ip/basic/fcip_bin2onehot.sv`

### 参数
| 参数名 | 默认值 | 描述 |
|--------|--------|------|
| BIN_WIDTH | 5 | 二进制输入位宽 |
| ONEHOT_WIDTH | 2^BIN_WIDTH | 独热码输出位宽 |

### 接口
| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| bin_in | input | BIN_WIDTH | 二进制输入 |
| onehot_out | output | ONEHOT_WIDTH | 独热码输出 |

### 功能
对每一位i：`onehot_out[i] = (bin_in == i)`

### 验证用例
| TC | 场景 | 预期 |
|----|------|------|
| 001 | bin_in=0 | onehot_out[0]=1，其余为0 |
| 002 | bin_in=max | 最高位为1 |
| 003 | 遍历所有值 | 每次恰好1位为1 |

---

## 3. fcip_onehot2bin — 独热码转二进制

**文件：** `ip/basic/fcip_onehot2bin.sv`

### 参数
| 参数名 | 默认值 | 描述 |
|--------|--------|------|
| ONEHOT_WIDTH | 4 | 独热码输入位宽 |
| BIN_WIDTH | $clog2(ONEHOT_WIDTH) | 二进制输出位宽 |

### 接口
| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| onehot_in | input | ONEHOT_WIDTH | 独热码输入 |
| bin_out | output | BIN_WIDTH | 二进制输出 |

### 功能
遍历onehot_in，找到为1的位，输出其索引。如果多位为1，以最高位为准。

### 验证用例
| TC | 场景 | 预期 |
|----|------|------|
| 001 | onehot_in=4'b0001 | bin_out=0 |
| 002 | onehot_in=4'b1000 | bin_out=3 |
| 003 | 全0输入 | bin_out=0 |

---

## 4. fcip_onehot_mux_pld — 独热码选择复用器（参数化类型）

**文件：** `ip/basic/fcip_onehot_mux_pld.sv`

### 参数
| 参数名 | 默认值 | 描述 |
|--------|--------|------|
| REQ_NUM | 4 | 输入通道数 |
| PLD_TYPE | logic | Payload数据类型 |

### 接口
| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| in_sel | input | REQ_NUM | 独热码选择信号 |
| in_pld | input | PLD_TYPE×REQ_NUM | 输入payload数组 |
| out_pld | output | PLD_TYPE | 选中输出 |

### 功能
根据in_sel选择对应in_pld输出，使用OR归约实现。

### 验证用例
| TC | 场景 | 预期 |
|----|------|------|
| 001 | 选择通道0 | 输出通道0数据 |
| 002 | 选择通道N-1 | 输出通道N-1数据 |
| 003 | 自定义PLD_TYPE | 结构体类型正确传递 |

---

## 5. fcip_real_mux_onehot — 独热码数据复用器（转置实现）

**文件：** `ip/basic/fcip_real_mux_onehot.sv`

### 参数
| 参数名 | 默认值 | 描述 |
|--------|--------|------|
| WIDTH | 4 | 输入通道数 |
| PLD_WIDTH | 32 | 数据位宽 |

### 接口
| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| select_onehot | input | WIDTH | 独热码选择 |
| v_pld | input | PLD_WIDTH×WIDTH | 输入数据数组 |
| select_pld | output | PLD_WIDTH | 选中输出 |

### 功能
将输入矩阵转置后与选择信号做AND，再OR归约。避免MUX扇入过大。

---

## 6. fcip_onehot_demux — 独热码解复用器

**文件：** `ip/basic/fcip_onehot_demux.sv`

### 参数
| 参数名 | 默认值 | 描述 |
|--------|--------|------|
| WIDTH | 8 | 输出通道数 |
| PLD_TYPE | logic | Payload类型 |

### 接口
| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| s_vld | input | 1 | 输入valid |
| s_rdy | output | 1 | 输入ready |
| s_pld | input | PLD_TYPE | 输入payload |
| sel_onehot | input | WIDTH | 独热码目标选择 |
| v_m_vld | output | WIDTH | 各输出valid |
| v_m_rdy | input | WIDTH | 各输出ready |
| v_m_pld | output | PLD_TYPE×WIDTH | 各输出payload |

### 功能
根据sel_onehot将输入路由到对应输出通道，带握手信号。

### 验证用例
| TC | 场景 | 预期 |
|----|------|------|
| 001 | sel选择通道0 | 仅通道0有效 |
| 002 | 目标通道反压 | 输入被反压 |
| 003 | Payload广播 | 所有通道pld相同 |
