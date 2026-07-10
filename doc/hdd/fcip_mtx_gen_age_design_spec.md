# FCIP MTX GEN AGE Design Specification

## 1. 概述

`fcip_mtx_gen_age` 是年龄矩阵生成模块，与`fcip_age_matrix`功能等价，作为独立封装使用于`fcip_arb_vrp`的MODE=2模式。

**所属分类：** arbiter  
**文件路径：** `ip/arbiter/fcip_mtx_gen_age.sv`

## 2. 功能描述

- 维护WIDTH×WIDTH年龄优先级矩阵
- 被分配条目变为最年轻（优先级最低）
- 未被分配条目保持原有相对年龄关系

## 3. 参数/接口

与`fcip_age_matrix`完全相同，参见该模块文档。

## 4. 验证关键点

参见`fcip_age_matrix`文档中的验证用例。
