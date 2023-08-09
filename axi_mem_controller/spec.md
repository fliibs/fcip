

# Feature

- 支持AXI数据位宽64/128/256 bit位宽可配置。（AXI数据位宽和SRAM位宽对应）
- 支持SRAM容量1KB-8MB。
- 支持可配置的Reg Slice，用于适应不同的物理实现。
- 支持最长16的Burst Length。
- 不支持Narrow Transfer。
- 只支持单口SRAM，读写复用同一个SRAM端口。
- 支持ECC（可配置），对外提供ECC相关的错误指示信号。