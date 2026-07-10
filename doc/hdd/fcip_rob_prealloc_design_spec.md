# FCIP ROB PREALLOC Design Specification

## 1. 概述

`fcip_rob_prealloc` 是ROB预分配器，从空闲位向量中选择一个空闲项进行分配。使用`fcip_lead_one`查找第一个空闲位，配合valid-ready握手接口输出分配结果。

**所属分类：** basic  
**文件路径：** `ip/basic/fcip_rob_prealloc.sv`

## 2. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| ROB_ENTRY_NUM | integer | 32 | ROB条目数 |
| ROB_ENTRY_WIDTH | localparam | $clog2(ROB_ENTRY_NUM) | 索引位宽 |

## 3. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| v_in_vld | input | ROB_ENTRY_NUM | 可分配条目位向量（1=可用） |
| v_in_rdy | output | ROB_ENTRY_NUM | 被分配条目（独热，带门控） |
| out_vld | output | 1 | 分配结果valid |
| out_rdy | input | 1 | 分配结果ready |
| out_pld | output | ROB_ENTRY_WIDTH | 分配的条目索引（二进制） |
| out_pld_oh | output | ROB_ENTRY_NUM | 分配的条目索引（独热） |

## 4. 功能

- 使用lead_one从v_in_vld中找到第一个空闲条目
- 通过out_rdy门控分配：仅当下游ready时确认分配
- v_in_rdy反映实际被消耗的条目

## 5. 验证用例

| TC | 场景 | 预期 |
|----|------|------|
| 001 | 多个空闲条目 | 选择最低索引的空闲条目 |
| 002 | 无空闲条目 | out_vld=0 |
| 003 | out_rdy=0 | v_in_rdy全0（不消耗） |
| 004 | 连续分配 | 每次选择不同条目（由外部更新v_in_vld） |
