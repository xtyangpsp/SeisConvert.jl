#examples of using sac2jld2 functions to convert sac files to jld2 format.
using SeisIO, SeisConvert
# Saves individual sac file (in) to JLD2 file.
# The output file name will be the same as the input, with new extension *.jld2.

infile = "BK.HUMO.BHZ.sac"
sac2jld2(infile)
#

# """
# Saves individual sac file (in) to JLD2 file (out), which is explicitly specified.
# """

sac2jld2(infile,"BK.HUMO.BHZ_younameit.jld2")

# """
# Saves sac files based on a filelist generated using ls() in Julia to
# JLD2 file (out), which is explicitly specified.
# """

filelist = ls("sac/Raw/Event_2010_001/*.sac")

sac2jld2(filelist,"2010.001T00.00.00","Event_2010_001.jld2")


# """
# Searches for all sac files scanning throgh the sacdirlist (Array{String,1}). The sac files
#     in each sac directory are assigned to one time stamp based on timestamplist (Array{String,1}).
#     The two Arrays must be equal in size. The list can be generated from a file list (using ls in shell),
#     using a utility function in this package: readfilelist(infilelist::String).
#
# All sac files will be saved into one single JLD2 file (out), which is explicitly specified as outfile.
# """
sacdirlist = ls("sac/Raw")
timestamplist=["2010.001T00.00.00","2010.002T00.00.00"]
sac2jld2(sacdirlist,timestamplist,"testoutput_2groups.jld2")
