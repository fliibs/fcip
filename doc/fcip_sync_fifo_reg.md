
# fcip_sync_fifo_reg

基于reg实现的同步FIFO，输入和输出都采用valid/ready握手接口，提供forwarding功能。

在启用forwarding功能时，SRAM的输入到输出延迟为0 cycle，但会引入in to out path。

在不启用forwarding功能时，SRAM的输入到输出延迟为1 cycle。

## Timing

### 在不启用forwarding模式时

对外输出的valid/ready/empty/full/almost_empty/almost_full都是完全reg out的。

外部输入的valid信号在内部的路径只有1级组合逻辑。

外部输入的ready信号在内部的路径只有1级组合逻辑。

外部输入的payload在内部的路径有log2(N)级组合逻辑(N为FIFO深度)。

对外输出的payload在内部的路径有log2(N)级组合逻辑(N为FIFO深度)。

输入输出的payload能采用进一步进行类似regslice的方式优化，没有继续往下做的原因是：这种优化会在valid和ready上额外引入1-2级组合逻辑，增加一些寄存器，收益是payload信号在内部的组合逻辑降为2级左右。考虑到关键路径通常在valid/ready信号上，并且基于reg的同步FIFO最大深度一般只会配到32左右，对应5级组合逻辑。综合考虑这里应当更关注valid/ready信号的路径优化，因此这里保留了payload信号的input decode和output mux。

### 在启用forwarding模式时

对外输出的empty/full/almost_empty/almost_full都是完全reg out的。

其它 TODO


## Parameter

| Parameter | Default Value | Constraint | Description |
| --- | --- | --- | --- |
| FIFO_DEPTH | 32 | >=4 | 建议深度不要超过64，超过64应当采用SRAM方案|
| DATA_WIDTH | 1 | >=1 | 定义数据宽度|
| ALMOST_FULL_THRESHOLD | 0 | >=0 | 这个阈值X，代表距离真正的full还有X时，almost_full就会拉高|
| ALMOST_EMPTY_THRESHOLD | 0 | >=0 | 这个阈值X，代表距离真正的empty还有X时，almost_empty就会拉高|
| FORWARD_EN | 0 | 1 or 0 | 决定是否启用forwarding，在启用时，FIFO延迟为0，但会引入in to out path|
