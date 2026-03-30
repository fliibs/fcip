# FCIP TREE PLRU COMB Design Specification

## 1. 概述

`fcip_tree_plru_comb` 是PLRU树形矩阵的纯组合逻辑版本，提供节点更新逻辑和矩阵转换，不包含寄存器。可用于需要在一个周期内完成PLRU查询和更新的场景。

**所属分类：** arbiter  
**文件路径：** `ip/arbiter/fcip_tree_plru_comb.sv`

## 2. 功能描述

- 输入当前树节点状态和分配信号
- 输出更新后的节点状态（update_node）
- 输出当前状态对应的优先级矩阵（vv_matrix）

## 3. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| WIDTH | integer | 4 | 条目数量 |
| DEPTH | integer | $clog2(WIDTH) | 树深度 |

## 4. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| alloc_en | input | 1 | 分配使能 |
| node[WIDTH-2:0] | input | WIDTH-1 | 当前树节点状态 |
| v_alloc[WIDTH-1:0] | input | WIDTH | 被分配条目 |
| update_node[WIDTH-2:0] | output | WIDTH-1 | 更新后树节点状态 |
| vv_matrix[WIDTH-1:0] | output | WIDTH×WIDTH | 优先级矩阵 |

## 5. 验证关键点

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | alloc_en=0 | update_node = node（不变） |
| TC_002 | alloc_en=1，分配不同条目 | 节点正确翻转 |
| TC_003 | 矩阵与节点一致性 | 矩阵正确反映节点状态 |
| TC_004 | 反对称性 | vv_matrix[i][j] = ~vv_matrix[j][i] |
