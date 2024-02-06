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
    :markdown             => "md" # ! 近似为编程语言（用于Markdown单元格）
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
    :rust               => "rs"
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
