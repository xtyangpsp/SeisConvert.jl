#examples of using segy2jld2 functions to convert PASSCAL segy files to jld2 format.
using SeisIO, SeisConvert
# Saves individual segy file (in) to JLD2 file.
# The output file name will be the same as the input, with new extension *.jld2.

infile = "02.089.00.01.50.7460.1"
segy2jld2(infile)
#

# """
# Saves individual segy file (in) to JLD2 file (out), which is explicitly specified.
# """

segy2jld2(infile,"02.089.00.01.50.7460.1_younameit.jld2")

# """
# Saves segy files based on a filelist generated using ls() in Julia to
# JLD2 file (out), which is explicitly specified.
# """

filelist = ls("segy/02.089.00.01.50/02*")

segy2jld2(filelist,"2002.089T00.01.50","2002.089T00.01.50.jld2")


# """
# Searches for all segy files scanning throgh the segydirlist (Array{String,1}). The segy files
#     in each segy directory are assigned to one time stamp based on timestamplist (Array{String,1}).
#     The two Arrays must be equal in size. The list can be generated from a file list (using ls in shell),
#     using a utility function in this package: readfilelist(infilelist::String).
#
# All segy files will be saved into one single JLD2 file (out), which is explicitly specified as outfile.
# """
segydirlist = ls("segy/02.089*")
timestamplist=["2002.089T00.01.50","2002.089T00.02.10"]
segy2jld2(segydirlist,timestamplist,"testoutput_2groups.jld2")
