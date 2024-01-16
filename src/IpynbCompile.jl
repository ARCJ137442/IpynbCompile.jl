# %% Jupyter Notebook | Julia 1.9.1 @ julia | format 2~4
# % language_info: {"file_extension":".jl","mimetype":"application/julia","name":"julia","version":"1.9.1"}
# % kernelspec: {"name":"julia-1.9","display_name":"Julia 1.9.1","language":"julia"}
# % nbformat: 4
# % nbformat_minor: 2

# %% [1] markdown
# # IpynbCompile.jl: 一个实用的「Jupyter笔记本→Julia源码」转换小工具

# %% [2] markdown
# <!-- README-ignored -->
# （✨执行其中所有单元格，可自动构建、测试并生成相应`.jl`源码！）

# %% [3] markdown
# ## 主要功能

# %% [4] markdown
# ### 简介

# %% [5] markdown
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

# %% [6] markdown
# ✨创新点：**使用多样的「特殊注释」机制，让使用者能更灵活、更便捷地编译Jupyter笔记本，并能将其【交互式】优势用于库的编写之中**

# %% [7] markdown
# ### 重要机制：单元格「特殊注释」

# %% [8] markdown
# 简介：单元格的主要「特殊注释」及其作用（以`# 单行注释` `#= 块注释 =#`为例）
# 
# - `# %ignore-line` 忽略下一行
# - `# %ignore-below` 忽略下面所有行
# - `# %ignore-cell` 忽略整个单元格
# - `# %ignore-begin` 块忽略开始
# - `# %ignore-end` 块忽略结束
# - `#= %only-compiled` 仅编译后可用（头）
# - `%only-compiled =#` 仅编译后可用（尾）
# - `# %include <路径>` 引入指定路径的文件内容，替代一整行注释

# %% [9] markdown
# ✨**该笔记本自身**，就是一个好的用法参考来源

# %% [10] markdown
# #### 各个「特殊注释」的用法

# %% [11] markdown
# ##### 忽略单行

# %% [12] markdown
# 📌简要用途：忽略**下一行**代码

# %% [13] markdown
# 编译前@笔记本单元格：
# 
# ```julia
# [[上边还会被编译]]
# # %ignore-line # 忽略单行（可直接在此注释后另加字符，会被一并忽略）
# [这是一行被忽略的代码]
# [[下边也要被编译]]
# ```
# 
# 编译后：
# 
# ```julia
# [[上边还会被编译]]
# [[下边也要被编译]]
# ```

# %% [14] markdown
# ##### 忽略下面所有行

# %% [15] markdown
# 编译前@笔记本单元格
# 
# ```julia
# [[上边的代码正常编译]]
# # %ignore-below # 忽略下面所有行（可直接在此注释后另加字符，会被一并忽略）
# [
#     之后会忽略很多代码
# ]
# [包括这一行]
# [不管多长都会被忽略]
# ```
# 
# 编译后：
# 
# ```julia
# [[上边的代码正常编译]]
# ```

# %% [16] markdown
# ##### 忽略整个单元格

# %% [17] markdown
# 编译前@笔记本单元格：
# 
# ```julia
# [上边的代码会被忽略（不会被编译）]
# # %ignore-cell # 忽略整个单元格（可直接在此注释后另加字符，会被一并忽略）
# [下面的代码也会被忽略]
# [⚠️另外，这些代码连着单元格都不会出现在编译后的文件中，连「标识头」都没有]
# ```
# 
# 编译后：
# 
# ```julia
# ```
# 
# ↑空字串

# %% [18] markdown
# 📌一般习惯将 `# %ignore-cell` 放在第一行

# %% [19] markdown
# ##### 忽略代码块

# %% [20] markdown
# 📝即「块忽略」

# %% [21] markdown
# 编译前@笔记本单元格：
# 
# ```julia
# [[上边的代码正常编译]]
# # %ignore-begin # 开始块忽略（可直接在此注释后另加字符，会被一并忽略）
# [这一系列中间的代码会被忽略]
# [不管有多少行，除非遇到终止注释]
# # %ignore-end # 结束块忽略（可直接在此注释后另加字符，会被一并忽略）
# [[下面的代码都会被编译]]
# ```
# 
# 编译后：
# 
# ```julia
# [[上边的代码正常编译]]
# [[下面的代码都会被编译]]
# ```

# %% [22] markdown
# ##### 仅编译后可用

# %% [23] markdown
# 主要用途：包装 `module` 等代码，实现编译后模块上下文
# 
# - ⚠️对于 **Python** 等【依赖缩进定义上下文】的语言，难以进行此类编译

# %% [24] markdown
# 编译前@笔记本单元格：
# 
# ```julia
# [[上边的代码正常编译，并且会随着笔记本一起执行]]
# #= %only-compiled # 开始「仅编译后可用」（可直接在此注释后另加字符，会被一并忽略）
# [
#     这一系列中间的代码
#     - 在「执行笔记本」时被忽略（因为在Julia块注释之中）
#     - 但在编译后「上下注释」被移除
#         - 因此会在编译后被执行
# ]
# %only-compiled =# # 结束「仅编译后可用」（可直接在此注释后另加字符，会被一并忽略）
# [[下面的代码正常编译，并且会随着笔记本一起执行]]
# ```
# 
# 编译后：
# 
# ```julia
# [[上边的代码正常编译，并且会随着笔记本一起执行]]
# [
#     这一系列中间的代码
#     - 在「执行笔记本」时被忽略（因为在Julia块注释之中）
#     - 但在编译后「上下注释」被移除
#         - 因此会在编译后被执行
# ]
# [[下面的代码正常编译，并且会随着笔记本一起执行]]
# ```

# %% [25] markdown
# ##### 文件引入

# %% [26] markdown
# 主要用途：结合「仅编译后可用」实现「外部代码内联」
# 
# - 如：集成某些**中小型映射表**，整合零散源码文件……

# %% [27] markdown
# 编译前@笔记本单元格：
# 
# ```julia
# const square_map_dict = # 这里的等号可以另起一行
# # % include to_include.jl 
# # ↑ 上面一行会被替换成数据
# ```
# 
# 编译前@和笔记本**同目录**下的`to_include.jl`中：
# ↓文件末尾有换行符
# 
# ```julia
# # 这是一个要被引入的外部字典对象
# Dict([
#     1 => 1
#     2 => 4
#     3 => 9
#     # ...
# ])
# ```
# 
# 编译后：
# 
# ```julia
# const square_map_dict = # 这里的等号可以另起一行
# # 这是一个要被引入的外部字典对象
# Dict([
#     1 => 1
#     2 => 4
#     3 => 9
#     # ...
# ])
# # ↑ 上面一行会被替换成数据
# ```
# 
# 📝Julia的「空白符无关性」允许在等号后边大范围附带注释的空白

# %% [28] markdown
# ## 参考

# %% [29] markdown
# - 本Julia库的灵感来源：[Promises.jl/src/notebook.jl](https://github.com/fonsp/Promises.jl/blob/main/src/notebook.jl)
#     - 源库使用了 [**Pluto.jl**](https://github.com/fonsp/Pluto.jl) 的「笔记本导出」功能
# - **Jupyter Notebook** 文件格式（JSON）：[🔗nbformat.readthedocs.io](https://nbformat.readthedocs.io/en/latest/format_description.html#notebook-file-format)

# %% [30] markdown
# <!-- README-end -->
# 
# ⚠️该单元格首行注释用于截止生成`README.md`（包括自身）

# %% [31] markdown
# ## 建立模块上下文

# %% [32] markdown
# 📌使用 `# %only-compiled` 控制 `module` 代码，生成模块上下文

# %% [33] code
# ! ↓这后边注释的代码只有在编译后才会被执行
# ! 使用多行注释/块注释的语法，
# !     以`#= %only-compiled`行*开头*
# !     以`%only-compiled =#`行*结尾*
"""
IpynbCompile 主模块
"""
module IpynbCompile # 后续编译后会变为模块上下文


# %% [34] markdown
# ## 模块前置

# %% [35] markdown
# 导入库

# %% [36] code
import JSON

# %% [37] markdown
# 预置语法糖

# %% [38] code
"JSON常用的字典"
const JSONDict{ValueType} = Dict{String,ValueType} where ValueType

"默认解析出来的JSON字典（与`JSONDict`有本质不同，会影响到后续方法分派，并可能导致歧义）"
const JSONDictAny = JSONDict{Any}

# %% [39] markdown
# ## 读取解析Jupyter笔记本（`.ipynb`文件）

# %% [40] markdown
# ### 读取文件（JSON）

# %% [41] code
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


# %% [42] markdown
# ### 解析文件元信息

# %% [43] markdown
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

# %% [44] markdown
# Jupyter Notebook Cell 格式参考
# 
# 共有：
# 
# ```yaml
# {
#     "cell_type": "type",
#     "metadata": {},
#     "source": "single string or [list, of, strings]",
# }
# ```
# 
# Markdown：
# 
# ```yaml
# {
#     "cell_type": "markdown",
#     "metadata": {},
#     "source": "[multi-line *markdown*]",
# }
# ```
# 
# 代码：
# 
# ```yaml
# {
#     "cell_type": "code",
#     "execution_count": 1,  # integer or null
#     "metadata": {
#         "collapsed": True,  # whether the output of the cell is collapsed
#         "scrolled": False,  # any of true, false or "auto"
#     },
#     "source": "[some multi-line code]",
#     "outputs": [
#         {
#             # list of output dicts (described below)
#             "output_type": "stream",
#             # ...
#         }
#     ],
# }
# ```

# %% [45] markdown
# 当前Julia笔记本 元数据：
# 
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
# 
# （截止至2024-01-16）


# %% [47] markdown
# ## 解析Jupyter笔记本（Julia `struct`）

# %% [48] markdown
# ### 定义「笔记本」结构

# %% [49] code
export IpynbNotebook, IpynbNotebookMetadata

"""
定义一个Jupyter Notebook的metadata结构
- 🎯规范化存储Jupyter Notebook的元数据
    - 根据官方文档，仅存储【已经确定存在】的「语言信息」和「内核信息」
"""
@kwdef struct IpynbNotebookMetadata # !【2024-01-14 16:09:35】目前只发现这两种信息
    "语言信息"
    language_info::JSONDictAny
    "内核信息"
    kernelspec::JSONDictAny
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


# %% [50] markdown
# ### 读取笔记本 总函数

# %% [51] code
export read_notebook

"从路径读取Jupyter笔记本（`struct IpynbNotebook`）"
read_notebook(path::AbstractString)::IpynbNotebook = IpynbNotebook(read_ipynb_json(path))

# %% [52] markdown
# ### 解析/生成 笔记本信息

# %% [53] markdown
# #### 识别编程语言

# %% [54] code
"【内部】编程语言⇒正则表达式 识别字典"
const LANG_IDENTIFY_DICT::Dict{Symbol,Regex} = Dict{Symbol,Regex}(
    lang => Regex("^(?:$regex_str)\$") # ! ←必须头尾精确匹配（不然就会把`JavaScript`认成`r`）
    for (lang::Symbol, regex_str::String) in
# ! 以下「特殊注释」需要在行首
# ! be included in: IpynbCompile.jl @ module IpynbCompile
# 其值看似作为正则表达式，实则后续需要变为「头尾精确匹配」
#= 实际上这里只需一个Julia数组 =# [
    :ahk                => "AutoHotKey|autohotkey|AHK|ahk"
    :autoit             => "AutoIt|autoit"
    :bat                => "Bat|bat"
    :c                  => "[Cc]([Ll]ang)?"
    :clojure            => "Clojure|clojure"
    :coffeescript       => "CoffeeScript|Coffeescript|coffeescript"
    :cpp                => raw"[Cc](\+\+|[Pp][Pp]|plusplus)"
    :crystal            => "Crystal|crystal"
    :csharp             => "[Cc](#|[Ss]harp)"
    :d                  => "[Dd]"
    :dart               => "Dart|dart"
    :fortran            => "Fortran|fortran"
    :fortran_fixed_form => "fortran-fixed-form|fortran_fixed-form"
    :fortran_free_form  => "FortranFreeForm"
    :fortran_modern     => "fortran-modern"
    :fsharp             => "[Ff](#|[Ss]harp)"
    :go                 => "Go|Golang|GoLang|go"
    :groovy             => "Groovy|groovy"
    :haskell            => "Haskell|haskell"
    :haxe               => "Haxe|haxe"
    :java               => "Java|java"
    :javascript         => "JavaScript|Javascript|javascript|JS|js"
    :julia              => "Julia|julia"
    :kit                => "Kit|kit"
    :less               => "LESS|less"
    :lisp               => "LISP|lisp"
    :lua                => "Lua|lua"
    :nim                => "Nim|nim"
    :objective_c        => "Objective-[Cc]|objective-[Cc]|[Oo]bj-[Cc]"
    :ocaml              => "OCaml|ocaml"
    :pascal             => "Pascal|pascal"
    :perl               => "Perl|perl"
    :perl6              => "Perl6|perl6"
    :php                => "PHP|php"
    :powershell         => "Powershell|powershell"
    :python             => "Python|python"
    :r                  => "[Rr]"
    :racket             => "Racket|racket"
    :ruby               => "Ruby|ruby"
    :rust               => "Rust|rust"
    :sass               => "SASS|sass"
    :scala              => "Scala|scala"
    :scheme             => "Scheme|scheme"
    :scss               => "SCSS|scss"
    :shellscript        => "Shellscript|ShellScript|shellscript"
    :smalltalk          => "Smalltalk|smalltalk"
    :swift              => "Swift|swift"
    :applescript        => "AppleScript|Applescript|applescript"
    :typescript         => "TypeScript|Typescript|typescript|TS|ts"
    :v                  => "[Vv]"
    :vbscript           => "VBScript|vbscript"
    :zig                => "Zig|zig"
]
)


"""
【内部】识别笔记本的编程语言
- @returns 特定语言的`Symbol` | `nothing`（若未找到/不支持）
- 📌目前基于的字段：`metadata.kernelspec.language`
    - 💭备选字段：`metadata.language_info.name`
    - 📝备选的字段在IJava中出现了`Java`的情况，而前者在IJava中仍然保持小写
- 📝Julia的`findXXX`方法，在`Dict`类型上是「基于『值』找『键』」的运作方式
    - key: `findfirst(::Dict{K,V})::K do V [...]`
- ⚠️所谓「使用的编程语言」是基于「笔记本」而非「单元格」的
"""
identify_lang(notebook::IpynbNotebook) = identify_lang(
    # 获取字符串
    get(
        notebook.metadata.kernelspec, "language",
        get(
            notebook.metadata.language_info, "name",
            # ! 默认返回空字串
            ""
        )
    )
)
identify_lang(language_text::AbstractString) = findfirst(LANG_IDENTIFY_DICT) do regex
    contains(language_text, regex)
end # ! 默认返回`nothing`


# %% [55] markdown
# #### 根据编程语言生成注释
# 
# - 生成的注释会用于「行开头」识别
#     - 如：`// %ignore-cell` (C系列)
#     - 如：`# %ignore-cell` (Python/Julia)

# %% [56] code
"【内部】编程语言⇒单行注释"
const LANG_COMMENT_DICT_INLINE::Dict{Symbol,String} = Dict{Symbol,String}()

"【内部】编程语言⇒多行注释开头"
const LANG_COMMENT_DICT_MULTILINE_HEAD::Dict{Symbol,String} = Dict{Symbol,String}()

"【内部】编程语言⇒多行注释结尾"
const LANG_COMMENT_DICT_MULTILINE_TAIL::Dict{Symbol,String} = Dict{Symbol,String}()

# * 遍历表格，生成列表
# * 外部表格的数据结构：`Dict(语言 => [单行注释, [多行注释开头, 多行注释结尾]])`
for (lang::Symbol, (i::String, (m_head::String, m_tail::String))) in (
# ! 以下「特殊注释」需要在行首
# ! be included in: IpynbCompile.jl @ module IpynbCompile
# *【2024-01-16 18:10:05】此映射表目前只用于【依语言】*识别/生成*相应注释
# * 此处只给出部分语言的单行（一个字串，无尾随空格）和多行注释格式（一头一尾两个字串）
# ! 所在的语言必须【同时】具有单行注释与多行注释
#= 后续读取之后建立字典 =# [
    :c                  => ["//", ("/*", "*/")]
    :cpp                => ["//", ("/*", "*/")]
    # :crystal            => []
    # :csharp             => []
    :d                  => ["//", ("/+", "+/")]
    # :dart               => []
    # :fortran            => []
    # :fortran_fixed_form => []
    # :fortran_free_form  => []
    # :fortran_modern     => []
    # :fsharp             => []
    # :go                 => []
    # :groovy             => []
    # :haskell            => []
    # :haxe               => []
    :java               => ["//", ("/*", "*/")]
    :javascript         => ["//", ("/*", "*/")]
    :julia              => ["#", ("#=", "=#")]
    # :kit                => []
    # :less               => []
    # :lisp               => []
    # :lua                => []
    # :nim                => []
    :objective_c        => ["//", ("/*", "*/")]
    # :ocaml              => []
    # :pascal             => []
    # :perl               => []
    # :perl6              => []
    # :php                => []
    # :powershell         => []
    :python             => ["#", ("'''", "'''")] # ! 近似无多行注释（使用多行字串当注释）
    # :r                  => [] # ! 无多行注释
    # :racket             => []
    # :ruby               => []
    # :rust               => []
    # :sass               => []
    # :scala              => []
    # :scheme             => []
    # :scss               => []
    # :shellscript        => []
    # :smalltalk          => []
    # :swift              => []
    # :applescript        => []
    :typescript         => ["//", ("/*", "*/")]
    # :v                  => []
    # :vbscript           => []
    # :zig                => []
]
)
    LANG_COMMENT_DICT_INLINE[lang] = i
    LANG_COMMENT_DICT_MULTILINE_HEAD[lang] = m_head
    LANG_COMMENT_DICT_MULTILINE_TAIL[lang] = m_tail
end

"【内部】生成单行注释 | ⚠️找不到⇒报错"
generate_comment_inline(lang::Symbol) = LANG_COMMENT_DICT_INLINE[lang]

"【内部】生成块注释开头 | ⚠️找不到⇒报错"
generate_comment_multiline_head(lang::Symbol) = LANG_COMMENT_DICT_MULTILINE_HEAD[lang]

"【内部】生成块注释结尾 | ⚠️找不到⇒报错"
generate_comment_multiline_tail(lang::Symbol) = LANG_COMMENT_DICT_MULTILINE_TAIL[lang]



# %% [57] markdown
# #### 生成常用扩展名

# %% [58] code
"【内部】编程语言⇒常用扩展名（不带`.`）"
const LANG_EXTENSION_DICT::Dict{Symbol,String} = Dict{Symbol,String}(
# ! 以下「特殊注释」需要在行首
# ! be included in: IpynbCompile.jl @ module IpynbCompile
# * 记录【未指定路径时】从语言到扩展名的映射 | 一般是常见扩展名 | 不带「.」 | 注释为【不确定】项
#= 实际上这里只需一个Julia数组 =# [
    # :ahk                => "ahk"
    # :autoit             => "autoit"
    # :bat                => "bat"
    :c                  => "c"
    # :clojure            => "clj"
    # :coffeescript       => "coffeescript"
    :cpp                => "cpp"
    # :crystal            => "crystal"
    # :csharp             => "csharp"
    # :d                  => "d"
    # :dart               => "dart"
    # :fortran            => "fortran"
    # :fortran_fixed_form => "fortran_fixed_form"
    # :fortran_free_form  => "fortran_free_form"
    # :fortran_modern     => "fortran_modern"
    # :fsharp             => "fsharp"
    # :go                 => "go"
    # :groovy             => "groovy"
    # :haskell            => "haskell"
    # :haxe               => "haxe"
    :java               => "java"
    :javascript         => "js"
    :julia              => "jl"
    # :kit                => "kit"
    # :less               => "less"
    # :lisp               => "lisp"
    # :lua                => "lua"
    # :nim                => "nim"
    # :objective_c        => "objective_c"
    # :ocaml              => "ocaml"
    # :pascal             => "pascal"
    # :perl               => "perl"
    # :perl6              => "perl6"
    :php                => "php"
    # :powershell         => "powershell"
    :python             => "py"
    :r                  => "r"
    # :racket             => "racket"
    # :ruby               => "ruby"
    # :rust               => "rust"
    # :sass               => "sass"
    # :scala              => "scala"
    # :scheme             => "scheme"
    # :scss               => "scss"
    # :shellscript        => "shellscript"
    # :smalltalk          => "smalltalk"
    # :swift              => "swift"
    # :applescript        => "applescript"
    :typescript         => "ts"
    # :v                  => "v"
    # :vbscript           => "vbscript"
    # :zig                => "zig"
]
)


"""
【内部】根据编程语言猜测扩展名
- @returns 特定语言的`Symbol` | 语言本身的字符串形式
    - @default 如`:aaa => "aaa"`
"""
get_extension(lang::Symbol) = get(
    LANG_EXTENSION_DICT, lang,
    string(lang)
)



# %% [59] markdown
# #### 解析/生成 测试


# %% [61] markdown
# ### Notebook编译/头部注释
# 
# - 🎯标注 版本信息
# - 🎯标注 各类元数据

# %% [62] code
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
compile_notebook_head(notebook::IpynbNotebook; lang::Symbol, kwargs...) = """\
$(generate_comment_inline(lang)) %% Jupyter Notebook | $(notebook.metadata.kernelspec["display_name"]) \
@ $(notebook.metadata.language_info["name"]) | \
format $(notebook.nbformat_minor)~$(notebook.nbformat)
$(generate_comment_inline(lang)) % language_info: $(JSON.json(notebook.metadata.language_info))
$(generate_comment_inline(lang)) % kernelspec: $(JSON.json(notebook.metadata.kernelspec))
$(generate_comment_inline(lang)) % nbformat: $(notebook.nbformat)
$(generate_comment_inline(lang)) % nbformat_minor: $(notebook.nbformat_minor)
"""



# %% [63] markdown
# ## 解析处理单元格

# %% [64] markdown
# ### 定义「单元格」结构

# %% [65] code
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



# %% [66] markdown
# ## 编译单元格

# %% [67] markdown
# ### 编译/入口

# %% [68] code
export compile_cell

"""
【入口】将一个单元格编译成代码（包括注释）
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
【入口】将多个单元格编译成代码（包括注释）
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

# %% [69] markdown
# ### 编译/单元格标头

# %% [70] code
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
compile_cell_head(cell::IpynbCell; lang::Symbol, kwargs...) = """\
$(generate_comment_inline(lang)) %% \
$(#= 可选的行号 =# haskey(kwargs, :line_num) ? "[$(kwargs[:line_num])] " : "")\
$(cell.cell_type)
""" # ! ←末尾附带换行符



# %% [71] markdown
# ### 编译/Markdown

# %% [72] code
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
compile_cell(::Val{:markdown}, cell::IpynbCell; lang::Symbol, kwargs...) = """\
$(#= 附带标头 =# compile_cell_head(cell; lang, kwargs...))\
$(join(
    "$(generate_comment_inline(lang)) $md_line"
    for md_line in cell.source
) #= ←此处无需附加换行符，`md_line`已自带 =#)
""" # ! ↑末尾附带换行符



# %% [73] markdown
# ### 编译/代码


# %% [75] markdown
# 主编译方法

# %% [76] code
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
- 📌在此开始执行各种「行编译逻辑」（具体用法参考先前文档）
- ⚠️编译后的文本是「每行都有换行符」
    - 对最后一行增加了换行符，以便和先前所有行一致
- @param cell 所需编译的单元格
- @param kwargs 其它附加信息（如行号）
- @return 编译后的源码 | nothing（表示「完全不呈现单元格」）
"""
function compile_code_lines(cell::IpynbCell;
    # 所使用的编程语言
    lang::Symbol,
    # 根路径（默认为「执行编译的文件」所在目录）
    root_path::AbstractString=@__DIR__,
    # 其它参数
    kwargs...)

    local lines::Vector{String} = cell.source
    local len_lines = length(lines)
    local current_line_i::Int = firstindex(lines)
    local current_line::String
    local result::String = ""

    while current_line_i <= len_lines
        current_line = lines[current_line_i]
        # * `%ignore-line` 忽略下一行 | 仅需为行前缀
        if startswith(current_line, "$(generate_comment_inline(lang)) %ignore-line")
            current_line_i += 1 # ! 结合后续递增，跳过下面一行，不让本「特殊注释」行被编译
        # * `%ignore-below` 忽略下面所有行 | 仅需为行前缀
        elseif startswith(current_line, "$(generate_comment_inline(lang)) %ignore-below")
            break # ! 结束循环，不再编译后续代码
        # * `%ignore-cell` 忽略整个单元格 | 仅需为行前缀
        elseif startswith(current_line, "$(generate_comment_inline(lang)) %ignore-cell")
            return nothing # ! 返回「不编译单元格」的信号
        # * `%include` 读取其所指定的路径，并将其内容作为「当前行」添加（不会自动添加换行！） | 仅需为行前缀
        elseif startswith(current_line, "$(generate_comment_inline(lang)) %include")
            # 在指定的「根路径」参数下行事 # * 无需使用`@inline`，编译器会自动内联
            local relative_path = current_line[nextind(current_line, 1, length("$(generate_comment_inline(lang)) %include ")):end] |> rstrip # ! ←注意`%include`后边有个空格
            # 读取内容
            local content::String = read(joinpath(root_path, relative_path), String)
            result *= content # ! 不会自动添加换行！
        # * `%ignore-begin` 跳转到`%ignore-end`的下一行，并忽略中间所有行 | 仅需为行前缀
        elseif startswith(current_line, "$(generate_comment_inline(lang)) %ignore-begin")
            # 只要后续没有以"$(generate_comment_inline(lang)) %ignore-end"开启的行，就不断跳过
            while !startswith(lines[current_line_i], "$(generate_comment_inline(lang)) %ignore-end") && current_line_i <= len_lines
                current_line_i += 1 # 忽略性递增
            end # ! 让最终递增跳过"# %ignore-end"所在行
        # * `%only-compiled` 仅编译后可用（多行） | 仅需为行前缀
        elseif (
            startswith(current_line, "$(generate_comment_multiline_head(lang)) %only-compiled") ||
            startswith(current_line, "%only-compiled $(generate_comment_multiline_tail(lang))")
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



# %% [77] markdown
# ## 解析执行单元格

# %% [78] markdown
# 🎯将单元格解析**编译**成Julia表达式，并可直接作为代码执行
# - 【核心】解释：`parse_cell`
#     - 📌基本是`compile_cell` ∘ `Meta.parse`的复合
#     - 对无法执行的单元格 ⇒ return `nothing`
#         - 如markdown单元格
#     - 可执行单元格 ⇒ Expr
#         - 如code单元格
# - 执行：`eval_cell`
#     - 📌基本是`parse_cell` ∘ `eval`的复合
#     - ⚙️可任意指定其中的`eval`函数

# %% [79] code
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




# %% [81] markdown
# ## 编译笔记本

# %% [82] code
export compile_notebook

"""
编译整个笔记本
- 🎯编译整个笔记本对象，形成相应Julia代码
- 📌整体文本：头部注释+各单元格编译（逐个join(_, '\\n')）
- ⚠️末尾不会附加换行符
- @param notebook 要编译的笔记本对象
- @return 编译后的文本
"""
compile_notebook(
    notebook::IpynbNotebook; 
    # 自动识别语言
    lang=identify_lang(notebook), 
    kwargs...
) = """\
$(compile_notebook_head(notebook; lang, kwargs...))
$(compile_cell(notebook.cells; lang, kwargs...))
""" # ! `$(compile_notebook_head(notebook))`在原本的换行下再空一行，以便与后续单元格分隔

"""
编译整个笔记本，并【写入】指定路径
- @param notebook 要编译的笔记本对象
- @param path 要写入的路径
- @return 写入结果
"""
compile_notebook(notebook::IpynbNotebook, path::AbstractString; kwargs...) = write(
    # 使用 `write`函数，自动写入编译结果
    path, 
    # 传入前编译
    compile_notebook(notebook; kwargs...)
)

"""
编译指定路径的笔记本，并写入指定路径
- @param path 要读取的路径
- @return 写入结果
"""
compile_notebook(path::AbstractString, destination; kwargs...) = compile_notebook(
    # 直接使用构造函数加载笔记本
    IpynbNotebook(path), 
    # 保存在目标路径
    destination;
    # 其它附加参数 #
    # 自动从`path`构造编译根目录
    root_path=dirname(path),
)

"""
编译指定路径的笔记本，并根据读入的笔记本【自动追加相应扩展名】
- @param path 要读取的路径
- @return 写入结果
"""
function compile_notebook(path::AbstractString; kwargs...)
    # 直接使用构造函数加载笔记本
    local notebook::IpynbNotebook = IpynbNotebook(path)
    # 返回
    return compile_notebook(
        notebook,
        # 根据语言自动追加扩展名
        destination="$path.$(IpynbCompile.get_extension(lang))";
        # 其它附加参数 #
        # 自动从`path`构造编译根目录
        root_path=dirname(path),
    )
end



# %% [83] markdown
# ## 解析执行笔记本

# %% [84] markdown
# 执行笔记本

# %% [85] code
export eval_notebook, eval_notebook_by_cell

"""
【整个】解释并执行Jupyter笔记本
- 📌直接使用`eval_cell`对笔记本的所有单元格进行解释执行
    - 可以实现一些「编译后可用」的「上下文相关代码」
        - 如「将全笔记本代码打包成一个模块」
"""
eval_notebook(notebook::IpynbNotebook; kwargs...) = eval_cell(
    notebook.cells;
    # 自动识别语言
    lang=identify_lang(notebook),
    # 其它附加参数（如「编译根目录」）
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
        result = eval_cell(cell; kwargs...)
    end
    # 返回最后一个结果
    return result
end

# ! 测试代码放在最后边

# %% [86] markdown
# 引入笔记本

# %% [87] code
export include_notebook, include_notebook_by_cell

"""
从【字符串】路径解析并【整个】编译执行整个笔记本的代码
- 📌「执行笔记本」已经有`eval_notebook`支持了
- 🎯直接解析并执行`.ipynb`文件
- 📌先加载并编译Jupyter笔记本，再【整个】执行其所有单元格
- 会像`include`一样返回「最后一个执行的单元格的返回值」
"""
include_notebook(path::AbstractString; kwargs...) = eval_notebook(
    path |> 
    read_ipynb_json |> 
    IpynbNotebook{IpynbCell};
    # 其它附加参数（如「编译根目录」）
    kwargs...
)

"""
解析并【逐单元格】执行整个笔记本的代码
- 📌「执行笔记本」已经有`eval_notebook_by_cell`支持了
- 🎯直接解析并执行`.ipynb`文件
- 📌先加载并编译Jupyter笔记本，再【逐个】执行其单元格
- ⚠️不会记录单元格执行的【中间】返回值
    - 但正如`include`一样，「最后一个执行的单元格的返回值」仍然会被返回
"""
include_notebook_by_cell(path::AbstractString; kwargs...) = eval_notebook_by_cell(
    path |> 
    read_ipynb_json |> 
    IpynbNotebook{IpynbCell};
    # 其它附加参数（如「编译根目录」）
    kwargs...
)



# %% [88] markdown
# ## 关闭模块上下文

# %% [89] code
# ! ↓这后边注释的代码只有在编译后才会被执行
# ! 仍然使用多行注释语法，以便统一格式
end # module


# %% [90] markdown
# ## 自动构建

# %% [91] markdown
# 构建过程主要包括：
# 
# - **自举**构建主模块，生成库文件
# - 扫描`src`目录下基本所有Jupyter笔记本（`.ipynb`），编译生成`.jl`源码
# - 提取该文件开头Markdown笔记，在**项目根目录**下**生成自述文件**（`README.md`）
#     - 因此`README.md`暂且只有一种语言（常更新的语言）
# 
# ⚠️不应该在编译后的库文件中看到任何代码




