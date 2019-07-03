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
        Converting JLD2 format to SAC files.

        INFILE ORGANIZATION CODE (string)
        TSD: JLD2 FILE -> Timestamp group -> SeisData;
        TCD: JLD2 FILE -> Timestamp group -> CorrData;
        CTSD: JLD2 FILE -> Component -> Timestamp group -> SeisData;
        CTCD: JLD2 FILE -> Component -> Timestamp group -> CorrData;

        OUTFILE SAC ORGANIZATION CODE (string)
        SR: Source -> Receiver -> SAC (timestamps and component information are
            embeded in file names) #this is for CorrData only.
            Specifically, this is good/designed for poststack CorrData, e.g.,
            1 stack per day.
        TG: Timestamp group -> SAC   #good for SeisData. if for CorrData, the
            station pair and component will be embeded in file names.

        NOTES:
        1. For CorrData, the freqmin, freqmax, cc_len, cc_step are stored in SAC headers
            USER0, USER1, USER2, USER3, respectively
        2. For CorrData, the maxlag is used to determine the start (B) and end (E) times

        \n")

    return
end

#
function jld22sac(jldfile::String,sacdatadir::String,jldformatcode::String="TCD",sacformatcode::String="SR")

    #first check JLD formatcode and sac output format/structrue code
    if jldformatcode != "TSD" && jldformatcode != "TCD" && jldformatcode != "CTSD" && jldformatcode != "CTCD"
        error("The input JLDFORMATCODE must be one of: TSD, TCD (default), CTSD, or CTCD. Run jld22sac() for detailed explanations.\n")
    end
    if sacformatcode != "SR" && sacformatcode != "TG"
        error("The input JLDFORMATCODE must be one of: SR (default), or TG. Run jld22sac() for detailed explanations.\n")
    end

    #create SAC data directory
    mkpath(sacdatadir)

    jfile = jldopen(jldfile,"r")

    #get first level group tags
    group1 = keys(jfile)

    for g1 = group1
        print("Working on 1st level group: ",g1,"\n")
        if jldformatcode == "TSD" || jldformatcode == "TCD" #only one level group
            dlist = keys(jfile[g1]) #data list
            for dfile = dlist
                d = jfile[joinpath(g1,dfile)]
                if jldformatcode == "TCD" # data file has CorrData type
                    print("CorrData to SAC")
                else # data file has SeisData type
                    error("TSD is not ready yet. Coming soon.")
                end
            end
        else #need to do anotehr level loop for format CTSD or CTCD
            error("CTSD and CTCD are not ready yet. Coming soon.")

        end


    end #end of loop for the first level group tags

    JLD2.close(jfile)
end
