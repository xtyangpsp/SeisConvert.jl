using Documenter, SeisConvert

makedocs(;
    modules=[SeisConvert],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/xtyangpsp/SeisConvert.jl/blob/{commit}{path}#L{line}",
    sitename="SeisConvert.jl",
    authors="Xiaotao_Yang",
    assets=String[],
)

deploydocs(;
    repo="github.com/xtyangpsp/SeisConvert.jl",
)
