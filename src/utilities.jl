# some utility functions.
using SeisIO

export readfilelist

function readfilelist(infilelist::String)
    outlist = String[];
    open(infilelist) do f
        for ln in eachline(f)
          push!(outlist,ln)
        end
    end
    return(outlist)
end
