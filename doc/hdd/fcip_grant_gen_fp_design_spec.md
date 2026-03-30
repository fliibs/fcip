# FCIP GRANT GEN FP Design Specification

## 1. 概述

`fcip_grant_gen_fp` 是固定优先级grant生成器，支持两级优先级分组。组内按照低位优先的策略仲裁。

**所属分类：** arbiter  
**文件路径：** `ip/arbiter/fcip_grant_gen_fp.sv`

## 2. 功能描述

- 将请求分为高优先级组（v_priority[i]=1）和低优先级组（v_priority[i]=0）
- 高优先级组内按索引低位优先（bit 0最高）
- 有高优先级请求时忽略低优先级组
- 纯组合逻辑

## 3. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| WIDTH | integer | 4 | 端口数量 |

## 4. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| v_vld[WIDTH-1:0] | input | WIDTH | 请求有效向量 |
| v_priority[WIDTH-1:0] | input | WIDTH | 优先级标记（1=高优先级） |
| v_grant[WIDTH-1:0] | output | WIDTH | 独热grant输出 |

## 5. 验证关键点

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | 仅高优先级组有请求 | 最低索引高优先级端口被grant |
| TC_002 | 仅低优先级组有请求 | 最低索引低优先级端口被grant |
| TC_003 | 两组均有请求 | 高优先级组获胜 |
| TC_004 | 所有端口为高优先级 | 端口0被grant |
| TC_005 | 无请求 | v_grant全0 |
