# FCIP ROB ID DEC Design Specification

## 1. 概述

`fcip_rob_id_dec` 是ROB ID解码器，将二进制索引和使能信号转换为独热使能向量，常用于重排序缓冲(ROB)的条目写使能生成。

**所属分类：** basic  
**文件路径：** `ip/basic/fcip_rob_id_dec.sv`

## 2. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| BIN_WIDTH | integer | 4 | 二进制索引位宽 |
| OH_WIDTH | localparam | 2^BIN_WIDTH | 输出独热向量位宽 |

## 3. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| in_en | input | 1 | 使能信号 |
| in_index | input | BIN_WIDTH | 二进制索引 |
| v_out_en | output | OH_WIDTH | 独热使能向量 |

## 4. 功能

```
v_out_en = {OH_WIDTH{in_en}} & bin2onehot(in_index)
```

## 5. 验证用例

| TC | 场景 | 预期 |
|----|------|------|
| 001 | in_en=1, in_index=3 | v_out_en[3]=1，其余为0 |
| 002 | in_en=0 | v_out_en全0 |
| 003 | 遍历所有索引 | 各位逐一被选中 |
