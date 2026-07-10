# FCIP ARB MATRIX Design Specification

## 1. 概述

`fcip_arb_matrix` 是矩阵仲裁的核心组合逻辑模块，根据优先级矩阵和请求向量生成独热grant输出。该模块是纯组合逻辑，无寄存器。

**所属分类：** arbiter  
**文件路径：** `ip/arbiter/fcip_arb_matrix.sv`

## 2. 功能描述

- 根据输入的优先级矩阵vv_matrix和请求向量v_vld，选出最高优先级的有效请求
- 输出独热grant信号v_grant

## 3. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| WIDTH | integer | 4 | 仲裁端口数量 |

## 4. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| vv_matrix[WIDTH-1:0] | input | WIDTH×WIDTH | 优先级矩阵 |
| v_vld[WIDTH-1:0] | input | WIDTH | 请求有效向量 |
| v_grant[WIDTH-1:0] | output | WIDTH | 独热grant输出 |

## 5. 工作原理

对于每个端口i：
```
v_grant[i] = (~|(v_vld & vv_matrix[i])) && v_vld[i]
```

即：端口i获得grant当且仅当：
1. 端口i有有效请求（v_vld[i]=1）
2. 在所有有效请求中，没有比端口i优先级更高的请求（通过矩阵行比较）

## 6. 验证关键点

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | 所有端口请求，不同矩阵 | 最高优先级端口获grant |
| TC_002 | 单端口有效 | 该端口获grant |
| TC_003 | 无有效请求 | v_grant全0 |
| TC_004 | Grant独热性检查 | 任意时刻最多一个1 |
| TC_005 | 矩阵对称性错误 | 确认不影响独热性 |
