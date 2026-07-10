# FCIP Memory Model Design Specification

## 1. 概述

本文档涵盖两个仿真用存储模型：
- **`fcip_dpram_model`**：双端口RAM仿真模型（独立读写端口）
- **`fcip_spram_model`**：单端口RAM仿真模型（共享读写端口）

两者均基于SystemVerilog关联数组实现，支持HEX文件加载和调试输出，**仅用于仿真，不可综合**。

**所属分类：** mem_model  
**文件路径：** `ip/mem_model/fcip_dpram_model.sv`, `ip/mem_model/fcip_spram_model.sv`

---

## 2. fcip_dpram_model（双端口RAM模型）

### 2.1 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| ARGPARSE_KEY | string | "HEX" | 运行时参数名（+HEX=path） |
| ALLOW_NO_HEX | integer unsigned | 1 | 允许无HEX文件（1=允许，0=报错退出） |
| ADDR_WIDTH | integer unsigned | 32 | 地址位宽 |
| DATA_WIDTH | integer unsigned | 32 | 数据位宽 |

### 2.2 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 时钟 |
| rd_en | input | 1 | 读使能 |
| rd_addr | input | ADDR_WIDTH | 读地址 |
| rd_data | output | DATA_WIDTH | 读数据（1周期延迟） |
| wr_en | input | 1 | 写使能 |
| wr_bit_en | input | DATA_WIDTH | 写位掩码 |
| wr_addr | input | ADDR_WIDTH | 写地址 |
| wr_data | input | DATA_WIDTH | 写数据 |

### 2.3 功能特性
- **读写独立**：读写可同周期操作不同地址
- **位级掩码写入**：`mem[addr] = (old & ~wr_bit_en) | (new & wr_bit_en)`
- **读延迟**：1个时钟周期（`rd_data` 寄存器输出）
- **写无延迟**：写数据在当前周期立即生效

---

## 3. fcip_spram_model（单端口RAM模型）

### 3.1 参数列表

与fcip_dpram_model相同。

### 3.2 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 时钟 |
| en | input | 1 | 端口使能 |
| addr | input | ADDR_WIDTH | 读写共享地址 |
| rd_data | output | DATA_WIDTH | 读数据（1周期延迟） |
| wr_data | input | DATA_WIDTH | 写数据 |
| wr_bit_en | input | DATA_WIDTH | 写位掩码 |
| wr_en | input | 1 | 写使能（en=1时有效） |

### 3.3 功能特性
- **共享端口**：读写互斥，`wr_en && en` 写入，`en && ~wr_en` 读出
- **位级掩码写入**：与dpram相同
- **读延迟**：1个时钟周期

---

## 4. 共通特性

### 4.1 HEX文件加载
```
初始化时通过 $value$plusargs 解析运行时参数：
  +ARGPARSE_KEY=<hex_file_path>
使用 $readmemh 加载数据
```

### 4.2 调试输出
- `+DEBUG` 运行时参数启用调试打印
- 初始化时打印前10行数据
- 运行时打印每次读写的地址和数据

### 4.3 关联数组存储
- 使用 `logic_data memory[logic_addr]` 关联数组
- 首次读取未初始化地址返回全0并写入全0
- 内存使用按需分配，适合大地址空间仿真

## 5. 验证关键点与测试用例

| TC | 场景 | 预期 |
|----|------|------|
| 001 | HEX文件加载 | 初始数据正确 |
| 002 | 读写基本功能 | 写后读取正确 |
| 003 | 位掩码写入 | 仅被掩码选中的位被修改 |
| 004 | 未初始化地址读取 | 返回全0 |
| 005 | SPRAM读写互斥 | en=1, wr_en=1时仅写入 |
| 006 | DPRAM同时读写 | 不同地址可同时操作 |
| 007 | ALLOW_NO_HEX=0无文件 | 报错退出 |
| 008 | DEBUG模式打印 | 读写操作均有打印 |
