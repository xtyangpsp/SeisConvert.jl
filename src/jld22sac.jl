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
        jld22sac(jldfile,sacrootdir; informat, outformat,subset, verbose)
        Requred  arguments:
            jldfile
            sacrootdir
        Optional:
            informat = infile (jld file) structure code (string).
                TD: JLD2 FILE -> Timestamp group -> SeisData/CorrData; Type of data is detected automatically.
                CTD: JLD2 FILE -> Component -> Timestamp group -> SeisData/CorrData;
            outformat = outfile (sac file) structre code (string)
                SRC: Source -> Receiver -> Component -> SAC (timestamps and component information are
                    embeded in file names) #this is for CorrData only. [DEFAULT]
                    Specifically, this is good/designed for poststack CorrData, e.g.,
                    1 stack per day.
                TG: Timestamp group -> SAC   #good for SeisData. if for CorrData, the
                    station pair and component will be embeded in file names.
            subset = a Dictionary containing subset condtions (lists). DEFAULT is empty
                Current support subset keys: timestamplist, stationlist (in net.sta format), componentlist.
            verbose = true/false. [DEFAULT] is false.

        NOTES:
        1. For CorrData, the freqmin, freqmax, cc_len, cc_step are stored in SAC headers
            USER0, USER1, USER2, USER3, respectively
        2. For CorrData, the maxlag is used to determine the start (B) and end (E) times

        \n")

    return
end

#
function jld22sac(jldfile::String,sacrootdir::String; informat::String="TD", outformat::String="SRC",
    subset::Dict=Dict(), verbose::Bool=false)

    #first check JLD formatcode and sac output format/structrue code
    if informat != "TD" && informat != "CTD"
        error("The input JLDFORMATCODE must be one of: TD (default) or CTD. Run jld22sac() for detailed explanations.\n")
    end
    if outformat != "SRC" && outformat != "TG"
        error("The input JLDFORMATCODE must be one of: SRC (default), or TG. Run jld22sac() for detailed explanations.\n")
    end

    #checking subset options
    subsetflag_ts = false
    subsetflag_sta = false
    subsetflag_comp = false
    subsetkey_ts = "timestamplist"
    subsetkey_sta = "stationlist" #consider both source and receiver in CorrData situation.
    subsetkey_comp = "componentlist" #component list
    if !isempty(subset)
        subsetkeys = collect(keys(subset))
        if verbose
            println("Applying subset. Will only save subset data for: ")
            println(subsetkeys)
        end

        if in(subsetkey_ts,subsetkeys)
            subsetflag_ts = true
        end
        if in(subsetkey_sta,subsetkeys)
            subsetflag_sta = true
        end
        if in(subsetkey_comp,subsetkeys)
            subsetflag_comp = true
        end
    end

    #create SAC data directory
    mkpath(sacrootdir)

    jfile = jldopen(jldfile,"r")

    #get first level group tags
    group1 = keys(jfile)
    if subsetflag_ts
        group1 = subset[subsetkey_ts] #use subset timestamplist
    end

    for g1 = group1
        if g1 != "info"
            if informat == "TD" #only one level group
                println("Working on group: ",g1)
                dlist = keys(jfile[g1]) #data list
                for dfile = dlist
                    d = jfile[joinpath(g1,dfile)]
                    # println("CorrData to SAC")

                    if typeof(d) == CorrData # data file has CorrData type
                        stemp = split(d.name,".")
                        srname = join([stemp[1],stemp[2]],".")  #use the first entry in location as the source name
                        rcname = join([stemp[5],stemp[6]],".")
                        comp = d.comp
                        S = corr2seis(d)
                    elseif typeof(d) == SeisData || typeof(d) == SeisChannel # data file has SeisData type
                        stemp = split(d.id,".")
                        rcname = join([stemp[1],stemp[2]],".")
                        comp = stemp[4]
                        S = SeisData(d)
                    else
                        error(typeof(d), " datatype not supported.")
                    end
                    if outformat == "SRC" #Source -> Receiver -> SAC
                        if subsetflag_sta
                            if in(srname,subset[subsetkey_sta]) || in(rcname,subset[subsetkey_sta])
                                if subsetflag_comp
                                    if in(comp,subset[subsetkey_comp])
                                        if verbose
                                            println("  --> converting: ",dfile)
                                        end
                                        writesac_rich(S,datatype=typeof(d),outdir=string(joinpath(sacrootdir,srname,rcname,comp)))
                                    end
                                else
                                    if verbose
                                        println("  --> converting: ",dfile)
                                    end
                                    writesac_rich(S,datatype=typeof(d),outdir=string(joinpath(sacrootdir,srname,rcname,comp)))
                                end
                            end
                        else
                            if subsetflag_comp
                                if in(comp,subset[subsetkey_comp])
                                    if verbose
                                        println("  --> converting: ",dfile)
                                    end
                                    writesac_rich(S,datatype=typeof(d),outdir=string(joinpath(sacrootdir,srname,rcname,comp)))
                                end
                            else
                                if verbose
                                    println("  --> converting: ",dfile)
                                end
                                writesac_rich(S,datatype=typeof(d),outdir=string(joinpath(sacrootdir,srname,rcname,comp)))
                            end
                        end
                    elseif outformat == "TG" #Timestamp -> SAC
                        if subsetflag_sta
                            if in(srname,subset[subsetkey_sta]) || in(rcname,subset[subsetkey_sta])
                                if subsetflag_comp
                                    if in(comp,subset[subsetkey_comp])
                                        if verbose
                                            println("  --> converting: ",dfile)
                                        end
                                        writesac_rich(S,datatype=typeof(d),outdir=string(joinpath(sacrootdir,g1)))
                                    end
                                else
                                    if verbose
                                        println("  --> converting: ",dfile)
                                    end
                                    writesac_rich(S,datatype=typeof(d),outdir=string(joinpath(sacrootdir,g1)))
                                end
                            end
                        else
                            if subsetflag_comp
                                if in(comp,subset[subsetkey_comp])
                                    if verbose
                                        println("  --> converting: ",dfile)
                                    end
                                    writesac_rich(S,datatype=typeof(d),outdir=string(joinpath(sacrootdir,g1)))
                                end
                            else
                                if verbose
                                    println("  --> converting: ",dfile)
                                end
                                writesac_rich(S,datatype=typeof(d),outdir=string(joinpath(sacrootdir,g1)))
                            end
                        end
                    end
                end
            else #need to do anotehr level loop for format CTSD or CTCD
                error("CTSD and CTCD are not ready yet. Coming soon.")
            end
        end
    end #end of loop for the first level group tags

    JLD2.close(jfile)
end
