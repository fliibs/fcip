
# fcip_async_fifo



## Auto Clear

这个Async支持Auto Clear功能，当这个功能开启时，这个异步FIFO会在空闲时自动进行指针恢复工作。

这个功能将会在空闲时在跨域传输空包，直到指针逐步恢复到全零。

指针恢复到全零后，full_zero信号会拉高。当然，使用clear信号强制清零指针后，full_zero信号也会拉高。

## Parameter


| Parameter | Default Value | Constraint | Description |
| --- | --- | --- | --- |
| SYNC_STAGE | 3 | >=2 | 异步打拍级数|
| FIFO_DEPTH | 0 | >=0 | 默认值为0，即根据SYNC_STAGE自动决定FIFO深度，不建议修改这个值|
| DATA_WIDTH | 1 | >=1 | 定义数据宽度|
| AUTO_CLEAR_EN | 0 | 1 or 0 | 启动自动清零模式，在这个模式下指针会自动回归到0位置|


## SDC

1. 识别与分类：

	1.1 抓出所有src进行遍历，分为如下类：
		- src only
		- src-dst pair中的src
		- 集成错误
		实现方法：通过判断src内某个关键锚点的连接关系，如果正确连接到input/output，则是src only。如果连接到dst内的对应锚点，则是src-dst pair中的成员。如果都不是，则是集成错误，打印错误。
		对于src only，保存为一个list，成员是src hier
		对于src-dst中的pair，保存一个list的list，[[src,dst],[src,dst]]，这里的src和dst都是hier string
		对于集成错误的节点，保存为一个list，成员是src hier，逐个打印错误。

	1.2 抓出所有dst进行遍历，分为如下类：
		- dst only
		- src-dst pair中的dst
		- 集成错误
		实现方法：通过判断dst内某个关键锚点的连接关系，如果正确连接到input/output，则是dst only。如果连接到src内的对应锚点，则是src-dst pair中的成员。如果都不是，则是集成错误，打印错误。
		对于dst only，保存为一个list，成员是dst hier
		对于src-dst中的pair，保存一个list的list，[[src,dst],[src,dst]]，这里的src和dst都是hier string
		对于集成错误的节点，保存为一个list，成员是dst hier，逐个打印错误。

	1.3 src-dst pair二次校验：
		在抓src和dst的过程中，都生成了src-dst pair list，对这两个list进行按字符串排序，然后比较，保证两次抓出来的是一样的，如果不一致则打印报错。

	这个阶段获得了三个数据结构：
	List[src]
	List[dst]
	List[List[src,dst]]

	和三个error flag:
	src detect error
	dst detect error
	pair detect error



2. 约束的设置:
	
	2.1 如果src detect error为0，开始进行src约束设置，遍历所有的src节点：
		2.1.1 检查所有src内的锚点都正确对应到input or ouptut，如果不是，那么报错，这是一个集成错误。
		2.1.2 针对锚点锚定的path，逐个设置约束。

	2.2 如果dst detect error为0，开始进行dst约束设置，遍历所有的dst节点：
		2.2.1 检查所有dst内的锚点都正确对应到input or output，如果不是，那么报错，这是一个集成错误。
		2.2.2 针对锚点锚定的path，逐个设置约束。

	2.3 如果pair detect error为0，开始进行pair约束设置，遍历所有pair:
		2.2.1 检查所有pair的对应锚点互相连接，如果不是，那么报错，这是一个集成错误。
		2.2.2 针对锚点锚定的path，逐个设置约束。	

	

这里所有的检查，无非是在做这几种情况：

- 检查锚点是否连接到input，返回input hier或空
- 检查锚点是否连接到output，返回output hier或空
- 检查两个锚点是否互联，返回true或空
- 检查src锚点是否连接到任意dst的特定锚点，返回dst名或空
- 检查dst锚点是否连接到任意src的特定锚点，返回src名或空

- check_marker_to_input_connection "marker_hier"
- check_marker_to_output_connection "marker_hier"
- check_marker_pair_connection "marker_a" "marker_b"
- check_src_primary_marker_to_dst_connection "src_primary_marker"
- check_dst_primary_marker_to_src_connection "dst_primary_marker"

为了支持这些检查，我们要在src和dst里定义若干marker和一个primary_marker，标识所有连接到对端异步桥的信号。


这份SDC应当直接以源码形式用现在的sdc gen flow source，要确认现在的flow在source的时候是否已经定义好了时钟，我们在代码里要直接get时钟属性的。

