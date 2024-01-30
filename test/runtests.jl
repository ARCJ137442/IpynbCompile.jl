# 【附加】使用测试代码
using Test

# ! ↓这后边注释的代码只有在编译后才会被执行
# ! 使用多行注释/块注释的语法，
# !     以`#= %only-compiled`行*开头*
# !     以`%only-compiled =#`行*结尾*
#= %only-compiled # * ←这个仅需作为前缀（⚠️这注释会被一并移除）
"""
IpynbCompile 主模块
"""
module IpynbCompile # 后续编译后会变为模块上下文
%only-compiled =# # * ←左边同理（⚠️这注释会被一并移除）

import JSON

"JSON常用的字典"
const JSONDict{ValueType} = Dict{String,ValueType} where ValueType

"默认解析出来的JSON字典（与`JSONDict`有本质不同，会影响到后续方法分派，并可能导致歧义）"
const JSONDictAny = JSONDict{Any}

#= %only-compiled # ! 模块上下文：导出元素
export read_ipynb_json
%only-compiled =#

"""
读取ipynb JSON文件
- @param path .ipynb文件路径
- @return .ipynb文件内容（JSON文本→Julia对象）
"""
read_ipynb_json(path) = open(path, "r") do f
    read(f, String) |> JSON.parse
end

# ! ↓使用`# %ignore-line`让 编译器/解释器 忽略下一行
# %ignore-line
ROOT_PATH = any(contains(@__DIR__(), sub) for sub in ["src", "test"]) ? dirname(@__DIR__) : @__DIR__
# %ignore-line
SELF_FILE = "IpynbCompile.ipynb"
# %ignore-line # * 行尾可以附带其它注释
SELF_PATH = joinpath(ROOT_PATH, "src", SELF_FILE)
# %ignore-line # * 但每行都需要一个注释
notebook_json = read_ipynb_json(SELF_PATH)

# %ignore-cell # ! ←使用`# %ignore-line`让 编译器/解释器 忽略整个单元格
# * ↑建议放在第一行
# ! ⚠️该代码不能有其它冗余的【前缀】字符

let metadata = notebook_json["metadata"],
    var"metadata.language_info" = metadata["language_info"]
    var"metadata.kernelspec" = metadata["kernelspec"]
    @info "notebook_json" notebook_json
    @info "notebook_json.metadata" metadata
    @info "metadata[...]" var"metadata.language_info" var"metadata.kernelspec"
end

#= %only-compiled # ! 模块上下文：导出元素
export IpynbNotebook, IpynbNotebookMetadata
%only-compiled =#

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

# %ignore-begin # ! ←通过「begin-end」对使用「块忽略」（精确到行）
# ! ↓下面这行仅为测试用，后续将重定向到特制的「笔记本单元格」类型
IpynbNotebook(json) = IpynbNotebook{Any}(json)
# * 这段注释也不会出现在编译后的代码中
# %ignore-end

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
# %ignore-below
notebook_raw_cell = IpynbNotebook(notebook_json)
notebook_metadata = notebook_raw_cell.metadata
@info "JSON转译结构化成功！" notebook_raw_cell notebook_metadata

#= %only-compiled # ! 模块上下文：导出元素
export read_notebook
%only-compiled =#

"从路径读取Jupyter笔记本（`struct IpynbNotebook`）"
read_notebook(path::AbstractString)::IpynbNotebook = IpynbNotebook(read_ipynb_json(path))

#= %only-compiled # ! 模块上下文：导出元素
export @notebook_str
%only-compiled =#

macro notebook_str(path::AbstractString)
    :(read_notebook($path)) |> esc
end
# %ignore-below
@macroexpand notebook"IpynbCompile.ipynb"

"【内部】编程语言⇒正则表达式 识别字典"
const LANG_IDENTIFY_DICT::Dict{Symbol,Regex} = Dict{Symbol,Regex}(
    lang => Regex("^(?:$regex_str)\$") # ! ←必须头尾精确匹配（不然就会把`JavaScript`认成`r`）
    for (lang::Symbol, regex_str::String) in
# ! 以下「特殊注释」需要在行首
# * 下方内容是「执行时动态引入，编译时静态内联」
#= %inline-compiled =# include("./../src/language_identify_dict.data.jl")
# !【2024-01-27 00:48:32】为了兼容自动生成的测试文件`runtests.jl`，需要使用「相对绝对路径」`./../src/`
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
# %ignore-below # ! 测试代码在最下边

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
#= %inline-compiled =# include("./../src/language_comment_forms.data.jl")
# *【2024-01-26 21:43:27】统一了类似「执行时加载，编译后内联」的机制，
# * @example `#= %inline-compiled =# include("language_comment_forms.data.jl")`
# * 其中`compiled`表示「编译后」，`inline`表示「内联」
# !【2024-01-27 00:48:32】为了兼容自动生成的测试文件`runtests.jl`，需要使用「相对绝对路径」`./../src/`
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

# %ignore-below # ! 测试代码在最下边
@info "" LANG_COMMENT_DICT_INLINE LANG_COMMENT_DICT_MULTILINE_HEAD LANG_COMMENT_DICT_MULTILINE_TAIL

"【内部】编程语言⇒常用扩展名（不带`.`）"
const LANG_EXTENSION_DICT::Dict{Symbol,String} = Dict{Symbol,String}(
# ! 以下「特殊注释」需要在行首
#= %inline-compiled =# include("./../src/language_extension_dict.data.jl")
# !【2024-01-27 00:48:32】为了兼容自动生成的测试文件`runtests.jl`，需要使用「相对绝对路径」`./../src/`
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

# %ignore-below # ! 测试代码在最下边
@info "" LANG_EXTENSION_DICT

# %ignore-cell
let path_examples(path) = joinpath(ROOT_PATH, "examples", path),
    notebooks = [
        #= C =# path_examples("c.ipynb")
        #= Java =# path_examples("java.ipynb")
        #= Julia =# SELF_PATH # * 直接使用自身
        #= Python =# path_examples("python.ipynb")
        #= TypeScript =# path_examples("typescript.ipynb")
    ] .|> read_ipynb_json .|> IpynbNotebook
    @test all(identify_lang.(notebooks) .== [
        :c
        :java
        :julia
        :python
        :typescript
    ])
    
    langs = identify_lang.(notebooks)
    @info "识别到的所有语言" langs
    
    table_comments = [langs generate_comment_inline.(langs) generate_comment_multiline_head.(langs) generate_comment_multiline_tail.(langs)]
    @info "生成的所有注释 [语言 单行 多行开头 多行结尾]" table_comments

    @info "生成的常见扩展名 [语言 扩展名]" [langs get_extension.(langs)]
end

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

# %ignore-below
# ! ↑使用`# %ignore-below`让 编译器/解释器 忽略后续内容 | 【2024-01-26 21:38:54】debug：笔记本可能在不同的电脑上运行
let notebook_jl_head = compile_notebook_head(notebook_raw_cell; lang=:julia)
    @test contains(notebook_jl_head, r"""
    # %% Jupyter Notebook \| [A-Za-z0-9. ]+ @ [A-Za-z0-9]+ \| format [0-9]+~[0-9]+
    # % language_info: \{[^}]+\}
    # % kernelspec: \{[^}]+\}
    # % nbformat: [0-9]+
    # % nbformat_minor: [0-9]+
    """)
    notebook_jl_head |> print
end

#= %only-compiled # ! 模块上下文：导出元素
export IpynbCell
%only-compiled =#

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

#= %only-compiled # ! 模块上下文：导出元素
export @cell_str
%only-compiled =#

"🎯将字符串拆分成单元格各行（区分末尾换行）"
function split_to_cell(text::AbstractString)::Vector{String}
    local result::Vector{String} = []
    local line_head_i::Int = 1
    # 递增遍历每个索引
    for i in eachindex(text)
        # 换行符⇒切分
        if text[i] === '\n'
            # 加入内容
            push!(result, String(text[line_head_i:i]))
            # 行头递进
            line_head_i = nextind(text, i, 1)
        end
    end
    # 处理末尾无换行的情况：要么超出，要么包括进去
    line_head_i > length(text) || push!(result, String(text[line_head_i:end]))
    # 返回
    return result
end

"""
用于快速构建Jupyter笔记本单元格的字符串宏
"""
macro cell_str(content::AbstractString, cell_type::String="code")
    return :(
        IpynbCell(;
            cell_type=$cell_type,
            source=$(split_to_cell(content))
        )
    ) |> esc
end

# %ignore-below
let a1 = split_to_cell("""1\n2\n3"""), # 📌测试【末尾有无换行】的区别
    a2 = split_to_cell("""1\n2\n3\n""")
    @test a1 == ["1\n", "2\n", "3"]
    @test a2 == ["1\n", "2\n", "3\n"]
end

let cell = cell"""
    # 这是个标题
    第二行是内容
    """markdown # ! 末尾有个空行，最后一行会多出换行符↓
    @test cell.source == ["# 这是个标题\n", "第二行是内容\n"]
    @test cell.cell_type == "markdown"
    @show cell
    @macroexpand cell"# 1"markdown
end

# ! 在此重定向，以便后续外部调用
"重定向「笔记本」的默认「单元格」类型"
IpynbNotebook(json) = IpynbNotebook{IpynbCell}(json)

# %ignore-below
notebook = IpynbNotebook{IpynbCell}(notebook_json)
cells = notebook.cells

#= %only-compiled # ! 模块上下文：导出元素
export compile_cell
%only-compiled =#

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

# %ignore-below
@test compile_cell_head(notebook.cells[1]; lang=:julia) == "# %% markdown\n"
@test compile_cell_head(notebook.cells[1]; lang=:julia, line_num=1) == "# %% [1] markdown\n"

# %ignore-cell # * 列举自身的所有代码单元格
codes = filter(cells) do cell
    cell.cell_type == "code"
end

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
    $code
    """ # ! ↑编译后的`code`不在最后一行附加换行符
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
    kwargs...)::Union{String,Nothing}

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
        # * `#= %inline-compiled =# include(` 读取后边`include`指定的路径，并将其内容作为「当前行」添加（不会自动添加换行！） | 仅需为行前缀
        elseif startswith(current_line, "$(generate_comment_multiline_head(lang)) %inline-compiled $(generate_comment_multiline_tail(lang)) include(")
            # 直接作为Julia代码解析
            local expr::Expr = Meta.parse(current_line)
            #= # * 在Expr中提取相应字符串 | 参考:
            julia> :(include("123")) |> dump
            Expr
            head: Symbol call
            args: Array{Any}((2,))
                1: Symbol include
                2: String "123"
            =#
            if expr.head == :call && expr.args[1] == :include && length(expr.args) > 1
                # 在指定的「根路径」参数下行事 # * 无需使用`@inline`，编译器会自动内联
                relative_path = expr.args[2]
                # 读取内容 | if内不再要用local，和上级表达式重复
                content = read(joinpath(root_path, relative_path), String)
                result *= content # ! 不会自动添加换行！
            else # 若非`include(路径)`的形式⇒警告
                @warn "非法表达式，内联失败！" current_line expr
            end
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

    # 最后返回所有行 # ! 「在最后一行和先前所有行的换行符一致」在行编译后方运行
    return result
end

# %ignore-below

let 引入路径 = joinpath(ROOT_PATH, "test", "%include.test.jl")
    # 放置测试脚本
    预期引入内容 = """\
    # 这是一段会被`# %include`引入编译后笔记本的内容
    println("Hello World")\
    """
    ispath(引入路径) || write(引入路径, 预期引入内容)
    # 现场编译
    引入后内容 = compile_code_lines(
        IpynbCell(; 
            cell_type="code", 
            source=["# %include $引入路径"]
        );
        lang=:julia
    )
    @test rstrip(引入后内容) == 预期引入内容 # rstrip(引入后内容) # !【2024-01-27 00:50:55】为后期兼容`runtests.jl`，不能引入第二个参数
    println(引入后内容)
end

printstyled("↓现在预览下其中所有代码的部分\n"; bold=true, color=:light_green)

# * ↓现在预览下其中所有代码的部分
compile_cell(codes; lang=:julia) |> print

"""
对Markdown的编译
- 📌主要方法：转换成多个单行注释
- ✨不对Markdown单元格作过于特殊的处理
    - 仅将其视作语言为 `markdown` 的源码
    - 仅在编译后作为程序语言注释

@example IpynbCell("markdown", ["# IpynbCompile.jl: 一个通用的Jupyter笔记本集成编译工具"], Dict{String, Any}(), nothing)
（行号为1）将被转换为
```julia
# %% [1] markdown
# # IpynbCompile.jl: 一个通用的Jupyter笔记本集成编译工具
```
# ↑末尾附带换行符
"""
function compile_cell(::Val{:markdown}, cell::IpynbCell; lang::Symbol, kwargs...)
    local code::Union{String,Nothing} = compile_code_lines(
        cell; # * 直接使用原单元格
        lang=:markdown
    ) # * 行作为Markdown代码编译后，不会附带换行符
    # 空⇒返回空字串
    isnothing(code) && return ""
    # 非空⇒返回
    return """\
    $(#= 附带标头 =# compile_cell_head(cell; lang, kwargs...))\
    $(
        generate_comment_inline(lang) * ' ' * 
        replace(code, '\n' => '\n' * generate_comment_inline(lang) * ' ')
    )
    """ # ! ↑末尾附带换行符
end

# %ignore-below
let cell = cells[1]
    local compiled::String = @show compile_cell(cell; lang=:julia, line_num = 1)
    @test contains(compiled, r"""
    # %% \[1\] markdown
    # # IpynbCompile\.jl: [^\n]+
    """)
    compiled |> println
end

let cell = cell"""
    前边的内容也会被忽略
    <!-- %ignore-cell 可以使用Markdown风格的注释 -->
    后边的内容，仍然被忽略
    """markdown
    local compiled::String = compile_cell(cell; lang=:julia, line_num = 1)
    @test isempty(compiled) # 编译后为空
    compiled |> println
end

let cell = cell"""
    这些内容不会被忽略
    <!-- %ignore-below 可以使用Markdown风格的注释 -->
    后边的内容，
    全部被忽略！
    """markdown
    local compiled::String = compile_cell(cell; lang=:julia, line_num = 1)
    @test compiled == """\
    # %% [1] markdown
    # 这些内容不会被忽略
    # 
    """
    compiled |> println
end

#= %only-compiled # ! 模块上下文：导出元素
export parse_cell, tryparse_cell, eval_cell
%only-compiled =#

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
    Base.showerror(stderr, e, Base.catch_backtrace())
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

# %ignore-below

# 执行其中一个代码单元格 # * 参考「预置语法糖」
eval_cell(codes[3]; lang=:julia)::Base.Docs.Binding

# 尝试对每个单元格进行解析
[
    tryparse_cell(cell; lang=:julia, line_num=i)
    for (i, cell) in enumerate(codes)
]

# %ignore-cell # * ↓ 不提供语言，会报错但静默失败
tryparse_cell(codes#= ; lang=:julia =#)

#= %only-compiled # ! 模块上下文：导出元素
export compile_notebook
%only-compiled =#

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
以「配对」方式进行展开，允许同时编译多个笔记本
- 🎯支持形如`compile_notebook(笔记本1 => 目标1, 笔记本2 => 目标2)`的语法
- 📌无论在此的「笔记本」「目标」路径还是其它的
"""
function compile_notebook(pairs::Vararg{Pair})
    for pair in pairs
        compile_notebook(first(pair), last(pair))
    end
end

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
        # 根据语言自动追加扩展名，作为目标路径
        "$path.$(get_extension(identify_lang(notebook)))";
        # 其它附加参数 #
        # 自动从`path`构造编译根目录
        root_path=dirname(path),
    )
end

# %ignore-below
compile_notebook(notebook) |> print

#= %only-compiled # ! 模块上下文：导出元素
export eval_notebook, eval_notebook_by_cell
%only-compiled =#

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

#= %only-compiled # ! 模块上下文：导出元素
export include_notebook, include_notebook_by_cell
%only-compiled =#

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

# %ignore-below

# * 递回执行自身代码（自举）
include_notebook(SELF_PATH)

# 检验是否成功导入
@test @isdefined IpynbCompile # ! 模块上下文生效：所有代码现在都在模块之中
printstyled("✅Jupyter笔记本文件引入完成，模块导入成功！\n"; color=:light_green, bold=true)
@show IpynbCompile
println()

# * 打印导出的所有符号
printstyled("📜以下为IpynbCompile模块导出的所有$(length(names(IpynbCompile)))个符号：\n"; color=:light_blue, bold=true)
for name in names(IpynbCompile)
    println(name)
end

# ! ↓这后边注释的代码只有在编译后才会被执行
# ! 仍然使用多行注释语法，以便统一格式
#= %only-compiled
end # module
%only-compiled =#

# %ignore-cell # * 自举构建主模块
# * 自编译生成`.jl`源码
let OUT_LIB_FILE = "IpynbCompile.jl" # 直接作为库的主文件
    # !不能在`runtests.jl`中运行
    contains(@__DIR__, "test") && return
    
    write_bytes = compile_notebook(SELF_PATH, joinpath(ROOT_PATH, "src", OUT_LIB_FILE))
    printstyled(
        "✅Jupyter笔记本「主模块」自编译成功！\n（共写入 $write_bytes 个字节）\n";
        color=:light_yellow, bold=true
    )
end

# %ignore-cell
# * 扫描`src`目录，自动构建主模块
# * - 📝Julia 文件夹遍历：`walkdir`迭代器
# * - 🔗参考：参考：https://stackoverflow.com/questions/58258101/how-to-loop-through-a-folder-of-sub-folders-in-julia
PATH_SRC = "."
let root_folder = PATH_SRC

    # !不能在`runtests.jl`中运行
    contains(@__DIR__, "test") && return

    local path::AbstractString, new_path::AbstractString

    # 遍历src目录下所有文件 # ! 包括间接子路径（故无需递归）
    for (root, dirs, file_names) in walkdir(root_folder),
        file_name in file_names
        # 只编译非自身文件
        file_name == SELF_FILE && continue
        # 拼接获取路径
        path = joinpath.(root, file_name)
        # * 只为Jupyter笔记本（`*.ipynb`）⇒编译
        endswith(path, ".ipynb") || continue
        # 计算目标路径 | 替换末尾扩展名
        new_path = replace(path, r".ipynb$" => ".jl") # 固定编译成Julia源码
        # 编译
        compile_notebook(
            path => new_path # * 测试Pair
            # ! 根目录后续会由`path`自行指定
        )
        # 输出编译结果
        printstyled(
            "Compiled: $path => $new_path\n";
            color=:light_green, bold=true
        )
    end
end

# %ignore-cell # * 自举构建主模块
if !contains(@__DIR__, "test") # 不能在测试代码中被重复调用
    OUT_TEST_JL = joinpath(ROOT_PATH, "test", "runtests.jl") # 直接作为库的主文件
    # 直接拼接所有代码单元格
    code_tests = join((
        join(cell.source)
        for cell in notebook.cells
        if cell.cell_type == "code"
    ), "\n\n")
    # 开头使用Test库，并添加测试上下文
    code_tests = """\
    # 【附加】使用测试代码
    using Test
    
    """ * code_tests
    # @testset "main" begin # !【2024-01-27 01:23:08】停用，会导致无法使用其内的宏`cell_str`
    # 替换所有的`@test`为`@test`
    code_tests = replace(code_tests, "@test" => "@test")
    # 注释掉所有的`write`写入代码（单行）
    code_tests = replace(
        code_tests, 
        # * 📝Julia中的「捕获-映射」替换：传入一个函数✅
        r"\n *write\(([^\n]+)\)(?:\n|$)" => "\n#= 文件读写已忽略 =#\n"
    )
    #= # 关闭测试上下文 # !【2024-01-27 01:23:08】停用，会导致无法使用其内的宏`cell_str`
    code_tests *= """
    end
    """ =#
    # 最终写入
    write_bytes = write(OUT_TEST_JL, code_tests)
    printstyled(
        "✅测试文件编译成功！\n（共写入 $write_bytes 个字节）\n";
        color=:light_green, bold=true
    )
end

# %ignore-cell # * 扫描自身Markdown单元格，自动生成`README.md`
"决定「单元格采集结束」的标识" # ! 不包括结束处单元格
FLAG_END = "<!-- README-end" # 只需要开头
FLAG_IGNORE = "<!-- README-ignored" # 只需要开头

# * 过滤Markdown单元格
markdowns = filter(notebook.cells) do cell
    cell.cell_type == "markdown"
end
# * 截取Markdown单元格 | 直到开头有`FLAG_END`标记的行（不考虑换行符）
README_END_INDEX = findlast(markdowns) do cell
    !isempty(cell.source) && any(
        startswith(line, FLAG_END)
        for line in cell.source
    )
end
README_markdowns = markdowns[begin:README_END_INDEX-1]

# * 提取Markdown代码，聚合生成原始文档
README_markdown_TEXT = join((
    join(cell.source) * '\n' # ←这里需要加上换行
    for cell in README_markdowns
    # * 根据【空单元格】或【任一行注释】进行忽略
    if !(isempty(cell.source) || any(
        startswith(line, FLAG_IGNORE)
        for line in cell.source
    ))
), '\n')

# * 继续处理：缩进4→2，附加注释
README_markdown_TEXT = join((
    begin
        local space_stripped_line = lstrip(line, ' ')
        local head_space_length = length(line) - length(space_stripped_line)
        # 缩进缩减到原先的一半
        ' '^(head_space_length ÷ 2) * space_stripped_line
    end
    for line in split(README_markdown_TEXT, '\n')
), '\n')
using Dates: now # * 增加日期注释（不会在正文显示）
README_markdown_TEXT = """\
<!-- ⚠️该文件由 `$SELF_FILE` 自动生成于 $(now())，无需手动修改 -->
$README_markdown_TEXT\
"""
print(README_markdown_TEXT)

README_FILE = "README.md"
#= 文件读写已忽略 =#
