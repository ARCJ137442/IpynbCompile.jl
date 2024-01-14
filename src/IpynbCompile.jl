# %% Jupyter Notebook | Julia 1.9.1 @ julia | format 2~4
# % language_info: {"file_extension":".jl","mimetype":"application/julia","name":"julia","version":"1.9.1"}
# % kernelspec: {"name":"julia-1.9","display_name":"Julia 1.9.1","language":"julia"}
# % nbformat: 4
# % nbformat_minor: 2

# %% [1] markdown
# # IpynbCompile.jl: 一个实用的「Jupyter笔记本→Julia源码」转换小工具

# %% [2] markdown
# **✨执行其中所有单元格，可自动构建、测试并生成相应`.jl`源码**！

# %% [3] markdown
# ## 主要功能

# %% [4] markdown
# 📍主要功能：**编译转换**&**解释执行** [***Jupyter***](https://jupyter.org/) 笔记本（`.ipynb`文件）
# 
# - 📌可【打开】并【解析】Jupyter笔记本：提供基本的「Jupyter笔记本」「Jupyter笔记本元数据」「Jupyter笔记本单元格」数据结构定义
#     - 笔记本 `IpynbNotebook{单元格类型}`
#     - 元数据 `IpynbNotebookMetadata`
#     - 单元格 `IpynbCell`
# - 📌可将Jupyter笔记本（`.ipynb`文件）【转换】成可直接执行的 [***Julia***](https://julialang.org/) 代码
#     - 编译单元格 `compile_cell`
#     - 编译笔记本 `compile_notebook`
#         - 方法1：`compile_notebook(笔记本::IpynbNotebook)`
#             - 功能：将「Jupyter笔记本结构」编译成Julia源码（字符串）
#             - 返回：`String`（源码字符串）
#         - 方法2：`compile_notebook(输入路径::String, 输出路径::String="$输入路径.jl")`
#             - 功能：从**指定路径**读取并编译Jupyter笔记本
#             - 返回：写入输出路径的字节数
# - 📌提供【解析并直接运行Jupyter笔记本】的方式（视作Julia代码执行）
#     - 解析单元格 `parse_cell`
#         - 方法 `parse_cell(单元格::IpynbCell)`
#             - 功能：将【单个】单元格内容编译解析成Julia表达式（`Expr`对象）
#         - 方法 `parse_cell(单元格列表::Vector{IpynbCell})`
#             - 功能：将【多个】单元格内容分别编译后【合并】，然后解析成Julia表达式（`Expr`对象）
#         - 返回
#             - Julia表达式（若为`code`代码类型）
#             - `nothing`（若为其它类型）
#     - 解析笔记本 `parse_notebook`
#         - 等效于「编译笔记本的**所有单元格**」
#     - 执行单元格 `eval_cell`
#         - 等效于「【解析】并【执行】单元格」
#     - 执行笔记本 `eval_notebook`
#         - 等效于「【解析】并【执行】笔记本」
#         - 逐单元格版本：`eval_notebook_by_cell`
#     - 引入笔记本 `include_notebook`
#         - 逐单元格版本：`include_notebook_by_cell`

# %% [5] markdown
# ✨创新点：**使用多样的「特殊注释」机制，让使用者能更灵活、更便捷地编译Jupyter笔记本，并能将其【交互式】优势用于库的编写之中**

# %% [6] markdown
# ### 重要机制：单元格「特殊注释」

# %% [7] markdown
# 简介：单元格的主要「特殊注释」及其作用
# 
# - `# %ignore-line` 忽略下一行
# - `# %ignore-below` 忽略下面所有行
# - `# %ignore-cell` 忽略整个单元格
# - `# %ignore-begin` 块忽略开始
# - `# %ignore-end` 块忽略结束
# - `#= %only-compiled` 仅编译后可用（头）
# - `%only-compiled =#` 仅编译后可用（尾）

# %% [8] markdown
# #### 各个「特殊注释」的用法

# %% [9] markdown
# 忽略单行

# %% [10] markdown
# ```julia
# 上边还会被编译
# # %ignore-line # 忽略单行（可直接在此注释后另加字符，会被一并忽略）
# [这是一行被忽略的代码]
# 下边也要被编译
# ```

# %% [11] markdown
# 忽略下面所有行

# %% [12] markdown
# ```julia
# 上边的代码正常编译
# # %ignore-below # 忽略下面所有行（可直接在此注释后另加字符，会被一并忽略）
# [
#     之后会忽略很多代码
# ]
# [包括这一行]
# [不管多长都会被忽略]
# ```

# %% [13] markdown
# 忽略整个单元格

# %% [14] markdown
# ```julia
# 上边的代码会被忽略（不会被编译）
# # %ignore-cell # 忽略整个单元格（可直接在此注释后另加字符，会被一并忽略）
# 下面的代码也会被忽略
# ⚠️另外，这些代码连着单元格都不会出现在编译后的文件中，连「标识头」都没有
# ```

# %% [15] markdown
# 忽略代码块

# %% [16] markdown
# ```julia
# 上边的代码正常编译
# # %ignore-begin # 开始块忽略（可直接在此注释后另加字符，会被一并忽略）
# [这一系列中间的代码会被忽略]
# [不管有多少行，除非遇到终止注释]
# # %ignore-end # 结束块忽略（可直接在此注释后另加字符，会被一并忽略）
# 下面的代码都会被编译
# ```

# %% [17] markdown
# 仅编译后可用

# %% [18] markdown
# ```julia
# 上边的代码正常编译，并且会随着笔记本一起执行
# #= %only-compiled # 开始「仅编译后可用」（可直接在此注释后另加字符，会被一并忽略）
# [
#     这一系列中间的代码
#     - 在「执行笔记本」时被忽略（因为在Julia块注释之中）
#     - 但在编译后「上下注释」被移除
#         - 因此会在编译后被执行
# ]
# %only-compiled =# # 结束「仅编译后可用」（可直接在此注释后另加字符，会被一并忽略）
# 下面的代码正常编译，并且会随着笔记本一起执行
# ```

# %% [19] markdown
# ✨另外，**该笔记本自身**，也是一个好的用法参考来源

# %% [20] markdown
# ## 参考

# %% [21] markdown
# - 本Julia库的灵感来源：[Promises.jl/src/notebook.jl](https://github.com/fonsp/Promises.jl/blob/main/src/notebook.jl)
#     - 源库使用了 [**Pluto.jl**](https://github.com/fonsp/Pluto.jl) 的「笔记本导出」功能
# - **Jupyter Notebook** 文件格式（JSON）：[🔗nbformat.readthedocs.io](https://nbformat.readthedocs.io/en/latest/format_description.html#notebook-file-format)

# %% [22] markdown
# %END_README
# 
# ↑ 最上面这行用于自动生成`README.md`（自动生成截止至此），阅读时可忽略

# %% [23] markdown
# ## 建立模块上下文

# %% [24] code
# ! ↓这后边注释的代码只有在编译后才会被执行
# ! 使用多行注释/块注释的语法，
# !     以`#= %only-compiled`行*开头*
# !     以`%only-compiled =#`行*结尾*
"""
IpynbCompile 主模块
"""
module IpynbCompile # 后续编译后会变为模块上下文


# %% [25] markdown
# ## 模块前置

# %% [26] markdown
# 导入库

# %% [27] code
import JSON

# %% [28] markdown
# 预置语法糖

# %% [29] code
"JSON常用的字典"
const JSONDict{ValueType} = Dict{String,ValueType} where ValueType

"默认解析出来的JSON字典（与`JSONDict`有本质不同，会影响到后续方法分派，并可能导致歧义）"
const JSONDictAny = JSONDict{Any}

# %% [30] markdown
# ## 读取ipynb文件

# %% [31] code
export read_ipynb_json

"""
读取ipynb JSON文件
- @param path .ipynb文件路径
- @return .ipynb文件内容（JSON文本→Julia对象）
"""
read_ipynb_json(path) = open(path, "r") do f
    read(f, String) |> JSON.parse
end

# ! ↓使用`# %ignore-line`让 编译器/解释器 忽略下一行


# %% [32] markdown
# ## 解析文件元信息

# %% [33] markdown
# Jupyter Notebook元数据 格式参考
# 
# ```yaml
# {
#     "metadata": {
#         "kernel_info": {
#             # if kernel_info is defined, its name field is required.
#             "name": "the name of the kernel"
#         },
#         "language_info": {
#             # if language_info is defined, its name field is required.
#             "name": "the programming language of the kernel",
#             "version": "the version of the language",
#             "codemirror_mode": "The name of the codemirror mode to use [optional]",
#         },
#     },
#     "nbformat": 4,
#     "nbformat_minor": 0,
#     "cells": [
#         # list of cell dictionaries, see below
#     ],
# }
# ```

# %% [34] markdown
# 当前Julia笔记本数据：
# ```json
# {
#     "language_info": {
#         "file_extension": ".jl",
#         "mimetype": "application/julia",
#         "name": "julia",
#         "version": "1.9.1"
#     },
#     "kernelspec": {
#         "name": "julia-1.9",
#         "display_name": "Julia 1.9.1",
#         "language": "julia"
#     }
# }
# ```


# %% [36] markdown
# 定义「笔记本」结构

# %% [37] code
export IpynbNotebook, IpynbNotebookMetadata

"""
定义一个Jupyter Notebook的metadata结构
- 🎯规范化存储Jupyter Notebook的元数据
    - 根据官方文档，仅存储【已经确定存在】的「语言信息」和「内核信息」
"""
@kwdef struct IpynbNotebookMetadata # !【2024-01-14 16:09:35】目前只发现这两种信息
    "语言信息"
    language_info::JSONDict{String}
    "内核信息"
    kernelspec::JSONDict{String}
end

"""
定义一个Jupyter Notebook的notebook结构
- 🎯规范化存储Jupyter Notebook的整体数据
"""
@kwdef struct IpynbNotebook{Cell}
    "单元格（类型后续会定义）"
    cells::Vector{Cell}
    "元信息"
    metadata::IpynbNotebookMetadata
    "笔记本格式"
    nbformat::Int
    "笔记本格式（最小版本？）"
    nbformat_minor::Int
end

"""
从JSON到notebook结构
- @method IpynbNotebook{Any}(json) Any泛型：直接保存原始字典
- @method IpynbNotebook{Cell}(json) where {Cell} 其它指定类型：调用`Cell`进行转换
"""
IpynbNotebook{Any}(json) = IpynbNotebook{Any}(;
    cells=json["cells"], # * Any类型→直接保存
    metadata=IpynbNotebookMetadata(json["metadata"]),
    nbformat=json["nbformat"],
    nbformat_minor=json["nbformat_minor"],
)
IpynbNotebook{Cell}(json) where {Cell} = IpynbNotebook{Cell}(;
    cells=Cell.(json["cells"]), # * ←广播类型转换
    metadata=IpynbNotebookMetadata(json["metadata"]),
    nbformat=json["nbformat"],
    nbformat_minor=json["nbformat_minor"],
)


# 从指定文件加载
IpynbNotebook(ipynb_path::AbstractString) = ipynb_path |> read_ipynb_json |> IpynbNotebook

"""
从JSON到「notebook元数据」结构
"""
IpynbNotebookMetadata(json::JSONDict) = IpynbNotebookMetadata(;
    language_info=json["language_info"],
    kernelspec=json["kernelspec"],
)

# ! ↓使用`# %ignore-below`让 编译器/解释器 忽略后续内容


# %% [38] markdown
# notebook编译/头部注释
# - 🎯标注 版本信息
# - 🎯标注 各类元数据

# %% [39] code
"""
【内部】从Notebook生成头部注释
- ⚠️末尾有换行
@example IpynbNotebook{Any, IpynbNotebookMetadata}(#= ... =#, IpynbNotebookMetadata(Dict("file_extension" => ".jl", "mimetype" => "application/julia", "name" => "julia", "version" => "1.9.1"), Dict("name" => "julia-1.9", "display_name" => "Julia 1.9.1", "language" => "julia")), 4, 2)
将生成如下代码
```julia
# %% Jupyter Notebook | Julia 1.9.1 @ julia | format 2~4
# % language_info: {"file_extension":".jl","mimetype":"application/julia","name":"julia","version":"1.9.1"}
# % kernelspec: {"name":"julia-1.9","display_name":"Julia 1.9.1","language":"julia"}
# % nbformat: 4
# % nbformat_minor: 2
```
"""
compile_notebook_head(notebook::IpynbNotebook) = """\
# %% Jupyter Notebook | $(notebook.metadata.kernelspec["display_name"]) \
@ $(notebook.metadata.language_info["name"]) | \
format $(notebook.nbformat_minor)~$(notebook.nbformat)
# % language_info: $(JSON.json(notebook.metadata.language_info))
# % kernelspec: $(JSON.json(notebook.metadata.kernelspec))
# % nbformat: $(notebook.nbformat)
# % nbformat_minor: $(notebook.nbformat_minor)
"""



# %% [40] markdown
# ## 解析处理单元格

# %% [41] markdown
# 定义「单元格」结构

# %% [42] code
export IpynbCell

"""
定义一个Jupyter Notebook的cell结构
- 🎯规范化存储Jupyter Notebook的单元格数据
"""
struct IpynbCell
    cell_type::String
    source::Vector{String}
    metadata::JSONDict
    output::Any

    "基于关键字参数的构造函数"
    IpynbCell(;
       cell_type="code",
       source=String[],
       metadata=JSONDictAny(),
       output=nothing
    ) = new(
        cell_type,
        source,
        metadata,
        output
    )

    """
    自单元格JSON对象的转换
    - 🎯将单元格转换成规范形式：类型+代码+元数据+输出
    - 不负责后续的 编译/解释 预处理
    """
    IpynbCell(json_cell::JSONDict) = IpynbCell(; (
        field => json_cell[string(field)]
        for field::Symbol in fieldnames(IpynbCell)
        if haskey(json_cell, string(field)) # ! 不论JSON对象是否具有：没有⇒报错
    )...)
end

# ! 在此重定向，以便后续外部调用
"重定向「笔记本」的默认「单元格」类型"
IpynbNotebook(json) = IpynbNotebook{IpynbCell}(json)



# %% [43] markdown
# 编译/入口

# %% [44] code
export compile_cell

"""
【入口】将一个单元格编译成Julia代码（包括注释）
- 📌根据「单元格类型」`code_type`字段进行细致分派
- ⚠️编译生成的字符串需要附带【完整】的换行信息
    - 亦即：编译后的「每一行」都需附带换行符
"""
compile_cell(cell::IpynbCell; kwargs...)::String = compile_cell(
    # 使用`Val`类型进行分派
    Val(Symbol(cell.cell_type)), 
    # 传递单元格对象自身
    cell;
    # 传递其它附加信息（如单元格序号，后续被称作「行号」）
    kwargs...
)

"""
【入口】将多个单元格编译成Julia代码（包括注释）
- 先各自编译，然后join(_, '\\n')
- ⚠️编译后不附带「最终换行符」
"""
compile_cell(cells::Vector{IpynbCell}; kwargs...)::String = join((
    compile_cell(
        # 传递单元格对象
        cell;
        # 附加单元格序号
        line_num,
        # 传递其它附加信息（如单元格序号，后续被称作「行号」）
        kwargs...
    )
    for (line_num, cell) in enumerate(cells) # ! ←一定是顺序遍历
), '\n')

"""
【内部】对整个单元格的「类型标头」编译
- 🎯生成一行注释，标识单元格
    - 指定单元格的边界
    - 简略说明单元格的信息
- ⚠️生成的代码附带末尾换行符

@example IpynbCell("markdown", ["# IpynbCompile.jl: 一个通用的「Julia Jupyter Notebook→Julia源码文件」小工具"], Dict{String, Any}(), nothing)
（行号为1）将生成
```julia
# %% [1] markdown
```
# ↑末尾附带换行符
"""
compile_cell_head(cell::IpynbCell; line_num::Integer) = "# %% [$line_num] $(cell.cell_type)\n"
# 无行号版本 # !【2024-01-14 15:57:21】具有更多细节的，必须放在前边（否则会被细节更多的方法覆盖）
compile_cell_head(cell::IpynbCell) = "# %% $(cell.cell_type)\n"



# %% [45] markdown
# 编译/Markdown

# %% [46] code
"""
对Markdown的编译
- 📌主要方法：转换成多个单行注释

@example IpynbCell("markdown", ["# IpynbCompile.jl: 一个通用的「Julia Jupyter Notebook→Julia源码文件」小工具"], Dict{String, Any}(), nothing)
（行号为1）将被转换为
```julia
# %% [1] markdown
# # IpynbCompile.jl: 一个通用的「Julia Jupyter Notebook→Julia源码文件」小工具
```
# ↑末尾附带换行符
"""
compile_cell(::Val{:markdown}, cell::IpynbCell; kwargs...) = """\
$(#= 附带标头 =# compile_cell_head(cell; kwargs...))\
$(join(
    "# $md_line"
    for md_line in cell.source
) #= ←此处无需附加换行符，`md_line`已自带 =#)
""" # ! ↑末尾附带换行符



# %% [47] markdown
# 编译/代码


# %% [49] code
"""
对代码的编译
- @param cell 所需编译的单元格
- @param kwargs 其它附加信息（如行号）
- 📌主要方法：逐行拼接代码，并
    - 📍每行代码的末尾都有换行符，除了最后一行代码

@example IpynbCell("code", ["\"JSON常用的字典\"\n", "const JSONDict{ValueType} = Dict{String,ValueType} where ValueType\n", "\n", "\"默认解析出来的JSON字典（与`JSONDict`有本质不同，会影响到后续方法分派，并可能导致歧义）\"\n", "const JSONDictAny = JSONDict{Any}"], Dict{String, Any}(), nothing)
（行号为1）将被转换为
```julia
"JSON常用的字典"
const JSONDict{ValueType} = Dict{String,ValueType} where ValueType

"默认解析出来的JSON字典（与`JSONDict`有本质不同，会影响到后续方法分派，并可能导致歧义）"
const JSONDictAny = JSONDict{Any}
```
↑⚠️注意：最后一行后自动添加了换行符
"""
function compile_cell(::Val{:code}, cell::IpynbCell; kwargs...)
    code::Union{Nothing,String} = compile_code_lines(cell; kwargs...)
    # 对应「忽略整个单元格」的情形，返回空字串
    isnothing(code) && return ""
    return """\
    $(#= 附带标头 =# compile_cell_head(cell; kwargs...))\
    $code\
    """ # ! ↑编译后的`code`已在最后一行带有换行符
end

"""
【内部，默认不导出】编译代码行
- 🎯根据单元格的`source::Vector{String}`字段，预处理并返回【修改后】的源码
- 📌在此开始执行各种「行编译逻辑」（在此列举部分）- `# %ignore-line` 忽略下一行
    - `# %ignore-below` 忽略下面所有行
    - `# %ignore-cell` 忽略整个单元格
    - `#= %only-compiled` 仅编译后可用（头）
    - `%only-compiled =#` 仅编译后可用（尾）
- ⚠️编译后的文本是「每行都有换行符」
    - 对最后一行增加了换行符，以便和先前所有行一致
- @param cell 所需编译的单元格
- @param kwargs 其它附加信息（如行号）
- @return 编译后的源码 | nothing（表示「完全不呈现单元格」）
"""
function compile_code_lines(cell::IpynbCell; kwargs...)

    local lines::Vector{String} = cell.source
    local len_lines = length(lines)
    local current_line_i::Int = firstindex(lines)
    local current_line::String
    local result::String = ""

    while current_line_i <= len_lines
        current_line = lines[current_line_i]
        # * `%ignore-line` 忽略下一行 | 仅需为行前缀
        if startswith(current_line, "# %ignore-line")
            current_line_i += 1 # ! 结合后续递增，跳过下面一行，不让本「特殊注释」行被编译
        # * `%ignore-below` 忽略下面所有行 | 仅需为行前缀
        elseif startswith(current_line, "# %ignore-below")
            break # ! 结束循环，不再编译后续代码
        # * `%ignore-cell` 忽略整个单元格 | 仅需为行前缀
        elseif startswith(current_line, "# %ignore-cell")
            return nothing # ! 返回「不编译单元格」的信号
        # * `%ignore-begin` 跳转到`%ignore-end`的下一行，并忽略中间所有行 | 仅需为行前缀
        elseif startswith(current_line, "# %ignore-begin")
            # 只要后续没有以"# %ignore-end"开启的行，就不断跳过
            while !startswith(lines[current_line_i], "# %ignore-end") && current_line_i <= len_lines
                current_line_i += 1 # 忽略性递增
            end # ! 让最终递增跳过"# %ignore-end"所在行
        # * `%only-compiled` 仅编译后可用（多行） | 仅需为行前缀
        elseif (
            startswith(current_line, "#= %only-compiled") ||
            startswith(current_line, "%only-compiled =#")
            )
            # ! 不做任何事情，跳过当前行
        # * 否则：直接将行追加到结果
        else
            result *= current_line
        end
        
        # 最终递增
        current_line_i += 1
    end

    # 最后返回所有行 # ! ↓对最后一行增加换行符，以便和先前所有行一致
    return result * "\n"
end



# %% [50] markdown
# ## 解析执行单元格

# %% [51] markdown
# 🎯将单元格解析成Julia表达式，并可直接作为代码执行
# - 【核心】解释：`parse_cell`
#     - 📌基本是`compile_cell` ∘ `Meta.parse`的复合
#     - 对无法执行的单元格 ⇒ return `nothing`
#         - 如markdown单元格
#     - 可执行单元格 ⇒ Expr
#         - 如code单元格
# - 执行：`eval_cell`
#     - 📌基本是`parse_cell` ∘ `eval`的复合
#     - ⚙️可任意指定其中的`eval`函数

# %% [52] code
export parse_cell, tryparse_cell, eval_cell

"""
解析一个单元格
- 🎯将单元格解析成Julia表达式
- 📌使用`Meta.parseall`解析代码
    - `Meta.parse`只能解析一个Julia表达式
    - 可能会附加上不必要的「:toplevel」表达式
@param cell 单元格
@param parse_function 解析函数（替代原先`Meta.parseall`的位置）
@param kwargs 附加参数
@return 解析后的Julia表达式 | nothing（不可执行）
"""
function parse_cell(cell::IpynbCell; parse_function = Meta.parseall, kwargs...)

    # 只有类型为 code 才执行解析
    cell.cell_type == "code" && return parse_function(
        compile_cell(cell; kwargs...)
    )

    # ! 默认不可执行
    return nothing
end

"""
解析一系列单元格
@param cells 单元格序列
@param parse_function 解析函数（替代原先`Meta.parseall`的位置）
@param kwargs 附加参数
@return 解析后的Julia表达式 | nothing（不可执行）
"""
function parse_cell(cells::Vector{IpynbCell}; parse_function = Meta.parseall, kwargs...)

    # 只有类型为 code 才执行解析
    return parse_function(
        # 预先编译所有代码单元格，然后连接成一个字符串
        join(
            compile_cell(cell; kwargs...)
            for cell in cells
            # 只有类型为`code`的单元格才执行解析
            if cell.cell_type == "code"
        )
    )

    # ! 默认不可执行
    return nothing
end

"""
尝试解析单元格
- 📌用法同`parse_cell`，但会在解析报错时返回`nothing`
    - ⚠️此中「解析报错」≠「解析过程出现错误」
        - 📝解析错误的代码会被`Meta.parseall`包裹进类似`Expr(错误)`的表达式中
        - 例如：`Expr(:incomplete, "incomplete: premature end of input")`
"""
tryparse_cell(args...; kwargs...) = try
    parse_cell(args...; kwargs...)
catch e
    @warn e
    nothing
end

"""
执行单元格
- 🎯执行解析后的单元格（序列）
- @param code_or_codes 单元格 | 单元格序列
- @param eval_function 执行函数（默认为`eval`）
- @param kwargs 附加参数
- @return 执行后表达式的值
"""
eval_cell(code_or_codes; eval_function=eval, kwargs...) = eval_function(
    parse_cell(code_or_codes; kwargs...)
)




# %% [54] markdown
# ## 编译笔记本

# %% [55] code
export compile_notebook

"""
编译整个笔记本
- 🎯编译整个笔记本对象，形成相应Julia代码
- 📌整体文本：头部注释+各单元格编译（逐个join(_, '\\n')）
- ⚠️末尾不会附加换行符
- @param notebook 要编译的笔记本对象
- @return 编译后的文本
"""
compile_notebook(notebook::IpynbNotebook) = """\
$(compile_notebook_head(notebook))
$(compile_cell(notebook.cells))
""" # ! `$(compile_notebook_head(notebook))`在原本的换行下再空一行，以便与后续单元格分隔

"""
编译整个笔记本，并【写入】指定路径
- @param notebook 要编译的笔记本对象
- @param path 要写入的路径
- @return 写入结果
"""
compile_notebook(notebook::IpynbNotebook, path::AbstractString) = open(path, "w") do io
    # 使用 `write`函数，自动写入编译结果
    write(io, compile_notebook(notebook))
end

"""
编译指定路径的笔记本，并写入指定路径
- 「写入路径」默认为「读入路径+`.jl`」
- @param path 要读取的路径
- @return 写入结果
"""
compile_notebook(path::AbstractString, destination="$path.jl") = compile_notebook(
    # 直接使用构造函数加载笔记本
    IpynbNotebook(path), 
    # 保存在目标路径
    destination
)



# %% [56] markdown
# ## 解析执行笔记本

# %% [57] markdown
# 执行笔记本

# %% [58] code
export eval_notebook, eval_notebook_by_cell

"""
【整个】解释并执行Jupyter笔记本
- 📌直接使用`eval_cell`对笔记本的所有单元格进行解释执行
    - 可以实现一些「编译后可用」的「上下文相关代码」
        - 如「将全笔记本代码打包成一个模块」
"""
eval_notebook(notebook::IpynbNotebook; kwargs...) = eval_cell(
   notebook.cells;
   kwargs...
)

"""
【逐单元格】解释并执行Jupyter笔记本
- 📌逐个取出并执行笔记本中的代码
- 记录并返回最后一个返回值
"""
function eval_notebook_by_cell(notebook::IpynbNotebook; kwargs...)
    # 返回值
    local result::Any = nothing
    # 逐个执行
    for cell in notebook.cells
        result = eval_cell(cell)
    end
    # 返回最后一个结果
    return result
end

# ! 测试代码放在最后边

# %% [59] markdown
# 引入笔记本

# %% [60] code
export include_notebook, include_notebook_by_cell

"""
从【字符串】路径解析并【整个】执行整个笔记本的代码
- 📌「执行笔记本」已经有`eval_notebook`支持了
- 🎯直接解析并执行`.ipynb`文件
- 📌先加载并编译Jupyter笔记本，再【整个】执行其所有单元格
- 会像`include`一样返回「最后一个执行的单元格的返回值」
"""
include_notebook(path::AbstractString) = (
    path |> 
    read_ipynb_json |> 
    IpynbNotebook{IpynbCell} |> 
    eval_notebook
)

"""
解析并【逐单元格】执行整个笔记本的代码
- 📌「执行笔记本」已经有`eval_notebook_by_cell`支持了
- 🎯直接解析并执行`.ipynb`文件
- 📌先加载并编译Jupyter笔记本，再【逐个】执行其单元格
- ⚠️不会记录单元格执行的【中间】返回值
    - 但正如`include`一样，「最后一个执行的单元格的返回值」仍然会被返回
"""
include_notebook_by_cell(path::AbstractString) = (
    path |> 
    read_ipynb_json |> 
    IpynbNotebook{IpynbCell} |> 
    eval_notebook_by_cell
)



# %% [61] markdown
# ## 关闭模块上下文

# %% [62] code
# ! ↓这后边注释的代码只有在编译后才会被执行
# ! 仍然使用多行注释语法，以便统一格式
end # module


# %% [63] markdown
# ## 自动构建

# %% [64] markdown
# 构建过程主要包括：
# 
# - **自举**构建主模块，生成库文件
# - 扫描`src`目录下基本所有Jupyter笔记本（`.ipynb`），编译生成`.jl`源码
# - 提取该文件开头Markdown笔记，在**项目根目录**下**生成自述文件**（`README.md`）
#     - 因此`README.md`暂且只有一种语言（常更新的语言）
# 
# ⚠️不应该在编译后的库文件中看到任何代码




