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
    :markdown           => ["<!--", ("<!--", "-->")] # ! 近似有单行注释（后续的末尾一般会被忽略）
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
    :rust               => ["//", ("/*", "*/")]
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
