# FCIP FIX ARB Design Specification

## 1. 概述

`fcip_fix_arb` 是一个双输入固定优先级仲裁器，priority端口具有更高优先级。使用参数化payload类型，支持任意数据结构。

**所属分类：** arbiter  
**文件路径：** `ip/arbiter/fcip_fix_arb.sv`

## 2. 功能描述

- 两个输入端口：priority端口（高优先级）和普通端口（低优先级）
- 当priority端口有请求时，优先服务priority端口
- 纯组合逻辑实现，无流水线延迟

## 3. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| PLD_TYPE | type | logic | Payload数据类型 |

## 4. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 时钟（预留） |
| rst_n | input | 1 | 复位（预留） |
| s_vld_priority | input | 1 | 高优先级输入valid |
| s_rdy_priority | output | 1 | 高优先级输入ready |
| s_pld_priority | input | PLD_TYPE | 高优先级输入payload |
| s_vld | input | 1 | 低优先级输入valid |
| s_rdy | output | 1 | 低优先级输入ready |
| s_pld | input | PLD_TYPE | 低优先级输入payload |
| m_vld | output | 1 | 输出valid |
| m_rdy | input | 1 | 输出ready |
| m_pld | output | PLD_TYPE | 输出payload |

## 5. 工作原理

```
m_vld          = s_vld_priority | s_vld
s_rdy_priority = s_vld_priority ? m_rdy : 1'b0
s_rdy          = s_vld_priority ? 1'b0  : m_rdy
m_pld          = s_vld_priority ? s_pld_priority : s_pld
```

## 6. 验证关键点

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | 仅priority端口请求 | priority端口被服务 |
| TC_002 | 仅普通端口请求 | 普通端口被服务 |
| TC_003 | 两端口同时请求 | priority端口被服务，普通端口未ready |
| TC_004 | 反压场景 | m_rdy=0时两端口均未ready |
| TC_005 | Payload类型参数化验证 | 不同PLD_TYPE下数据正确传递 |
