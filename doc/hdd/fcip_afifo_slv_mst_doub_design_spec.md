# FCIP AFIFO SLV DOUB / MST DOUB Design Specification

## 1. 概述

`fcip_afifo_slv_doub` 和 `fcip_afifo_mst_doub` 是双倍数据线宽异步FIFO的写侧和读侧子模块。与标准版本（fcip_afifo_slv/mst）的主要区别在于支持DOUBLE_DATA_WIRE参数控制pld_sync的位宽。

**所属分类：** async_fifo  
**文件路径：**
- `ip/async_fifo/fcip_afifo_slv_doub.sv`
- `ip/async_fifo/fcip_afifo_mst_doub.sv`

## 2. 功能描述

- fcip_afifo_slv_doub：写侧逻辑，增加DOUBLE_DATA_WIRE参数
  - 当DOUBLE_DATA_WIRE=1时，pld_sync宽度为DATA_WIDTH*2+2
  - 当DOUBLE_DATA_WIRE=0时，pld_sync宽度为DATA_WIDTH+1
- fcip_afifo_mst_doub：读侧逻辑，配合处理双倍线宽数据

## 3. 额外参数

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| DOUBLE_DATA_WIRE | integer | 0 | 双倍数据线宽使能 |

其余参数与标准slv/mst版本相同。

## 4. 接口信号

与标准slv/mst版本相同，pld_sync位宽根据DOUBLE_DATA_WIRE动态调整。

## 5. 验证关键点

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | DOUBLE_DATA_WIRE=0回退 | 行为与标准版本一致 |
| TC_002 | DOUBLE_DATA_WIRE=1 | 双倍线宽数据正确传输 |
| TC_003 | 不同DATA_WIDTH配置 | 位宽计算正确 |
