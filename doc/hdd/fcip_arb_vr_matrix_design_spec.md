# FCIP ARB VR MATRIX Design Specification

## 1. 概述

`fcip_arb_vr_matrix` 是一个基于外部优先级矩阵的轻量级仲裁器，仅提供valid-ready握手接口，不包含payload数据通路。适用于仅需仲裁控制信号而不需要数据选择的场景。

**所属分类：** arbiter  
**文件路径：** `ip/arbiter/fcip_arb_vr_matrix.sv`

## 2. 功能描述

- 接受外部优先级矩阵和多路valid信号
- 生成独热ready信号，同时考虑rdy_m反压
- 输出合并的vld_m信号

## 3. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| WIDTH | integer | 4 | 仲裁输入端口数量 |

## 4. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| vv_matrix[WIDTH-1:0] | input | WIDTH×WIDTH | 外部优先级矩阵 |
| v_vld_s[WIDTH-1:0] | input | WIDTH | 各输入端口valid |
| v_rdy_s[WIDTH-1:0] | output | WIDTH | 各输入端口ready |
| vld_m | output | 1 | 输出valid |
| rdy_m | input | 1 | 输出ready |

## 5. 工作原理

- 仲裁判决：`select_onehot[i] = (~|(v_vld_s & vv_matrix[i])) && (rdy_m && v_vld_s[i])`
- `vld_m = |v_vld_s`
- `v_rdy_s = select_onehot`

## 6. 验证关键点

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | 多端口同时请求 | 仅最高优先级端口ready |
| TC_002 | rdy_m撤销 | 所有v_rdy_s为0 |
| TC_003 | 矩阵值全零 | 低索引端口优先 |
| TC_004 | 单端口请求 | 对应端口立即ready |
