# %% Jupyter Notebook | Julia 1.9.1 @ julia | format 2~4
# % language_info: {"file_extension":".jl","mimetype":"application/julia","name":"julia","version":"1.9.1"}
# % kernelspec: {"name":"julia-1.9","display_name":"Julia 1.9.1","language":"julia"}
# % nbformat: 4
# % nbformat_minor: 2

# %% [1] markdown
# # IpynbCompile.jl 交互式命令行

# %% [2] markdown
# **✨执行其中所有单元格，可自动构建、测试并生成相应`.jl`源码**！

# %% [3] markdown
# 主要用途：为 ***IpynbCompile.jl*** 提供交互访问接口
# - 可通过cmd命令行调用
#     - 直接编译 语法：`compiler.ipynb.jl 文件名.ipynb`
# - 可直接打开并进入「交互模式」
#     - 直接键入路径，自动解析、编译并生成`.jl`文件

# %% [4] markdown
# ## 引入模块

# %% [5] code
# 编译后脚本中【直接引入】即可
LIB_IPYNB_PATH = "IpynbCompile.ipynb"
LIB_JL_PATH = "IpynbCompile.jl"
include(LIB_JL_PATH)




# %% [7] markdown
# ## 预置函数

# %% [8] code
try_compile_notebook(path, destination) = try
    printstyled("Compiling \"$path\" => \"$destination\"...\n", color=:white)
    local num_bytes = IpynbCompile.compile_notebook(path, destination)
    # 编译结果
    printstyled("[√] Compiling succeed with $num_bytes bytes!\n", color=:light_green)
catch e
    printstyled("[×] Compiling failed!\n", color=:light_red)
    @error e
    showerror(e)
end

# %% [9] markdown
# ## 处理传入的命令行参数

# %% [10] markdown
# 处理方法：将其中所有参数视作**Jupyter笔记本路径**，直接【编译】成`.jl`文件

# %% [11] code
# ! 📝Julia对「命令行参数」的存储：【不包括】自身路径
function compile_with_ARGS(ARGS=ARGS)
    for path in ARGS
        try_compile_notebook(path)
    end
end

# %% [12] markdown
# ## 交互模式

# %% [13] code
"""
交互模式
- 📌不断请求输入路径
"""
function interactive_mode()
    local path::AbstractString, out_path::AbstractString
    # 开始循环
    while true
        # 请求输入路径 | 空值⇒退出
        printstyled("IpynbCompile> path="; color=:light_cyan, bold=true)
        path = readline()
        # 空路径⇒退出
        if isempty(path)
            printstyled("Compiler exit!\n", color=:light_blue)
            return
        end
        # 先读取笔记本
        printstyled("Reading \"$path\"...\n", color=:white)
        local notebook = IpynbCompile.read_notebook(path)
        local lang = IpynbCompile.identify_lang(notebook)
        local default_out = "$path.$(IpynbCompile.get_extension(lang))"
        # 请求输出路径 | 默认为`输入路径.jl`
        printstyled("            > out_path(default \"$default_out\")="; color=:light_cyan, bold=true)
        out_path = readline()
        isempty(out_path) && (out_path = default_out) # 无⇒自动附加扩展名
        try_compile_notebook(path, out_path)
    end
end

# %% [14] markdown
# ## 主程序

# %% [15] markdown
# 定义

# %% [16] code
"主程序"
function main()
    if isempty(ARGS)
        # 【无】附加参数时，进入交互模式
        interactive_mode()
    else
        # 有附加参数时⇒编译所有文件并自动退出
        compile_with_ARGS(ARGS)
    end
end

# %% [17] markdown
# 执行

# %% [18] code
main()


