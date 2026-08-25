# FCIP ECC Codec HDD（硬件设计文档）

## 1. 概述

FCIP ECC codec 基于扩展 Hamming SECDED 编码，实现单比特错误纠正和双比特错误检测。模块支持组合解码、一级流水解码、双路解码结果状态比较，以及仿真环境下的错误注入。

- **所属分类：** `ecc_codec`
- **RTL 目录：** `ip/ecc_codec/`
- **文件清单：** `vc/ecc_codec.f`、`vc/ring_err_injc.f`

本文档覆盖以下模块：

| 模块 | 文件 | 功能 |
|------|------|------|
| `fcip_ecc_enc` | `ip/ecc_codec/fcip_ecc_enc.sv` | 组合 SECDED 编码 |
| `fcip_ecc_dec` | `ip/ecc_codec/fcip_ecc_dec.sv` | 组合 SECDED 解码和单比特纠错 |
| `fcip_ecc_dec_pipe` | `ip/ecc_codec/fcip_ecc_dec_pipe.sv` | 一级流水 SECDED 解码 |
| `fcip_ecc_dec_dcls` | `ip/ecc_codec/fcip_ecc_dec_dcls.sv` | 双路组合解码和错误状态比较 |
| `fcip_ecc_dec_dcls_pipe` | `ip/ecc_codec/fcip_ecc_dec_dcls_pipe.sv` | 双路一级流水解码和错误状态比较 |
| `ecc_enc_inject_sim` | `ip/ecc_codec/ring_err_injc/ecc_enc_inject_sim.sv` | 编码数据仿真注错 |
| `ecc_dec_inject_sim` | `ip/ecc_codec/ring_err_injc/ecc_dec_inject_sim.sv` | 双路 decoder 输入仿真注错 |

## 2. 功能列表

- 对 `DATA_WIDTH` 位原始数据生成 Hamming check bits 和 1 位 overall parity。
- 检测并纠正码字中的单比特错误。
- 检测码字中的双比特错误，双比特错误不可纠正。
- 提供组合 decoder 和一级流水 decoder。
- 提供双路 decoder 结构，比较两路 `sb_err` 和 `db_err` 状态。
- 通过 `DFV_FUSA` 和注错宏支持仿真错误注入。
- 所有功能均位于单一时钟域；组合模块不使用时钟和复位。

## 3. ECC 编码定义

### 3.1 参数和派生参数

所有 encoder 和 decoder 使用相同的参数计算：

```systemverilog
CODE_WIDTH =
    ($clog2(DATA_WIDTH) + DATA_WIDTH + 1 <= 2**$clog2(DATA_WIDTH))
    ? $clog2(DATA_WIDTH)
    : $clog2(DATA_WIDTH) + 1;

TOTAL_WIDTH = DATA_WIDTH + CODE_WIDTH + 1;
```

| 参数 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `DATA_WIDTH` | `integer unsigned` | 1024 | 原始数据位宽 |
| `CODE_WIDTH` | `integer unsigned` | 由 `DATA_WIDTH` 计算 | Hamming check bits 数量 |
| `TOTAL_WIDTH` | `integer unsigned` | `DATA_WIDTH + CODE_WIDTH + 1` | 完整 SECDED 码字位宽 |
| `CODE_WIDTH_OH` | `integer unsigned` | `2**CODE_WIDTH` | syndrome 独热展开位宽，仅 decoder 使用 |

`CODE_WIDTH` 满足 Hamming check bits 对原始数据位和 check bits 本身的定位要求。额外的 1 位用于 overall parity，以区分单比特错误和双比特错误。

### 3.2 码字格式

`encode_data` 的物理位域定义如下：

```text
高位                                                低位
+------------------------+----------------------+--------+
| data[DATA_WIDTH-1:0]   | check_bits           | parity |
+------------------------+----------------------+--------+
 TOTAL_WIDTH-1       CODE_WIDTH+1  CODE_WIDTH:1      0
```

等价 RTL 表达式为：

```systemverilog
encode_data = {data, check_bits, parity_bit};
```

其中：

- `data` 为原始数据。
- `check_bits` 为 Hamming check bits。
- `parity_bit` 为整个 `{data, check_bits}` 的 overall parity。

### 3.3 Hamming 虚拟位置

编码和解码逻辑使用从 1 到 `TOTAL_WIDTH-1` 的虚拟 Hamming 位置：

- 位置为 2 的整数次幂时，该位置为 check bit 位置。
- 其余位置按低位到高位顺序映射原始数据。
- overall parity 不参与虚拟位置编号，固定存放于 `encode_data[0]`。

对第 `i` 个 check bit，所有满足 `position & (2**i) != 0` 的数据位置参与异或计算。

## 4. 总体架构

### 4.1 基础 encoder 和 decoder

```text
                  +----------------+
data ------------>| fcip_ecc_enc   |----> encode_data
                  +----------------+

                  +----------------+
encode_data ----->| fcip_ecc_dec   |----> data
                  |                |----> sb_err
                  |                |----> db_err
                  +----------------+
```

### 4.2 双路 DCLS decoder

```text
                             +----------------+    data_1 -----> data
encode_data --> [注错选择] -->| ECC decoder 1 |---- sb_err_1 --> sb_err
                 |           +----------------+---- db_err_1 --> db_err
                 |
                 |           +----------------+
                 +---------->| ECC decoder 2 |---- sb_err_2 --+
                             +----------------+---- db_err_2 --+--> comp_err
```

正常功能模式下，两路 decoder 接收相同的 `encode_data`。`DFV_FUSA` 模式下，仿真注错模块可以改变其中一路或两路 decoder 的输入。

`data`、`sb_err` 和 `db_err` 固定取 decoder 1 的结果。`comp_err` 仅比较两路错误状态，不比较 `data_1` 和 `data_2`。

## 5. 模块详细设计

### 5.1 `fcip_ecc_enc`

#### 5.1.1 接口

| 信号 | 方向 | 位宽 | 描述 |
|------|------|------|------|
| `data` | 输入 | `DATA_WIDTH` | 原始数据 |
| `encode_data` | 输出 | `TOTAL_WIDTH` | SECDED 编码结果 |

#### 5.1.2 工作过程

1. 将 `data` 映射到虚拟 Hamming 非 check bit 位置。
2. 每个 `check_bits[i]` 对对应位置集合进行异或归约。
3. `parity_bit` 对 `{data, check_bits}` 进行异或归约。
4. 按 `{data, check_bits, parity_bit}` 形成输出码字。

该模块为纯组合逻辑，没有时钟、复位和握手接口。

### 5.2 `fcip_ecc_dec`

#### 5.2.1 接口

| 信号 | 方向 | 位宽 | 描述 |
|------|------|------|------|
| `encode_data` | 输入 | `TOTAL_WIDTH` | 待解码 SECDED 码字 |
| `data` | 输出 | `DATA_WIDTH` | 纠错后的数据；`db_err=1` 时无有效性保证 |
| `sb_err` | 输出 | 1 | 单比特错误指示 |
| `db_err` | 输出 | 1 | 双比特错误或非法 syndrome 指示 |

#### 5.2.2 Syndrome 计算

decoder 从 `encode_data` 拆分出 `enc_data`、`enc_check_bits` 和 `enc_parity_bit`。按照 encoder 相同的虚拟位置映射重新计算 check bits：

```systemverilog
check_bits_rst = dec_check_bits ^ enc_check_bits;
dec_parity_bit = ^encode_data;
```

`check_bits_rst` 为 syndrome，表示检测到的错误位置。`dec_parity_bit` 为完整码字的 overall parity 检查结果。

#### 5.2.3 错误判定

| `dec_parity_bit` | `check_bits_rst` | `sb_err` | `db_err` | 数据处理 |
|------------------|------------------|----------|----------|----------|
| 0 | 0 | 0 | 0 | 无错误，直接输出 |
| 1 | 0 | 1 | 0 | overall parity 位错误，数据不变 |
| 1 | `1..TOTAL_WIDTH-1` | 1 | 0 | 单比特错误，纠正对应位置 |
| 0 | 非 0 | 0 | 1 | 双比特错误，不保证输出数据有效 |
| 任意值 | `> TOTAL_WIDTH-1` | 0 | 1 | 非法 syndrome，不保证输出数据有效 |

RTL 判定表达式为：

```systemverilog
sb_err =  dec_parity_bit && (check_bits_rst <= TOTAL_WIDTH-1);
db_err = (~dec_parity_bit && (|check_bits_rst))
         || (check_bits_rst > TOTAL_WIDTH-1);
```

#### 5.2.4 单比特纠错

`fcip_bin2onehot` 将 syndrome 转换为独热纠错掩码。纠错掩码与虚拟 Hamming 数据异或后，重新提取非 check bit 位置形成 `data`。

当错误位置为 check bit 或 overall parity 位时，原始数据保持不变。当 `db_err=1` 时，decoder 仍会执行当前组合纠错路径，因此使用方必须以 `db_err` 判断 `data` 是否有效。

### 5.3 `fcip_ecc_dec_pipe`

#### 5.3.1 接口

| 信号 | 方向 | 位宽 | 描述 |
|------|------|------|------|
| `clk` | 输入 | 1 | 工作时钟 |
| `rst_n` | 输入 | 1 | 异步低有效复位 |
| `encode_data` | 输入 | `TOTAL_WIDTH` | 待解码 SECDED 码字 |
| `data` | 输出 | `DATA_WIDTH` | 纠错后的数据 |
| `sb_err` | 输出 | 1 | 单比特错误指示 |
| `db_err` | 输出 | 1 | 双比特错误或非法 syndrome 指示 |

#### 5.3.2 流水线划分

```text
encode_data
    |
    v
[一级入口寄存器: encode_data_r]
    |
    v
[数据展开、syndrome 计算、错误判定、独热展开和数据纠正]
    |
    +----> data/sb_err/db_err
```

该模块在 decoder 入口寄存完整的 `encode_data`，再将寄存结果送入组合 `fcip_ecc_dec`。模块相对输入增加 1 个时钟周期延迟，且没有 `vld` 信号，集成模块必须自行将数据有效信号延迟相同周期。

`rst_n=0` 时，流水寄存器清零，`data`、`sb_err` 和 `db_err` 收敛为 0。

### 5.4 `fcip_ecc_dec_dcls`

#### 5.4.1 接口

| 信号 | 方向 | 位宽 | 描述 |
|------|------|------|------|
| `encode_data` | 输入 | `TOTAL_WIDTH` | 两路 decoder 的源 SECDED 码字 |
| `data` | 输出 | `DATA_WIDTH` | decoder 1 的纠错数据 |
| `sb_err` | 输出 | 1 | decoder 1 的单比特错误指示 |
| `db_err` | 输出 | 1 | decoder 1 的双比特错误指示 |
| `comp_err` | 输出 | 1 | 两路错误状态不一致指示 |

#### 5.4.2 比较范围

```systemverilog
comp_err = (sb_err_1 ^ sb_err_2) || (db_err_1 ^ db_err_2);
```

`comp_err` 的覆盖范围仅包括 `sb_err` 和 `db_err`。当前实现不比较 `data_1` 和 `data_2`，因此两路数据不一致但错误状态一致时，`comp_err` 不会置位。

该模块为组合逻辑，不增加时钟周期延迟。

### 5.5 `fcip_ecc_dec_dcls_pipe`

#### 5.5.1 接口

| 信号 | 方向 | 位宽 | 描述 |
|------|------|------|------|
| `clk` | 输入 | 1 | 工作时钟，同时连接仿真注错模块 |
| `rst_n` | 输入 | 1 | 异步低有效复位，同时连接仿真注错模块 |
| `encode_data` | 输入 | `TOTAL_WIDTH` | 两路 decoder 的源 SECDED 码字 |
| `data` | 输出 | `DATA_WIDTH` | decoder 1 的纠错数据 |
| `sb_err` | 输出 | 1 | decoder 1 的单比特错误指示 |
| `db_err` | 输出 | 1 | decoder 1 的双比特错误指示 |
| `comp_err` | 输出 | 1 | 两路错误状态不一致指示 |

#### 5.5.2 时序行为

模块内部例化两个 `fcip_ecc_dec_pipe`，注错后的两路 `encode_data` 分别在 decoder 入口寄存。两路路径具有相同的 1 个时钟周期延迟。`comp_err` 在流水 decoder 输出端组合生成，与 `data`、`sb_err` 和 `db_err` 周期对齐。

`DFV_FUSA` 打开时，`clk` 和 `rst_n` 同时连接到 `ecc_enc_inject_sim` 和 `ecc_dec_inject_sim`，支持基于计数器的遍历注错。

## 6. 仿真错误注入

### 6.1 功能使能

只有定义 `DFV_FUSA` 时，DCLS 模块才例化错误注入模块。未定义 `DFV_FUSA` 时：

```systemverilog
inj_enc_data0 = encode_data;
inj_enc_data1 = encode_data;
```

错误注入只用于仿真验证，不属于正常功能数据通路。

### 6.2 `ecc_enc_inject_sim`

该模块在 DCLS 分路前修改编码数据，可以向两路 decoder 同时注入错误。

| 编译宏 | 注错行为 |
|--------|----------|
| `ONE_BIT_RING_ECC_RANDOM_INJECT` | 随机翻转 1 位 |
| `TWO_BIT_RING_ECC_RANDOM_INJECT` | 随机翻转 2 个不同位置 |
| `ONE_BIT_RING_ECC_TRAVERSE_INJECT` | 使用计数器逐位翻转 |
| 未定义以上宏 | 数据透传 |

`INVALID_START` 和 `INVALID_END` 定义不参与随机或遍历注错的区间。部分 plusarg 会调整保留区间：

- `TEST_MASTER_ECC`
- `TEST_SLAVE_ECC`
- `TEST_COMP_ECC`
- `TEST_ECC_COV`
- `MEM_ECC_COV`

内部 `err_enject_en` 初始值为 0。测试平台需要通过层次化 force 或 deposit 将其置为 1，才能使注错数据进入功能路径。

### 6.3 `ecc_dec_inject_sim`

该模块位于两路 decoder 分路点，可以只修改 decoder 1 或 decoder 2 的输入。

| 编译宏 | 注错行为 |
|--------|----------|
| `COMPARE_RING_ECC_RANDOM_INJECT` | 随机翻转 decoder 2 输入的 1 位 |
| `COMPARE_RING_ECC_DEC1_TRAVERSE_INJECT` | 遍历翻转 decoder 1 输入 |
| `COMPARE_RING_ECC_DEC2_TRAVERSE_INJECT` | 遍历翻转 decoder 2 输入 |
| 未定义以上宏 | 两路数据透传 |

内部 `err_inject_en` 初始值为 0，测试平台需要通过层次化 force 或 deposit 使能注错。

### 6.4 DCLS 版本约束

- `fcip_ecc_dec_dcls_pipe` 提供 `clk` 和 `rst_n`，支持随机注错和遍历注错。
- `fcip_ecc_dec_dcls` 没有时钟和复位接口。该模块可以使用不依赖计数器的随机注错分支，但不能使用依赖时钟计数器的遍历注错分支。
- 同一注错模块中的多个模式由 `` `ifdef/`elsif `` 选择，每次编译只生效一个模式。

## 7. Memory 集成

`fcip_mem_ctrl_wrap` 通过参数 `ECC_EN` 选择 ECC 数据通路。

### 7.1 `ECC_EN=0`

- SRAM 数据宽度为 `DATA_WIDTH`。
- 写数据不编码，读数据不解码。
- `ecc_sb_err`、`ecc_db_err` 和 `ecc_comp_err` 固定为 0。

### 7.2 `ECC_EN=1`

写路径：

```text
mem_req_data -> fcip_ecc_enc -> 写路径寄存器 -> spram_din
```

读路径：

```text
spram_dout -> fcip_ecc_dec_dcls -> 读路径寄存器 -> mem_rsp_data
```

错误输出在读路径寄存后与 `mem_rsp_en` 相与，只在有效读响应周期上报：

```systemverilog
ecc_sb_err   = ecc_sb_err_1d   && mem_rsp_en;
ecc_db_err   = ecc_db_err_1d   && mem_rsp_en;
ecc_comp_err = ecc_comp_err_1d && mem_rsp_en;
```

ECC 模式的总响应延迟为：

```text
SRAM_ACCESS_LATENCY + SRAM_REQ_PIPE_STAGE + SRAM_RSP_PIPE_STAGE + 2
```

新增的 2 个周期分别来自 SRAM 请求及 ECC 编码路径寄存器，以及读侧解码结果寄存器。读请求的地址、使能和控制信息也经过前一级请求路径寄存器。

### 7.3 集成限制

- ECC 数据和 check bits 必须作为完整码字写入 SRAM。
- 部分位写会造成数据位和 check bits 不一致。集成模块使用 ECC 时应执行整字写，不应启用写 bit mask。
- `db_err=1` 时，`mem_rsp_data` 不保证有效，系统必须根据错误策略丢弃、重试或上报。
- `fcip_sync_fifo_spram` 当前不向模块端口暴露三类 ECC 错误输出，内部例化将其悬空。

## 8. 时序、复位和实现约束

| 模块 | 逻辑类型 | 时钟周期延迟 | 复位 |
|------|----------|--------------|------|
| `fcip_ecc_enc` | 组合 | 0 | 无 |
| `fcip_ecc_dec` | 组合 | 0 | 无 |
| `fcip_ecc_dec_pipe` | 组合加一级寄存 | 1 | 异步低有效 |
| `fcip_ecc_dec_dcls` | 双路组合 | 0 | 无 |
| `fcip_ecc_dec_dcls_pipe` | 双路一级流水 | 1 | 异步低有效 |

实现约束：

- `DATA_WIDTH` 增大时，encoder 的 check bit 异或树和 decoder 的 syndrome 计算逻辑同步增大。
- 组合 decoder 的关键路径包含 syndrome 计算、独热展开和数据纠正。
- pipe decoder 在 `encode_data` 入口插入一级寄存器，完整的 syndrome 计算、独热展开和数据纠正逻辑位于该寄存器之后。
- pipe 模块没有 `vld/rdy` 接口，控制信号延迟必须由集成模块实现。
- 所有参与同一事务的 `data`、`sb_err`、`db_err` 和 `comp_err` 必须保持周期对齐。

## 9. 验证关键点

| 用例 | 场景 | 预期结果 |
|------|------|----------|
| `TC_001` | 无错误编码后解码 | `data` 与原始数据一致，错误信号为 0 |
| `TC_002` | 遍历翻转每个数据位 | `sb_err=1`，`data` 被正确纠正 |
| `TC_003` | 遍历翻转每个 check bit | `sb_err=1`，`data` 保持正确 |
| `TC_004` | 翻转 overall parity 位 | `sb_err=1`，`data` 保持正确 |
| `TC_005` | 随机翻转两个不同位置 | `db_err=1` |
| `TC_006` | syndrome 超出码字范围 | `db_err=1` |
| `TC_007` | pipe decoder 连续输入 | 每拍输出对应前 1 拍输入 |
| `TC_008` | pipe decoder 异步复位 | 流水寄存器和错误输出清零 |
| `TC_009` | DCLS 两路输入一致 | `comp_err=0` |
| `TC_010` | 仅一路产生 `sb_err` | `comp_err=1` |
| `TC_011` | 仅一路产生 `db_err` | `comp_err=1` |
| `TC_012` | 两路数据不同但错误状态相同 | 按当前实现，`comp_err=0` |
| `TC_013` | `DFV_FUSA` 未定义 | 注错路径完全透传 |
| `TC_014` | 随机注错宏和注错使能有效 | 指定 decoder 输入出现翻转 |
| `TC_015` | pipe DCLS 遍历注错 | 计数器随 `clk` 运行，`rst_n=0` 时清零 |
| `TC_016` | Memory `ECC_EN=1` 连续读写 | 数据和错误信号按总延迟对齐 |

断言检查应覆盖以下不变量：

- 出现可纠正单比特错误且 `db_err=0` 时，`data` 必须等于参考数据。
- `comp_err` 必须等于两路 `sb_err` 不一致或两路 `db_err` 不一致。
- pipe 版本的输出必须与前 1 个周期采样的输入事务对应。
- `rst_n=0` 时，pipe 版本的流水寄存器和错误状态必须清零。

测试平台实现断言时，应根据组合版或 pipe 版设置正确的采样时钟和周期延迟。

## 10. 依赖关系和编译顺序

```text
fcip_ecc_dec
└── fcip_bin2onehot

fcip_ecc_dec_pipe
└── fcip_ecc_dec
    └── fcip_bin2onehot

fcip_ecc_dec_dcls
├── fcip_ecc_dec ×2
├── ecc_enc_inject_sim  [DFV_FUSA]
└── ecc_dec_inject_sim  [DFV_FUSA]

fcip_ecc_dec_dcls_pipe
├── fcip_ecc_dec_pipe ×2
├── ecc_enc_inject_sim  [DFV_FUSA]
└── ecc_dec_inject_sim  [DFV_FUSA]
```

`vc/fcip.f` 中 `vc/ring_err_injc.f` 位于 `vc/ecc_codec.f` 之前，保证定义 `DFV_FUSA` 时注错模块先于 DCLS 模块进入编译文件列表。
