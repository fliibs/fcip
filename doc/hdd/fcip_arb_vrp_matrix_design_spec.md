# FCIP ARB VRP MATRIX Design Specification

## 1. 概述

`fcip_arb_vrp_matrix` 是一个基于外部优先级矩阵的仲裁器模块，带payload数据通路和valid-ready握手接口。与`fcip_arb_vrp`不同，该模块的优先级矩阵由外部提供，适合需要自定义矩阵更新策略的场景。

**所属分类：** arbiter  
**文件路径：** `ip/arbiter/fcip_arb_vrp_matrix.sv`

## 2. 功能描述

- 接受外部提供的优先级矩阵vv_matrix
- 根据矩阵和输入valid信号生成独热grant
- 通过onehot mux选择被grant端口的payload输出
- v_rdy_s考虑rdy_m反压

## 3. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| WIDTH | integer | 4 | 仲裁输入端口数量 |
| PLD_WIDTH | integer | 32 | Payload数据位宽 |

## 4. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 时钟信号 |
| rst_n | input | 1 | 异步低有效复位 |
| vv_matrix[WIDTH-1:0] | input | WIDTH×WIDTH | 外部优先级矩阵 |
| v_vld_s[WIDTH-1:0] | input | WIDTH | 各输入端口valid |
| v_rdy_s[WIDTH-1:0] | output | WIDTH | 各输入端口ready |
| v_pld_s[WIDTH-1:0] | input | PLD_WIDTH×WIDTH | 各输入端口payload |
| vld_m | output | 1 | 输出valid |
| rdy_m | input | 1 | 输出ready |
| pld_m | output | PLD_WIDTH | 输出payload |

## 5. 工作原理

- 仲裁判决：`select_onehot[i] = (~|(v_vld_s & vv_matrix[i])) && v_vld_s[i]`
  - 当请求i有效且没有比它更高优先级的有效请求时，授予grant
- Ready信号：`v_rdy_s[i] = select_onehot[i] && rdy_m && v_vld_s[i]`
- 输出valid：`vld_m = |v_vld_s`

## 6. 子模块依赖

| 子模块 | 功能 |
|--------|------|
| `fcip_real_mux_onehot` | Payload选择复用器 |

## 7. 验证关键点

### 功能验证
1. 不同矩阵配置下的仲裁正确性
2. 动态矩阵更新后仲裁行为变化
3. 反压场景下数据完整性

### 关键测试用例

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | 固定矩阵，多端口请求 | 矩阵优先级高的端口被服务 |
| TC_002 | 矩阵动态变化 | 仲裁跟随矩阵变化 |
| TC_003 | 单端口请求 | 立即grant |
| TC_004 | master反压 | 数据不丢失 |
| TC_005 | Payload通路完整性 | 输出数据与grant端口匹配 |
