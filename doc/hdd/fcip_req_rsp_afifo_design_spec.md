# FCIP REQ RSP AFIFO Design Specification

## 1. 概述

`fcip_req_rsp_afifo` 是Request-Response双向通道异步FIFO，支持请求通道和响应通道的双向跨时钟域传输。适用于带有请求-响应模式的总线桥接场景。

**所属分类：** async_fifo  
**文件路径：** `ip/async_fifo/fcip_req_rsp_afifo.sv`

## 2. 功能描述

- 请求通道（req）：slave侧写入→master侧读出
- 响应通道（rsp）：master侧写入→slave侧读出
- 每个通道支持valid/ready/payload/last信号
- 两个方向共享同一时钟域分割

## 3. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| SYNC_STAGE | integer | 3 | CDC同步级数 |
| FIFO_DEPTH | integer | 16 | 各通道FIFO深度 |
| AUTO_CLEAR_EN | integer | 1 | 自动清理使能 |
| REQ_WIDTH | integer | 32 | 请求通道数据位宽 |
| RSP_WIDTH | integer | 32 | 响应通道数据位宽 |
| VT_TYPE | integer | 1 | 标准单元VT类型 |

## 4. 接口信号

### Slave侧
| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | slave时钟 |
| rst_n | input | 1 | slave复位 |
| slv_req_s_vld/rdy/pld/last | I/O | - | 请求写入接口 |
| slv_rsp_m_vld/rdy/pld/last | O/I | - | 响应读出接口 |

### Master侧
| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| mst_req_s_vld/rdy/pld/last | O/I | - | 请求读出接口 |
| mst_rsp_m_vld/rdy/pld/last | I/O | - | 响应写入接口 |

## 5. 子模块依赖

| 子模块 | 功能 |
|--------|------|
| `fcip_req_rsp_afifo_slv` | Slave侧逻辑 |
| `fcip_req_rsp_afifo_mst` | Master侧逻辑 |
| `fcip_afifo_slv` | 基础异步FIFO写侧 |
| `fcip_afifo_mst` | 基础异步FIFO读侧 |

## 6. 验证关键点

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | 单请求-单响应事务 | 请求和响应数据/last正确 |
| TC_002 | 连续请求 | 所有请求按序传输 |
| TC_003 | 请求满反压 | slave请求正确反压 |
| TC_004 | 响应满反压 | master响应正确反压 |
| TC_005 | 不同REQ_WIDTH/RSP_WIDTH | 位宽参数化正确 |
| TC_006 | last信号传递 | 事务边界正确标记 |
