# FCIP GRANT GEN RR Design Specification

## 1. 概述

`fcip_grant_gen_rr` 是基于掩码的Round-Robin轮询grant生成器。通过维护优先级寄存器实现公平的轮询仲裁。

**所属分类：** arbiter  
**文件路径：** `ip/arbiter/fcip_grant_gen_rr.sv`

## 2. 功能描述

- 使用掩码机制实现Round-Robin仲裁
- 维护prio_reg优先级寄存器，记录上次grant之后的优先级掩码
- 掩码通道（masked channel）和非掩码通道（unmasked channel）双通道仲裁
- 掩码通道有效时优先使用，否则使用非掩码通道

## 3. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| WIDTH | integer | 4 | 端口数量 |

## 4. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 时钟 |
| rst_n | input | 1 | 异步低有效复位 |
| v_vld[WIDTH-1:0] | input | WIDTH | 请求有效向量 |
| v_grant[WIDTH-1:0] | output | WIDTH | 独热grant输出 |

## 5. 工作原理

1. `vld_mask = v_vld & prio_reg`：用优先级掩码过滤请求
2. 对掩码后的请求做固定优先级仲裁（低位优先）→ mask_grant
3. 对原始请求做固定优先级仲裁 → unmask_grant
4. 有掩码请求时选mask_grant，否则选unmask_grant
5. 更新prio_reg：将被grant位之后的位设为高优先级

## 6. 验证关键点

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | 所有端口持续请求 | 依次轮询服务0→1→2→3→0... |
| TC_002 | 部分端口请求 | 在有效端口间轮询 |
| TC_003 | 复位后首次仲裁 | prio_reg全1，从端口0开始 |
| TC_004 | 间歇性请求 | RR指针正确记忆和恢复 |
| TC_005 | 单端口持续请求 | 始终grant该端口 |
| TC_006 | Grant独热性 | 任意时刻最多1位为1 |
