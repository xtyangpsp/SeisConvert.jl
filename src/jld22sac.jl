export jld22sac
#
using Dates, SeisIO, JLD2, SeisNoise
"""
    Converting JLD2 format to sac files. There are options to read in JLD2 data
    in different types: SeisData (defined in SeisIO) and CorrData (defined in SeisNoise).
"""

#base function to output usage information and format descriptions.
function jld22sac()
    print("
        Converting JLD2 format to sac files.
        INFILE ORGANIZATION CODE (string)
        TSD: JLD2 FILE -> Timestamp group -> SeisData;
        TCD: JLD2 FILE -> Timestamp group -> CorrData;
        CTSD: JLD2 FILE -> Component -> Timestamp group -> SeisData;
        CTCD: JLD2 FILE -> Component -> Timestamp group -> CorrData;

        OUTFILE SAC ORGANIZATION CODE (string)
        SRC: Source -> Receiver -> Component -> SAC (timestamps are embeded in file names) #this is for CorrData only.
        PC: Pair -> Component -> SAC  #this is for CorrData only.
        TG: Timestamp group -> SAC   #good for SeisData. if for CorrData, the station pair and component will be embeded in file names.
        \n")

    return
end
