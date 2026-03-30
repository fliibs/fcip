# FCIP AFIFO DOUB Design Specification

## 1. 概述

`fcip_afifo_doub` 是支持双倍数据线宽的异步FIFO顶层模块。通过DOUBLE_DATA_WIRE参数控制CDC传输线宽，可选择使用双倍数据线宽以提高CDC可靠性或支持特殊应用场景。

**所属分类：** async_fifo  
**文件路径：** `ip/async_fifo/fcip_afifo_doub.sv`

## 2. 功能描述

- 功能与`fcip_afifo`基本相同
- 增加DOUBLE_DATA_WIRE参数，控制CDC数据通路使用原始宽度还是双倍宽度
- 内部使用`fcip_afifo_slv_doub`和`fcip_afifo_mst_doub`子模块

## 3. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| FIFO_DEPTH | integer | 16 | FIFO深度 |
| DATA_WIDTH | integer | 16 | 数据位宽 |
| AUTO_CLEAR_EN | integer | 0 | 自动清理使能 |
| THRESHOLD_EN | integer | 0 | 阈值使能 |
| ALMOST_FULL_THRESHOLD | integer | 12 | Almost Full阈值 |
| ALMOST_EMPTY_THRESHOLD | integer | 4 | Almost Empty阈值 |
| SYNC_STAGE | integer | 2 | CDC同步级数 |
| DOUBLE_DATA_WIRE | integer | 1 | 双倍数据线宽使能 |
| VT_TYPE | integer | 1 | 标准单元VT类型 |

## 4. 接口信号

接口与`fcip_afifo`完全相同，参见该模块文档。

## 5. 子模块依赖

| 子模块 | 功能 |
|--------|------|
| `fcip_afifo_slv_doub` | 双倍线宽写侧 |
| `fcip_afifo_mst_doub` | 双倍线宽读侧 |

## 6. 验证关键点

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | DOUBLE_DATA_WIRE=0 | 与标准afifo行为一致 |
| TC_002 | DOUBLE_DATA_WIRE=1 | 双倍线宽模式正常工作 |
| TC_003 | 不同频率比CDC传输 | 数据不丢失不错乱 |
| TC_004 | 满/空状态切换 | 状态信号正确 |
