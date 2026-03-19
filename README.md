# fcip
This is a common ip library containing common RTL modules.

  - memory
    - doc
    - rtl
    - vc
    - tb
  - fifo
  - arbiter
  - regslice
  - stdcell_wrap

## fexpand

fexpand submodule是一个 filelist 预处理器，功能：
- 递归展开 -f 引用的子 filelist
- 展开环境变量（$ENV_VAR）为绝对路径
- 支持 C99 宏条件编译（#ifdef / \ifdef` 等）
- 自动去重（同一文件/路径出现多次只保留一次）
  
### 使用方法

1. cd $fcip_new_rel/fexpand
- ./fexpand -i <input.f> -o <output_expanded.f>

2. 附加宏定义（等价于 `define / #define）
- ./fexpand -i top.f -o out.f -D SUB1 -D SUB2=1

3. 指定日志文件
- ./fexpand -i top.f -o out.f -l fexpand.log

4. 同时导出 VHDL 文件列表（.vhd/.vhdl 单独输出）
- ./fexpand -i top.f -o sv_out.f -oh vhdl_out.f