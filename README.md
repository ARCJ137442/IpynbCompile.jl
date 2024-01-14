# IpynbCompile.jl: 一个实用的「Jupyter笔记本→Julia源码」转换小工具

**✨执行其中所有单元格，可自动构建、测试并生成相应`.jl`源码**！

## 主要功能

📍主要功能：**编译转换**&**解释执行** [***Jupyter***](https://jupyter.org/) 笔记本（`.ipynb`文件）

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

简介：单元格的主要「特殊注释」及其作用

- `# %ignore-line` 忽略下一行
- `# %ignore-below` 忽略下面所有行
- `# %ignore-cell` 忽略整个单元格
- `# %ignore-begin` 块忽略开始
- `# %ignore-end` 块忽略结束
- `#= %only-compiled` 仅编译后可用（头）
- `%only-compiled =#` 仅编译后可用（尾）

#### 各个「特殊注释」的用法

```jupyter-notebook
上边还会被编译
# %ignore-line # 忽略单行（可直接在此注释后另加字符，会被一并忽略）
[这是一行被忽略的代码]
下边也要被编译
```

```jupyter-notebook
上边的代码正常编译
# %ignore-below # 忽略下面所有行（可直接在此注释后另加字符，会被一并忽略）
[
  之后会忽略很多代码
]
[包括这一行]
[不管多长都会被忽略]
```

```jupyter-notebook
上边的代码会被忽略（不会被编译）
# %ignore-cell # 忽略整个单元格（可直接在此注释后另加字符，会被一并忽略）
下面的代码也会被忽略
⚠️另外，这些代码连着单元格都不会出现在编译后的文件中，连「标识头」都没有
```

```jupyter-notebook
上边的代码正常编译
# %ignore-begin # 开始块忽略（可直接在此注释后另加字符，会被一并忽略）
[这一系列中间的代码会被忽略]
[不管有多少行，除非遇到终止注释]
# %ignore-end # 结束块忽略（可直接在此注释后另加字符，会被一并忽略）
下面的代码都会被编译
```

```jupyter-notebook
上边的代码正常编译，并且会随着笔记本一起执行
#= %only-compiled # 开始「仅编译后可用」（可直接在此注释后另加字符，会被一并忽略）
[
  这一系列中间的代码
  - 在「执行笔记本」时被忽略（因为在Julia块注释之中）
  - 但在编译后「上下注释」被移除
    - 因此会在编译后被执行
]
%only-compiled =# # 结束「仅编译后可用」（可直接在此注释后另加字符，会被一并忽略）
下面的代码正常编译，并且会随着笔记本一起执行
```

✨另外，**该笔记本自身**，也是一个好的用法参考来源

## 参考

- 本Julia库的灵感来源：[Promises.jl/src/notebook.jl](https://github.com/fonsp/Promises.jl/blob/main/src/notebook.jl)
  - 源库使用了 [**Pluto.jl**](https://github.com/fonsp/Pluto.jl) 的「笔记本导出」功能
- **Jupyter Notebook** 文件格式（JSON）：[🔗nbformat.readthedocs.io](https://nbformat.readthedocs.io/en/latest/format_description.html#notebook-file-format)

⚠️该文件由 IpynbCompile.ipynb 自动生成于 2024-01-15T00:14:18.672，请勿修改！
