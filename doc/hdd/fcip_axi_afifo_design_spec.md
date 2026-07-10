# FCIP AXI AFIFO Design Specification

## 1. 概述

`fcip_axi_afifo` 是AXI协议异步FIFO，支持完整AXI4总线的五个通道（AW/W/B/AR/R）跨时钟域传输。每个通道独立配置FIFO深度。

**所属分类：** async_fifo  
**文件路径：** `ip/async_fifo/fcip_axi_afifo/fcip_axi_afifo.sv`

## 2. 功能描述

- 完整AXI4协议五通道CDC传输
- 写方向：AW(地址)、W(数据) 从slave时钟域→master时钟域
- 读方向：AR(地址) 从slave时钟域→master时钟域
- 响应方向：B(写响应)、R(读响应) 从master时钟域→slave时钟域
- 每个通道独立的FIFO深度配置
- 低功耗控制接口（stall/clear/full_zero）

## 3. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| ADDR_WIDTH | integer | 32 | 地址位宽 |
| DATA_WIDTH | integer | 128 | 数据位宽 |
| AWID_WIDTH | integer | 8 | 写地址ID位宽 |
| ARID_WIDTH | integer | 8 | 读地址ID位宽 |
| AWLEN_WIDTH | integer | 8 | 写突发长度位宽 |
| ARLEN_WIDTH | integer | 8 | 读突发长度位宽 |
| AWUSER_WIDTH | integer | 1 | AW用户信号位宽 |
| WUSER_WIDTH | integer | 1 | W用户信号位宽 |
| BUSER_WIDTH | integer | 1 | B用户信号位宽 |
| ARUSER_WIDTH | integer | 1 | AR用户信号位宽 |
| RUSER_WIDTH | integer | 1 | R用户信号位宽 |
| AW_FIFO_DEPTH | integer | 8 | AW通道FIFO深度 |
| W_FIFO_DEPTH | integer | 8 | W通道FIFO深度 |
| B_FIFO_DEPTH | integer | 8 | B通道FIFO深度 |
| AR_FIFO_DEPTH | integer | 8 | AR通道FIFO深度 |
| R_FIFO_DEPTH | integer | 8 | R通道FIFO深度 |
| SYNC_STAGE | integer | 2 | CDC同步级数 |
| AUTO_CLEAR_EN | integer | 1 | 自动清理使能 |
| VT_TYPE | integer | 1 | 标准单元VT类型 |

## 4. 接口信号

### Slave侧（slave时钟域，clk_s/rst_s_n）
- 完整AXI4 slave接口：AW/W/B/AR/R五通道
- 低功耗控制：axi_fifo_slv_stall, axi_fifo_slv_clear, axi_fifo_slv_full_zero

### Master侧（master时钟域，clk_m/rst_m_n）
- 完整AXI4 master接口：AW/W/B/AR/R五通道
- 低功耗控制：axi_fifo_mst_stall, axi_fifo_mst_clear, axi_fifo_mst_full_zero

## 5. 内部架构

```
  slave clock domain (clk_s)              master clock domain (clk_m)
  ┌──────────────────────┐                ┌──────────────────────┐
  │  fcip_axi_afifo_slv  │ ──AW_CDC──►   │  fcip_axi_afifo_mst  │
  │                      │ ──W_CDC───►   │                      │
  │  AW/W/AR write side  │ ──AR_CDC──►   │  AW/W/AR read side   │
  │  B/R read side       │ ◄──B_CDC───   │  B/R write side      │
  │                      │ ◄──R_CDC───   │                      │
  └──────────────────────┘                └──────────────────────┘
```

## 6. 子模块依赖

| 子模块 | 功能 |
|--------|------|
| `fcip_axi_afifo_slv` | AXI slave侧逻辑（5通道写/读） |
| `fcip_axi_afifo_mst` | AXI master侧逻辑（5通道读/写） |
| `fcip_afifo_slv` | 基础异步FIFO写侧（每通道一个实例） |
| `fcip_afifo_mst` | 基础异步FIFO读侧（每通道一个实例） |

## 7. 验证关键点

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | 单笔AXI写事务 | AW/W/B通道数据正确传输 |
| TC_002 | 单笔AXI读事务 | AR/R通道数据正确传输 |
| TC_003 | 突发传输（burst） | wlast/rlast正确传递 |
| TC_004 | 多个未完成事务 | ID排序正确 |
| TC_005 | AW/W通道FIFO满 | 正确反压slave |
| TC_006 | 不同频率比 | 五通道数据均正确 |
| TC_007 | 低功耗stall/clear | 功能正确 |
| TC_008 | full_zero恢复验证 | 完全排空后full_zero断言 |
| TC_009 | 所有AXI信号位宽参数化 | 不同配置下正确工作 |
| TC_010 | 协议合规性 | AXI4协议要求（ordering等）满足 |
