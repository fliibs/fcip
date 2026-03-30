# FCIP Booth-Wallace Multiplier Design Specification

## 1. 概述

`fcip_booth_wallace_mul` 是一个基于 Booth 编码 + Wallace 树压缩的高性能乘法器。采用 Radix-4 Booth 编码生成部分积，使用 Synopsys DW02_tree 进行 Wallace 树压缩，最后通过加法器得到最终乘积。

**所属分类：** basic  
**文件路径：** `ip/basic/fcip_booth_wallace_mul.sv`

## 2. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| A_WIDTH | integer unsigned | 8 | 被乘数A位宽 |
| B_WIDTH | integer unsigned | 8 | 乘数B位宽 |
| PRODUCT_WIDTH | integer unsigned | 16 | 乘积输出位宽 |

## 3. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 时钟（当前未使用） |
| rst_n | input | 1 | 复位（当前未使用） |
| TC_a | input | 1 | A有符号标志（1=有符号，0=无符号） |
| TC_b | input | 1 | B有符号标志（1=有符号，0=无符号） |
| mul_a | input | A_WIDTH | 被乘数 |
| mul_b | input | B_WIDTH | 乘数 |
| product | output | PRODUCT_WIDTH | 乘积结果 |

## 4. 功能描述

### 4.1 Booth Radix-4 编码
- 将乘数B扩展为 `{符号扩展2bit, B, 1'b0}`
- 每次取3位 `mul_b_reg[2*i+2:2*i]` 进行Booth编码
- 编码结果：0（000/111），+A（001/010），-A（110/101），+2A（011），-2A（100）

### 4.2 部分积生成
- 共生成 B_WIDTH/2+1 个部分积
- 第0个部分积直接移位，后续部分积包含进位修正位（cin）

### 4.3 Wallace 树压缩
- 使用 Synopsys DesignWare `DW02_tree` IP 将所有部分积压缩为两个加数（out0, out1）

### 4.4 最终加法
- `product = (out0 + out1)[PRODUCT_WIDTH-1:0]`

### 4.5 有符号/无符号支持
- TC_a/TC_b 控制A/B的符号扩展方式
- TC=1：符号扩展；TC=0：零扩展

## 5. 依赖
- Synopsys DesignWare `DW02_tree`

## 6. 验证关键点与测试用例

| TC | 场景 | 预期 |
|----|------|------|
| 001 | 无符号 3×5 | product=15 |
| 002 | 有符号 (-3)×5 | product=-15（补码） |
| 003 | 有符号 (-128)×(-128) | product=16384 |
| 004 | 边界：A=0 或 B=0 | product=0 |
| 005 | 最大值无符号 255×255 | product=65025 |
| 006 | 混合：TC_a=1, TC_b=0 | A有符号×B无符号 |
| 007 | 不同位宽 A_WIDTH≠B_WIDTH | 位宽不对称验证 |
