# FCIP AGE MATRIX LIST Design Specification

## 1. 概述

`fcip_age_matrix_list` 是支持每周期多个分配操作的年龄矩阵生成器。通过级联多个分配阶段，一个周期内可处理LIST_DEPTH个分配请求。

**所属分类：** arbiter  
**文件路径：** `ip/arbiter/fcip_age_matrix_list.sv`

## 2. 功能描述

- 支持每周期最多LIST_DEPTH个条目同时分配
- 分配操作按列表顺序依次应用，后面的分配比前面的更年轻
- 维护WIDTH×WIDTH的年龄矩阵

## 3. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| WIDTH | integer | 4 | 条目数量 |
| LIST_DEPTH | integer | 2 | 每周期最大分配数 |

## 4. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 时钟 |
| rst_n | input | 1 | 异步低有效复位 |
| v_alloc_en[LIST_DEPTH-1:0] | input | LIST_DEPTH | 各分配通道使能 |
| v_alloc[LIST_DEPTH-1:0] | input | WIDTH×LIST_DEPTH | 各通道分配向量 |
| vv_matrix[WIDTH-1:0] | output | WIDTH×WIDTH | 年龄矩阵 |

## 5. 验证关键点

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | 同时分配2个条目 | 后分配的更年轻 |
| TC_002 | 仅启用部分分配通道 | 未启用通道不影响矩阵 |
| TC_003 | 连续多周期分配 | 年龄顺序正确维护 |
| TC_004 | 复位 | 矩阵全0 |
| TC_005 | 级联正确性 | k=0基于当前矩阵，k>0基于k-1的结果 |
