# FCIP MTX GEN PLRU TREE Design Specification

## 1. 概述

`fcip_mtx_gen_plru_tree` 是基于二叉树的Pseudo-LRU矩阵生成器。使用WIDTH-1个树节点维护PLRU状态，并将其转换为WIDTH×WIDTH的优先级矩阵输出。

**所属分类：** arbiter  
**文件路径：** `ip/arbiter/fcip_mtx_gen_plru_tree.sv`

## 2. 功能描述

- 使用二叉树（DEPTH = log2(WIDTH)层）维护PLRU替换策略
- 每个树节点记录左/右子树的使用状态
- 分配时更新树节点方向指针
- 将树节点状态转换为WIDTH×WIDTH矩阵，供fcip_arb_matrix使用

## 3. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| WIDTH | integer | 4 | 条目数量（需为2的幂） |
| DEPTH | integer | $clog2(WIDTH) | 树深度（自动计算） |

## 4. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 时钟 |
| rst_n | input | 1 | 异步低有效复位 |
| alloc_en | input | 1 | 分配使能 |
| v_alloc[WIDTH-1:0] | input | WIDTH | 被分配条目 |
| vv_matrix[WIDTH-1:0] | output | WIDTH×WIDTH | PLRU优先级矩阵 |

## 5. PLRU树结构（WIDTH=4示例）

```
        node[0]
       /       \
    node[1]   node[2]
    /    \    /    \
  [0]   [1] [2]   [3]
```

- node[i]=0：左子树更老（应被替换）
- node[i]=1：右子树更老（应被替换）

## 6. 验证关键点

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | 依次访问0,1,2,3 | 节点状态正确更新 |
| TC_002 | 复位后状态 | 所有节点为0 |
| TC_003 | 重复访问同一条目 | 其他条目优先级升高 |
| TC_004 | 矩阵反对称性 | vv_matrix[i][j] = ~vv_matrix[j][i] |
| TC_005 | WIDTH=8 | 3层树结构正确工作 |
| TC_006 | 配合arb_matrix | PLRU选择的条目被grant |
