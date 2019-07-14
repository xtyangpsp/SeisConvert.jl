export jld22sac
#
using Dates, SeisIO, JLD2, SeisNoise, Sockets
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
function jld22sac(jldfile::String,sacrootdir::String; informat::String="TCD", outformat::String="SR", verbose::Bool=false)

    #first check JLD formatcode and sac output format/structrue code
    if informat != "TSD" && informat != "TCD" && informat != "CTSD" && informat != "CTCD"
        error("The input JLDFORMATCODE must be one of: TSD, TCD (default), CTSD, or CTCD. Run jld22sac() for detailed explanations.\n")
    end
    if outformat != "SR" && outformat != "TG"
        error("The input JLDFORMATCODE must be one of: SR (default), or TG. Run jld22sac() for detailed explanations.\n")
    end

    #create SAC data directory
    mkpath(sacrootdir)

    jfile = jldopen(jldfile,"r")

    #get first level group tags
    group1 = keys(jfile)

    for g1 = group1
        if g1 != "info"
            if informat == "TSD" || informat == "TCD" #only one level group
                println("Working on group: ",g1)
                dlist = keys(jfile[g1]) #data list
                for dfile = dlist
                    if verbose
                        println("  --> converting: ",dfile)
                    end
                    d = jfile[joinpath(g1,dfile)]
                    if informat == "TCD" # data file has CorrData type
                        # println("CorrData to SAC")
                        if outformat == "SR" #Source -> Receiver -> SAC
                            stemp = split(d.name,".")
                            evname = join([stemp[1],stemp[2]],".")  #use the first entry in location as the event name
                            stname = join([stemp[5],stemp[6]],".")
                            # println(typeof(d))
                            S=corr2seis(d)
                            writesac_corr(S,outdir=string(joinpath(sacrootdir,evname,stname)))
                        elseif outformat == "TG" #Timestamp -> SAC
                            writesac_corr(corr2seis(d),outdir=string(joinpath(sacrootdir,g1)))
                        end
                    else # data file has SeisData type
                        error("TSD is not ready yet. Coming soon.")
                    end
                end
            else #need to do anotehr level loop for format CTSD or CTCD
                error("CTSD and CTCD are not ready yet. Coming soon.")
            end
        end
    end #end of loop for the first level group tags

    JLD2.close(jfile)
end
