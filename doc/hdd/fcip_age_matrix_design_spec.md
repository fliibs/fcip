# FCIP AGE MATRIX Design Specification

## 1. 概述

`fcip_age_matrix` 是年龄矩阵生成器，维护N个条目之间的年龄优先关系。新分配的条目为最年轻，可用于实现最老优先（Oldest First）仲裁。

**所属分类：** arbiter  
**文件路径：** `ip/arbiter/fcip_age_matrix.sv`

## 2. 功能描述

- 维护WIDTH×WIDTH的上三角矩阵，vv_matrix[i][j]=1表示i比j更老
- 分配新条目时（alloc_en & v_alloc），被分配条目变为最年轻
- 矩阵自动维护反对称性：vv_matrix[i][j] = ~vv_matrix[j][i]
- 对角线始终为0

## 3. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| WIDTH | integer | 4 | 条目数量 |

## 4. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 时钟 |
| rst_n | input | 1 | 异步低有效复位 |
| alloc_en | input | 1 | 分配使能 |
| v_alloc[WIDTH-1:0] | input | WIDTH | 被分配条目（独热码） |
| vv_matrix[WIDTH-1:0] | output | WIDTH×WIDTH | 年龄矩阵 |

## 5. 验证关键点

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | 依次分配0,1,2,3 | 矩阵正确反映分配顺序 |
| TC_002 | 重复分配同一条目 | 该条目变为最年轻 |
| TC_003 | alloc_en=0 | 矩阵保持不变 |
| TC_004 | 复位 | 矩阵全0 |
| TC_005 | 矩阵反对称性 | vv_matrix[i][j] = ~vv_matrix[j][i]（对i≠j） |
| TC_006 | 配合fcip_arb_matrix | 最老条目被优先grant |
