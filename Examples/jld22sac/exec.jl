#examples of using jld22sac functions to convert JLD2 files to sac format.
using SeisIO, SeisConvert, Sockets, JLD2
# using SeisIO, Sockets, JLD2
# include("/Users/xiaotaoyang/SOFT/mySeisJL/code/SeisConvert.jl/src/jld22sac.jl")
# include("/Users/xiaotaoyang/SOFT/mySeisJL/code/SeisConvert.jl/src/sac2jld2.jl")
# include("/Users/xiaotaoyang/SOFT/mySeisJL/code/SeisConvert.jl/src/corr2seis.jl")
# include("/Users/xiaotaoyang/SOFT/mySeisJL/code/SeisConvert.jl/src/utilities.jl")
# Saves individual sac file (in) to JLD2 file.
# The output file name will be the same as the input, with new extension *.jld2.

# 1. prepare a SeisData jld2 file first.
println("preparing JLD2 file using test dataset")
sacdirlist = ls("sac/Raw")
timestamplist=["2010.001T00.00.00","2010.002T00.00.00"]
sac2jld2(sacdirlist,timestamplist,"testSeisData.jld2")

# 2. Conver it back to SAC using jld22sac
println(" Conver it back to SAC using jld22sac")
jld22sac("testSeisData.jld2","SeisData_SAC_all_TG",informat="TD",outformat="TG",verbose=true)

# 3. Conver it back to SAC using jld22sac, output as SRC format/structure
println(" Conver it back to SAC using jld22sac, output as SRC format/structure")
jld22sac("testSeisData.jld2","SeisData_SAC_all_SRC",informat="TD",outformat="SRC",verbose=true)

# 4. Conver it back to SAC using jld22sac, subset timestamplist
println(" Conver it back to SAC using jld22sac, subset timestamplist")
subsetcondition = Dict("timestamplist" => ["2010.001T00.00.00"])
jld22sac("testSeisData.jld2","SeisData_SAC_subset_TG",subset=subsetcondition,informat="TD",outformat="TG",verbose=true)
