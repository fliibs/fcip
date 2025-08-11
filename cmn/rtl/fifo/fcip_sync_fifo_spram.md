
# fcip_sync_fifo_spram


## ROB


这个ROB维护的还是一个顺进顺出模型，它的输出是顺序的，它的Pre-alloc也是顺序的，但是它的输入是乱序的。


事实上它的内部是两个指针和若干个entry，每个entry需要一个data_valid信号和一个idle信号。

输出指针会指向当前entry，等当前entry的data_valid拉高后对外输出。

Pre-alloc指针会指向当前entry，等当前entry的idle信号为高时成功分配该entry。

事实上对于一个entry来说，data_valid和idle两个信号构成了entry的三个状态：

- 空闲
- 已被分配等待数据
- 已被分配且有数据可用

这三个状态总是循环出现。

这实现了一个基本的FIFO功能，它还需要支持forwarding逻辑。

对于forwarding来说，输入是一个带了entry_id的包，这个输入的entry_id需要当拍和当前的输出指针比较，如果相等的话，会直接把结果forward到输出上，并且直接将对应entry标注为空闲。但如果在这拍这个数据并没有被握手取走，这个数据依旧要写回对应entry。

需要注意的是，ROB有两个输入通道，这个操作对两个输入通道都要做。当然，每个周期永远只会有一个输入通道会生效forwarding。



## Decode

这个Decode逻辑比较复杂，它按如下流程进行路由：

    if(SRAM empty)
        if(forwarding ready)
            goto forwarding
        else
            goto sram
    else
        goto sram

这里指的是路由的策略，路由决策后还是要按照valid ready握手来决定传输是否成功的。

## LUT

LUT就是一个不带fowrading逻辑的基于reg的同步FIFO，用来记录每一笔传输存储的位置。


## FIFO Controller

这是一个基于双口SRAM反压接口的FIFO控制器，它的实现

## SRAM RW Controller

这个模块是最tricky的部分。
