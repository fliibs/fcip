# FCIP ARB VRP Design Specification

## 1. 概述

`fcip_arb_vrp` 是一个 N 路 `valid-ready-payload` 输入汇聚到 1 路输出的仲裁器顶层模块。模块将请求选择、payload 选择和输出握手缓冲三部分封装在一起，通过 `MODE` 选择内部仲裁模型，通过 `HSK_MODE` 选择输出侧握手实现。

RTL 文件位于 `ip/arbiter/fcip_arb_vrp.sv`，其核心实现特点如下：

- 输入侧 `v_vld_s` 直接参与仲裁，未在顶层做前置打拍。
- 内部将仲裁结果拆成 `v_grant` 和 `v_grant_hsk` 两条路径：
    - `v_grant` 由具体仲裁器模型直接生成。
    - `v_grant_hsk` 经过握手模式处理后，再驱动 payload 选择和 upstream ready 返回。
- 输出 payload 始终由 `fcip_real_mux_onehot` 完成 onehot 复用。
- `HSK_MODE` 在当前 RTL 中实际实现了三种模式：
    - `HSK_MODE=0`：纯组合直通。
    - `HSK_MODE=1`：payload 级后向寄存切片，带 1 项缓存。
    - `HSK_MODE=2`：grant 级保持模式，锁存被选中的 onehot grant。
- 若 `HSK_MODE` 取其他值，RTL 会落回与 `HSK_MODE=0` 等价的直通实现。

## 2. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| MODE | integer | 3 | 仲裁模式，`0=Fix`，`1=RR`，`2=Age Matrix`，`3=PLRU` |
| HSK_MODE | integer | 1 | 输出握手模式，`0=pass`，`1=backward reg slice(payload hold)`，`2=grant hold` |
| WIDTH | integer | 4 | 输入端口数 |
| PRIORITY | bit vector | `{WIDTH{1'b0}}` | 固定优先级模式下的高优先级分组标记 |
| PLD_WIDTH | integer | 32 | payload 位宽 |

## 3. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 工作时钟 |
| rst_n | input | 1 | 异步低有效复位 |
| v_vld_s | input | WIDTH | 各输入请求 valid |
| v_rdy_s | output | WIDTH | 各输入请求 ready |
| v_pld_s | input | WIDTH x PLD_WIDTH | 各输入 payload |
| vld_m | output | 1 | 输出 valid |
| rdy_m | input | 1 | 下游 ready |
| pld_m | output | PLD_WIDTH | 输出 payload |

## 4. 顶层数据通路与控制通路

### 4.1 顶层连接关系

```text
v_vld_s -------------------------------> 仲裁核心 -------------------+
                                                                    |
v_grant --------------------------------> 握手模式选择 ------------+ |
                                                                  | |
v_pld_s --> fcip_real_mux_onehot <------- v_grant_hsk <-----------+ |--> 输出侧
                                                                  | |
rdy_m ----------------------------------> 握手模式逻辑 ------------+ |
                                                                    |
v_rdy_s = v_grant_hsk & {WIDTH{m_rdy}} <----------------------------+
```

### 4.2 关键组合关系

- `v_vld = v_vld_s`
- `m_vld = |v_vld_s`
- `v_rdy_s = v_grant_hsk & {WIDTH{m_rdy}}`
- `m_pld = onehot_mux(v_pld_s, v_grant_hsk)`

这里有两个实现细节需要特别说明：

1. 顶层的 `m_vld` 仅由是否存在任意输入 valid 决定，而不是由 `v_grant` 或 `v_grant_hsk` 是否非零决定。
2. payload mux 和 upstream ready 都使用 `v_grant_hsk`，因此握手模式不仅影响 ready 返压，也可能影响输出侧实际选择的是哪一路 payload。

因此正确性依赖于各仲裁器在 `|v_vld_s == 1` 时一定输出合法 onehot `v_grant`，并且在 `HSK_MODE=2` 下，被锁存 grant 的源端必须遵守 `valid-ready` 协议，在 ready 返回前保持 payload 稳定。

### 4.3 ready 回传机制

只有被 grant 的那个输入端口会收到 ready：

```text
slave_i ready = v_grant_hsk[i] & m_rdy
```

因此顶层具备以下行为特征：

- 未被选中的请求即便 `v_vld_s[i]=1`，也会保持 `v_rdy_s[i]=0`。
- 对于 `HSK_MODE=1`，`m_rdy` 不一定等于 `rdy_m`，而是由内部缓冲是否占用和寄存后的 ready 决定。
- 对于 `HSK_MODE=2`，`m_rdy` 仍等于 `rdy_m`，但 `v_grant_hsk` 可能在反压期间保持为旧值。

## 5. 输出握手电路实现

## 5.1 HSK_MODE=0 直通模式

该模式下输出侧没有任何状态单元：

- `vld_m = m_vld`
- `pld_m = m_pld`
- `m_rdy = rdy_m`

这意味着：

- valid 路径是纯组合从输入 valid 到输出 valid。
- payload 路径是纯组合从 `v_pld_s` 经 onehot mux 到 `pld_m`。
- backpressure 也是纯组合从 `rdy_m` 反向传到 `v_rdy_s`。

适用场景：时序宽松、希望零额外延迟、接受较长组合路径。

## 5.2 HSK_MODE=1 后向寄存切片

该模式引入 3 个内部状态量：

- `vld_m_r`：缓存中是否已有待发送数据。
- `pld_m_r`：缓存的数据。
- `rdy_m_r`：对 `rdy_m` 的 1 拍寄存。

对应组合逻辑为：

- `vld_m = vld_m_r | m_vld`
- `pld_m = vld_m_r ? pld_m_r : m_pld`
- `m_rdy = rdy_m_r | (~vld_m_r)`

其语义不是“前向寄存 payload”，而是“对 ready 进行后向打拍，并在下游突然拉低 ready 时用 1 项寄存器吸收一个飞行中的传输”。

### 5.2.1 缓存写入条件

缓存只在以下条件同时成立时写入：

```text
m_vld && ~vld_m_r && ~rdy_m
```

即：

- 当前仲裁器确实有数据要输出。
- 缓冲目前为空。
- 下游这一拍不 ready。

满足时：

- `vld_m_r <= 1`
- `pld_m_r <= m_pld`

### 5.2.2 缓存释放条件

当 `rdy_m=1` 时，`vld_m_r` 会在时钟沿清零。也就是说，缓存数据一旦被下游接收，下一拍重新回到直通状态。

### 5.2.3 ready 打拍效果

`rdy_m_r` 每拍采样一次 `rdy_m`，复位后初始化为 1，因此：

- 当缓存为空时，`m_rdy` 恒为 1，不会阻塞新的仲裁输出。
- 当缓存非空时，`m_rdy` 由前一拍的 `rdy_m_r` 决定。
- 这相当于将 backpressure 反向传播延迟了 1 拍，但通过 1 项 buffer 保证数据不丢失。

## 5.3 HSK_MODE=2 grant 保持模式

该模式新增 2 个内部状态量：

- `vld_m_r`：当前是否存在被锁存的历史 grant。
- `pld_m_r`：锁存的历史 grant onehot，位宽为 `WIDTH`，虽然命名为 `pld_m_r`，但实际保存的不是 payload，而是 grant。

对应组合逻辑为：

- `vld_m = m_vld`
- `pld_m = m_pld`
- `m_rdy = rdy_m`
- `v_grant_hsk = vld_m_r ? pld_m_r : v_grant`

可见这个模式没有缓存 payload，也没有打拍 ready；它只在下游反压时把“当前选中了哪一路”锁存下来。

### 5.3.1 锁存条件

锁存条件与 `HSK_MODE=1` 类似：

```text
m_vld && ~vld_m_r && ~rdy_m
```

满足时：

- `vld_m_r <= 1`
- `pld_m_r <= v_grant`

### 5.3.2 释放条件

当 `rdy_m=1` 时，`vld_m_r` 清零，`v_grant_hsk` 恢复跟随实时仲裁结果 `v_grant`。

### 5.3.3 实际语义

这个模式适用于上游 source 能在 `valid=1` 且尚未收到 ready 前持续保持 payload 稳定的场景。因为：

- 输出 payload 来自 `m_pld = mux(v_pld_s, v_grant_hsk)`。
- 一旦 `v_grant_hsk` 被锁定，后续输出仍持续从同一路输入采样 payload。
- 如果该 source 在未握手完成时改变 payload，就会破坏时序假设。

因此 `HSK_MODE=2` 本质上是“锁存选择，不锁存数据”。

## 6. 三种内部握手时序示意

说明：当前 RTL 已实现 3 种 `HSK_MODE`，下面分别给出对应的时序行为。

### 6.1 场景A: HSK_MODE=0 直通握手

```text
clk     : ┌─┐ ┌─┐ ┌─┐ ┌─┐
          └─┘ └─┘ └─┘ └─┘
v_vld_s0: 0───1──────────0
v_grant : 0───1──────────0
rdy_m   : 1────────────────
v_rdy_s0: 0───1──────────0
vld_m   : 0───1──────────0
pld_m   : ---- D0 ---------

说明:
1. 同拍仲裁、同拍输出、同拍返回 ready。
2. 无寄存器截断，输入到输出完全组合通过。
```

### 6.2 场景B: HSK_MODE=1，payload 缓冲吸收反压

```text
clk     : ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐
          └─┘ └─┘ └─┘ └─┘ └─┘
v_vld_s1: 0───1────1────0────0
rdy_m   : 1───0────0────1────1
rdy_m_r : 1───1────0────0────1
vld_m_r : 0───1────1────0────0
m_rdy   : 1───1────0────0────1
v_grant : 0───1────0────0────0
vld_m   : 0───1────1────1────0
pld_m   : ---- D1---D1---D1-----

说明:
1. 第2拍下游 `rdy_m=0`，但 `m_rdy` 仍可能因 `rdy_m_r=1` 保持为1。
2. 飞行中的 `m_pld` 被写入 `pld_m_r`，`vld_m_r` 置1。
3. 后续优先输出缓存 payload，直到下游重新 ready 后清空缓存。
4. 该模式对 source 的 payload 保持要求最低，因为数据本身已被缓存。
```

### 6.3 场景C: HSK_MODE=2，grant 锁存保持

```text
clk     : ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐
          └─┘ └─┘ └─┘ └─┘ └─┘
src1_vld : 0───1────1────1────0
src1_pld : ---- A----A----A-----
src2_vld : 0───0────1────1────0
v_grant  : 0───1────0/1──0/1──0
rdy_m    : 1───0────0────1────1
vld_m_r  : 0───1────1────0────0
v_grant_h: 0───1────1────1────0
v_rdy_s1 : 0───0────0────1────0
pld_m    : ---- A----A----A-----

说明:
1. 第2拍检测到反压时，锁存的是 `v_grant`，不是 payload。
2. 即使后续实时仲裁 `v_grant` 变化，`v_grant_hsk` 仍保持旧选路。
3. `pld_m` 会继续从被锁定的 source 采样，因此 source1 必须保持 payload A 不变直到握手完成。
4. 该模式缩短了内部缓存数据通路，但把 payload 保持责任留给上游接口协议。
```

## 7. 四种仲裁模型的生成原理

## 7.1 MODE=0 固定优先级仲裁

使用子模块 `fcip_grant_gen_fp`。

### 7.1.1 原理

该模块不是简单的“低位固定优先级”，而是两级优先级：

1. 先按 `v_priority` 将请求拆成高优先级组和低优先级组。
2. 若高优先级组非空，只在高优先级组内部执行低位优先。
3. 否则在低优先级组内部执行低位优先。

实现方式：

- `high_pri_vld = v_vld & v_priority`
- `low_pri_vld  = v_vld & ~v_priority`
- 每组内部通过前缀或 `~(|bits_below)` 生成 onehot grant。

### 7.1.2 例子

```text
WIDTH      = 4
v_vld      = 4'b1111
v_priority = 4'b1010

high_pri_vld = 4'b1010
low_pri_vld  = 4'b0101

高优先级组存在请求，因此仅在 bit[3], bit[1] 中选择低位优先的 bit1。
v_grant = 4'b0010
```

## 7.2 MODE=1 Round-Robin 仲裁

使用子模块 `fcip_grant_gen_rr`。

### 7.2.1 原理

RR 的核心状态是 `prio_reg`，它不是“上次 grant 编号”，而是一组 mask：

- `vld_mask = v_vld & prio_reg`
- 若 mask 后仍有有效请求，则在 mask 区域内取低位优先。
- 若 mask 区域无有效请求，则回绕到全向量 `v_vld` 中重新取低位优先。
- 每次 grant 后更新 `prio_reg`，使下一次优先从当前 grant 的后一位开始。

该实现是典型的“两路固定优先级 + mask 回绕”结构。

### 7.2.2 例子

```text
WIDTH = 4
初始 prio_reg = 4'b1111

周期1: v_vld=1111 -> grant bit0
更新后 prio_reg 指向 bit1 及以上

周期2: v_vld=1111 -> grant bit1
周期3: v_vld=1111 -> grant bit2
周期4: v_vld=1111 -> grant bit3
周期5: 再回绕到 bit0
```

因此当所有端口持续请求时，grant 顺序表现为 `0 -> 1 -> 2 -> 3 -> 0 ...`。

## 7.3 MODE=2 Age Matrix 仲裁

由 `fcip_mtx_gen_age + fcip_arb_matrix` 两级构成。

### 7.3.1 矩阵含义

`vv_matrix[i][j] = 1` 表示端口 `i` 比端口 `j` 更老，应优先于 `j` 被服务。

矩阵满足：

- 对角线恒为 0。
- 下三角始终是上三角的按位取反，因此矩阵只需维护一半。

### 7.3.2 年龄更新原理

当某个端口 `k` 在 `alloc_en=1` 时被分配后：

- `vv_matrix[k][j]` 对所有 `j!=k` 被更新为 1，表示别人都比 `k` 新。
- `vv_matrix[i][k]` 对所有 `i!=k` 被更新为 0，表示 `k` 不再比别人老。

直观理解：被刚刚服务过的端口变成“最新”，其他未服务端口相对更老。

### 7.3.3 选择原理

`fcip_arb_matrix` 对每个候选端口 `i` 计算：

```text
select_onehot[i] = (~|(v_vld & vv_matrix[i])) && v_vld[i]
```

含义是：如果所有当前有效请求里，没有任何一个端口比 `i` 更老，那么 `i` 被选中。

### 7.3.4 例子

假设 `WIDTH=4`，当前有效请求为端口 0、2、3，年龄关系满足：

```text
3 最新，2 次之，0 最老
```

则矩阵在这些请求之间会表现为：

- 端口0相对于2、3均占优。
- 端口2相对于3占优，但相对于0不占优。
- 端口3对0、2都不占优。

因此 `v_grant = 4'b0001`，优先选择端口0。

## 7.4 MODE=3 PLRU 树仲裁

由 `fcip_mtx_gen_plru_tree + fcip_arb_matrix` 两级构成。

### 7.4.1 节点编码原理

PLRU 使用一棵满二叉树，每个内部节点 1 bit，记录“哪一侧更久未被访问”。

对于 `WIDTH=4`：

- 共有 `WIDTH-1 = 3` 个内部节点。
- 根节点决定左半区和右半区哪一半更旧。
- 两个叶子父节点分别决定本半区内哪一个端口更旧。

RTL 中 `node[WIDTH-2:0]` 保存这组状态，并在 `alloc_en` 时根据 `v_alloc` 更新。

### 7.4.2 矩阵生成原理

`fcip_mtx_gen_plru_tree` 不是直接输出 grant，而是先把树状态展开为 `vv_matrix`：

- 若某节点指示左侧更旧，则左子树中的所有端口都应在矩阵中优先于右子树中的所有端口。
- 对每一层、每个分区，RTL 用双层循环把该节点状态批量写入对应的矩阵块。
- 最后再通过下三角取反和对角线清零补齐完整矩阵。

所以 PLRU 的仲裁决策最终也统一落入 `fcip_arb_matrix` 的“矩阵比较”框架。

### 7.4.3 例子

以 `WIDTH=4` 为例，假设最近一次服务顺序是 `0, 1, 0`，那么端口 2 或 3 会被认为更久未使用。若树状态表示：

- 右半区 `{2,3}` 比左半区 `{0,1}` 更旧。
- 在右半区内，端口2 比端口3 更旧。

则展开后的矩阵会让端口2成为所有有效请求中的最优项，故 `v_grant` 优先指向端口2。

## 8. payload 选择电路

`fcip_real_mux_onehot` 的实现不是直接写 `case(onehot)`，而是先做一次二维转置：

1. 把 `v_pld[port][bit]` 转成 `v_pld_rev[bit][port]`。
2. 每个 bit 与 `select_onehot` 按位与。
3. 对每个 bit 做按位或还原为最终 payload。

即：

```text
pld_m[b] = OR_i (v_pld_s[i][b] & v_grant_hsk[i])
```

这要求 `v_grant_hsk` 是 onehot 或 all-zero。正常使用中应保证 grant 独热，且握手模式切换后不能破坏其 onehot 属性。

## 9. 关键实现约束

- `WIDTH` 应满足仲裁子模块的使用预期，尤其 PLRU 的树结构天然更适合 2 的幂宽度。
- `HSK_MODE=1` 只提供 1 项 payload 缓存，不是完整多级 skid buffer。
- `HSK_MODE=2` 不缓存 payload，只缓存 onehot grant，因此依赖上游 source 在未完成握手前保持 payload 稳定。
- `alloc_en = rdy_m && vld_m`，Age/PLRU 的内部状态仅在真正输出握手成功时更新。
- 对于 `HSK_MODE=1` 和 `HSK_MODE=2`，状态更新都以外部 `rdy_m` 为准，不以 `m_rdy` 为准，这一点决定了反压吸收的精确时序。

## 10. 使用示例

### 10.1 Round-Robin 4路仲裁

```systemverilog
fcip_arb_vrp #(
    .MODE(1),
    .HSK_MODE(1),
    .WIDTH(4),
    .PLD_WIDTH(64)
) u_rr_arb (
    .clk    (clk),
    .rst_n  (rst_n),
    .v_vld_s(v_vld_s),
    .v_rdy_s(v_rdy_s),
    .v_pld_s(v_pld_s),
    .vld_m  (vld_m),
    .rdy_m  (rdy_m),
    .pld_m  (pld_m)
);
```

适合多个持续请求源共享一个下游消费端，且要求服务公平。

### 10.2 Grant 保持模式示例

```systemverilog
fcip_arb_vrp #(
    .MODE(3),
    .HSK_MODE(2),
    .WIDTH(4),
    .PLD_WIDTH(128)
) u_plru_hold_arb (
    .clk    (clk),
    .rst_n  (rst_n),
    .v_vld_s(v_vld_s),
    .v_rdy_s(v_rdy_s),
    .v_pld_s(v_pld_s),
    .vld_m  (vld_m),
    .rdy_m  (rdy_m),
    .pld_m  (pld_m)
);
```

适合 source 侧已经天然保证 `valid` 保持和 `payload` 保持的场景，此时可以只锁存 grant，减少 payload 缓存开销。

### 10.3 分组固定优先级仲裁

```systemverilog
fcip_arb_vrp #(
    .MODE(0),
    .HSK_MODE(0),
    .WIDTH(4),
    .PRIORITY(4'b1100),
    .PLD_WIDTH(32)
) u_fp_arb (...);
```

其中端口2、3属于高优先级组，若它们有请求，端口0、1即使有效也不会被选中。

## 11. 验证关键点

### 11.1 功能检查

1. `v_grant` 与 `v_grant_hsk` 独热性：任意时刻最多一位为 1。
2. `v_rdy_s` 回传准确性：只有 `v_grant_hsk` 对应端口能看到 ready。
3. `fcip_real_mux_onehot` 输出 payload 与 `v_grant_hsk` 选择端口一致。
4. `HSK_MODE=1` 下 backpressure 进入和释放时无数据丢失、无重复发送。
5. `HSK_MODE=2` 下反压期间 grant 被锁住，且被锁定源的 payload 在握手完成前保持稳定。
6. Age/PLRU 状态只在 `rdy_m && vld_m` 时更新。

### 11.2 推荐测试用例

| 用例编号 | 场景 | 预期 |
|----------|------|------|
| TC_001 | MODE=0，`v_priority=0`，全请求 | 低位优先 |
| TC_002 | MODE=0，混合优先级分组 | 高优先级组先服务，组内低位优先 |
| TC_003 | MODE=1，所有端口持续请求 | grant 周期性轮转 |
| TC_004 | MODE=2，请求先后到达 | 最老请求优先输出 |
| TC_005 | MODE=3，重复访问部分端口 | 长时间未访问端口优先 |
| TC_006 | HSK_MODE=0，下游始终ready | 零额外拍延迟直通 |
| TC_007 | HSK_MODE=1，下游短时反压 | payload 缓冲吸收1次飞行数据 |
| TC_008 | HSK_MODE=1，下游长时反压 | 维持缓存并阻塞上游 ready |
| TC_009 | HSK_MODE=2，下游反压且其他端口请求变化 | `v_grant_hsk` 保持旧选路 |
| TC_010 | HSK_MODE=2，被选中 source 保持 payload | 输出 payload 与锁存 grant 一致 |
| TC_011 | 复位后首次仲裁 | RR/Age/PLRU 初值行为符合RTL |
| TC_012 | 动态 valid 抖动 | grant 和 payload 均稳定合法 |
