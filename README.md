<!-- ⚠️该文件由 `IpynbCompile.ipynb` 自动生成于 2024-09-14T21:33:32.587，无需手动修改 -->
# IpynbCompile.jl: 一个实用的Jupyter笔记本构建工具

![GitHub License](https://img.shields.io/github/license/ARCJ137442/IpynbCompile.jl?style=for-the-badge&color=a270ba)
![Code Size](https://img.shields.io/github/languages/code-size/ARCJ137442/IpynbCompile.jl?style=for-the-badge&color=a270ba)
![Lines of Code](https://www.aschey.tech/tokei/github.com/ARCJ137442/IpynbCompile.jl?style=for-the-badge&color=a270ba)
[![Language](https://img.shields.io/badge/language-Julia%201.7+-purple?style=for-the-badge&color=a270ba)](https://cn.julialang.org/)

开发状态：

[![CI status](https://img.shields.io/github/actions/workflow/status/ARCJ137442/IpynbCompile.jl/ci.yml?style=for-the-badge)](https://github.com/ARCJ137442/IpynbCompile.jl/actions/workflows/ci.yml)

![Created At](https://img.shields.io/github/created-at/ARCJ137442/IpynbCompile.jl?style=for-the-badge)
![Last Commit](https://img.shields.io/github/last-commit/ARCJ137442/IpynbCompile.jl?style=for-the-badge)

[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?style=for-the-badge)](https://conventionalcommits.org)
![GitHub commits since latest release](https://img.shields.io/github/commits-since/ARCJ137442/IpynbCompile.jl/latest?style=for-the-badge)

## 主要功能

### 简介

📍主要功能：为 [***Jupyter***](https://jupyter.org/) 笔记本（`.ipynb`文件）提供一套特定的注释语法，以支持 **编译转换**&**解释执行** 功能，扩展其应用的可能性

- 📌可【打开】并【解析】Jupyter笔记本：提供基本的「Jupyter笔记本」「Jupyter笔记本元数据」「Jupyter笔记本单元格」数据结构定义
  - 笔记本 `IpynbNotebook{单元格类型}`
  - 元数据 `IpynbNotebookMetadata`
  - 单元格 `IpynbCell`
- 📌可将Jupyter笔记本（`.ipynb`文件）【转换】成可直接执行的 [***Julia***](https://julialang.org/) 代码
  - 编译单元格 `compile_cell`
  - 编译笔记本 `compile_notebook`
    - 方法1：`compile_notebook(笔记本::IpynbNotebook)`
      - 功能：将「Jupyter笔记本结构」编译成Julia源码（字符串）
      - 返回：`String`（源码字符串）
    - 方法2：`compile_notebook(输入路径::String, 输出路径::String="$输入路径.jl")`
      - 功能：从**指定路径**读取并编译Jupyter笔记本
      - 返回：写入输出路径的字节数
- 📌提供【解析并直接运行Jupyter笔记本】的方式（视作Julia代码执行）
  - 解析单元格 `parse_cell`
    - 方法 `parse_cell(单元格::IpynbCell)`
      - 功能：将【单个】单元格内容编译解析成Julia表达式（`Expr`对象）
    - 方法 `parse_cell(单元格列表::Vector{IpynbCell})`
      - 功能：将【多个】单元格内容分别编译后【合并】，然后解析成Julia表达式（`Expr`对象）
    - 返回
      - Julia表达式（若为`code`代码类型）
      - `nothing`（若为其它类型）
  - 解析笔记本 `parse_notebook`
    - 等效于「编译笔记本的**所有单元格**」
  - 执行单元格 `eval_cell`
    - 等效于「【解析】并【执行】单元格」
  - 执行笔记本 `eval_notebook`
    - 等效于「【解析】并【执行】笔记本」
    - 逐单元格版本：`eval_notebook_by_cell`
  - 引入笔记本 `include_notebook`
    - 逐单元格版本：`include_notebook_by_cell`

✨创新点：**使用多样的「特殊注释」机制，让使用者能更灵活、更便捷地编译Jupyter笔记本，并能将其【交互式】优势用于库的编写之中**

### 重要机制：单元格「特殊注释」

简介：单元格的主要「特殊注释」及其作用（以`# 单行注释` `#= 块注释 =#`为例）

- `# %ignore-line` 忽略下一行
- `# %ignore-below` 忽略下面所有行
- `# %ignore-cell` 忽略整个单元格
- `# %ignore-begin` 块忽略开始
- `# %ignore-end` 块忽略结束
- `#= %only-compiled` 仅编译后可用（头）
- `%only-compiled =#` 仅编译后可用（尾）
- `# %include <路径>` 引入指定路径的文件内容，替代一整行注释

✨**该笔记本自身**，就是一个好的用法参考来源

#### 各个「特殊注释」的用法

##### 忽略单行

📌简要用途：忽略**下一行**代码

编译前@笔记本单元格：

```julia
[["上边还会被编译"]]
# %ignore-line # 忽略单行（可直接在此注释后另加字符，会被一并忽略）
["这是一行被忽略的代码"]
[["下边也要被编译"]]
```

编译后：

```julia
[["上边还会被编译"]]
[["下边也要被编译"]]
```

##### 忽略下面所有行

编译前@笔记本单元格

```julia
[["上边的代码正常编译"]]
# %ignore-below # 忽略下面所有行（可直接在此注释后另加字符，会被一并忽略）
["""
  之后会忽略很多代码
"""]
["包括这一行"]
["不管多长都会被忽略"]
```

编译后：

```julia
[["上边的代码正常编译"]]
```

##### 忽略整个单元格

编译前@笔记本单元格：

```julia
["上边的代码会被忽略（不会被编译）"]
# %ignore-cell # 忽略整个单元格（可直接在此注释后另加字符，会被一并忽略）
["下面的代码也会被忽略"]
["⚠️另外，这些代码连着单元格都不会出现在编译后的文件中，连「标识头」都没有"]
```

编译后：

```julia
```

↑空字串

📌一般习惯将 `# %ignore-cell` 放在第一行

##### 忽略代码块

📝即「块忽略」

编译前@笔记本单元格：

```julia
[["上边的代码正常编译"]]
# %ignore-begin # 开始块忽略（可直接在此注释后另加字符，会被一并忽略）
["这一系列中间的代码会被忽略"]
["不管有多少行，除非遇到终止注释"]
# %ignore-end # 结束块忽略（可直接在此注释后另加字符，会被一并忽略）
[["下面的代码都会被编译"]]
```

编译后：

```julia
[["上边的代码正常编译"]]
[["下面的代码都会被编译"]]
```

##### 仅编译后可用

主要用途：包装 `module` 等代码，实现编译后模块上下文

- ⚠️对于 **Python** 等【依赖缩进定义上下文】的语言，难以进行此类编译

编译前@笔记本单元格：

```julia
[["上边的代码正常编译，并且会随着笔记本一起执行"]]
#= %only-compiled # 开始「仅编译后可用」（可直接在此注释后另加字符，会被一并忽略）
["""
  这一系列中间的代码
  - 在「执行笔记本」时被忽略（因为在Julia块注释之中）
  - 但在编译后「上下注释」被移除
    - 因此会在编译后被执行
"""]
%only-compiled =# # 结束「仅编译后可用」（可直接在此注释后另加字符，会被一并忽略）
[["下面的代码正常编译，并且会随着笔记本一起执行"]]
```

编译后：

```julia
[["上边的代码正常编译，并且会随着笔记本一起执行"]]
["""
  这一系列中间的代码
  - 在「执行笔记本」时被忽略（因为在Julia块注释之中）
  - 但在编译后「上下注释」被移除
    - 因此会在编译后被执行
"""]
[["下面的代码正常编译，并且会随着笔记本一起执行"]]
```

##### 文件引入

主要用途：结合「仅编译后可用」简单实现「外部代码内联」

- 如：集成某些**中小型映射表**，整合零散源码文件……

编译前@笔记本单元格：

```julia
const square_map_dict = # 这里的等号可以另起一行
# %include to_include.jl 
# ↑ 上面一行会被替换成文件内容
```

编译前@和笔记本**同目录**下的`to_include.jl`中：
↓文件末尾有换行符

```julia
# 这是一个要被引入的外部字典对象
Dict([
  1 => 1
  2 => 4
  3 => 9
  # ...
])
```

编译后：

```julia
const square_map_dict = # 这里的等号可以另起一行
# 这是一个要被引入的外部字典对象
Dict([
  1 => 1
  2 => 4
  3 => 9
  # ...
])
# ↑ 上面一行会被替换成数据
```

📝Julia的「空白符无关性」允许在等号后边大范围附带注释的空白

##### 文件内联

主要用途：为「文件引入」提供一个快捷方式，并**支持「编译后内联笔记本」**

- 如：编译并集成**其它笔记本**到该文件中

编译前@笔记本单元格：

```julia
const square_map_dict = # 这里的等号可以另起一行
#= %inline-compiled =# include("to_include.jl")
# ↑ 上面一行会被替换成文件内容
# * 若为使用`include_notebook`引入的笔记本，则会被替换为编译后的笔记本内容
```

编译前@和笔记本**同目录**下的`to_include.jl`中：
↓文件末尾有换行符

```julia
# 这是一个要被引入的外部字典对象
Dict([
  1 => 1
  2 => 4
  3 => 9
  # ...
])
```

编译后：

```julia
const square_map_dict = # 这里的等号可以另起一行
# 这是一个要被引入的外部字典对象
Dict([
  1 => 1
  2 => 4
  3 => 9
  # ...
])
# ↑ 上面一行会被替换成数据
```

📝Julia的「空白符无关性」允许在等号后边大范围附带注释的空白

## 参考

- 本Julia库的灵感来源：[Promises.jl/src/notebook.jl](https://github.com/fonsp/Promises.jl/blob/main/src/notebook.jl)
  - 源库使用了 [**Pluto.jl**](https://github.com/fonsp/Pluto.jl) 的「笔记本导出」功能
- **Jupyter Notebook** 文件格式（JSON）：[🔗nbformat.readthedocs.io](https://nbformat.readthedocs.io/en/latest/format_description.html#notebook-file-format)
