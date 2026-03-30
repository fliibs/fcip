# FCIP ARB VRP Design Specification

## 1. 概述

`fcip_arb_vrp` 是一个多模式参数化仲裁器顶层模块，支持四种仲裁策略：固定优先级（Fix Priority）、轮询（Round Robin）、年龄矩阵（Age Matrix）和伪最近最少使用（Pseudo-LRU）。模块集成了valid-ready-payload握手接口，支持可配置的输出握手模式。

**所属分类：** arbiter  
**文件路径：** `ip/arbiter/fcip_arb_vrp.sv`

## 2. 功能描述

- 支持N路输入仲裁，每路带独立的valid/ready/payload信号
- 四种仲裁模式通过参数MODE选择：
  - **MODE=0**：固定优先级，低位优先级高，支持两级优先级分组
  - **MODE=1**：Round-Robin轮询仲裁
  - **MODE=2**：Age Matrix年龄矩阵仲裁（最老优先）
  - **MODE=3**：Pseudo-LRU树形仲裁
- 输出握手模式HSK_MODE可配置：
  - **HSK_MODE=0**：直通模式，无额外延迟
  - **HSK_MODE=1**：1拍缓冲模式，在master端未ready时缓存数据
- 使用onehot mux进行payload选择

## 3. 参数列表

| 参数名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| MODE | integer | 3 | 仲裁模式：0=Fix Priority, 1=Round Robin, 2=Age Matrix, 3=PLRU |
| HSK_MODE | integer | 1 | 输出握手模式：0=直通, 1=1拍缓冲 |
| WIDTH | integer | 4 | 仲裁输入端口数量 |
| PRIORITY | bit vector | {WIDTH{1'b0}} | 固定优先级模式下各端口的优先级（仅MODE=0有效） |
| PLD_WIDTH | integer | 32 | Payload数据位宽 |

## 4. 接口信号

| 信号名 | 方向 | 位宽 | 描述 |
|--------|------|------|------|
| clk | input | 1 | 时钟信号 |
| rst_n | input | 1 | 异步低有效复位 |
| v_vld_s[WIDTH-1:0] | input | WIDTH | 各输入端口的valid信号 |
| v_rdy_s[WIDTH-1:0] | output | WIDTH | 各输入端口的ready信号 |
| v_pld_s[WIDTH-1:0] | input | PLD_WIDTH×WIDTH | 各输入端口的payload数据 |
| vld_m | output | 1 | 输出端口valid信号 |
| rdy_m | input | 1 | 输出端口ready信号 |
| pld_m | output | PLD_WIDTH | 输出端口payload数据 |

## 5. 内部架构

```
                    ┌─────────────────────────────┐
  v_vld_s[0] ──────┤                             ├──── vld_m
  v_pld_s[0] ──────┤    Arbiter Engine           ├──── pld_m
  v_vld_s[1] ──────┤   (FP/RR/Age/PLRU)         ├
  v_pld_s[1] ──────┤         │                   │
  ...              │    v_grant                   │
  v_vld_s[N] ──────┤         │                   │
  v_pld_s[N] ──────┤    ┌────▼────┐              │
                    │    │ Onehot  │   ┌────────┐ │
  rdy_m ───────────┤    │  MUX    ├──►│HSK Buf ├─┤
                    │    └─────────┘   └────────┘ │
  v_rdy_s[0] ◄─────┤                             │
  v_rdy_s[N] ◄─────┤                             │
                    └─────────────────────────────┘
```

### 子模块依赖

| 子模块 | 功能 | 使用条件 |
|--------|------|----------|
| `fcip_real_mux_onehot` | Payload选择复用器 | 始终使用 |
| `fcip_grant_gen_fp` | 固定优先级grant生成 | MODE=0 |
| `fcip_grant_gen_rr` | Round Robin grant生成 | MODE=1 / 默认 |
| `fcip_mtx_gen_age` | 年龄矩阵生成 | MODE=2 |
| `fcip_arb_matrix` | 矩阵仲裁核心 | MODE=2,3 |
| `fcip_mtx_gen_plru_tree` | PLRU树形矩阵生成 | MODE=3 |

## 6. 时序说明

### HSK_MODE=0（直通模式）
- vld_m = |v_vld_s（组合逻辑）
- pld_m = mux(v_pld_s, v_grant)（组合逻辑）
- 无额外延迟

### HSK_MODE=1（1拍缓冲模式）
- 当master端就绪时直接输出
- 当master端未就绪时，将数据缓存到寄存器中
- 下一拍优先输出缓存数据

## 7. 验证关键点

### 功能验证
1. **MODE切换验证**：分别验证四种仲裁模式的正确性
2. **公平性验证**：RR/Age/PLRU模式下多个持续请求是否公平服务
3. **单请求验证**：仅一个端口有请求时的行为
4. **全请求验证**：所有端口同时请求时的仲裁行为
5. **HSK_MODE验证**：两种握手模式下数据传输的正确性
6. **反压验证**：rdy_m持续无效时的行为（无数据丢失）
7. **Grant独热性**：任意时刻v_grant最多只有1位为1

### 关键测试用例

| 用例编号 | 测试场景 | 预期结果 |
|----------|----------|----------|
| TC_001 | MODE=0，所有端口同时请求 | 低位端口优先被服务 |
| TC_002 | MODE=1，所有端口持续请求 | 各端口被均匀轮询服务 |
| TC_003 | MODE=2，先后到达的请求仲裁 | 最先到达的请求先被服务 |
| TC_004 | MODE=3，持续多轮请求 | PLRU策略选择最久未服务端口 |
| TC_005 | HSK_MODE=1，master端反压 | 数据被缓存，无丢失 |
| TC_006 | 单端口请求 | 立即grant该端口 |
| TC_007 | 无请求 | vld_m=0，无grant |
| TC_008 | 动态请求变化 | grant随请求变化正确切换 |
| TC_009 | 复位后首次仲裁 | 初始状态正确，仲裁正常启动 |
| TC_010 | Payload数据通路完整性 | 输出payload与被grant端口的payload一致 |
