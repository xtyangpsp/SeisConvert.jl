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
                TSD: JLD2 FILE -> Timestamp group -> SeisData;
                TCD: JLD2 FILE -> Timestamp group -> CorrData; [DEFAULT]
                CTSD: JLD2 FILE -> Component -> Timestamp group -> SeisData;
                CTCD: JLD2 FILE -> Component -> Timestamp group -> CorrData;
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
function jld22sac(jldfile::String,sacrootdir::String; informat::String="TCD", outformat::String="SRC",
    subset::Dict=Dict(), verbose::Bool=false)

    #first check JLD formatcode and sac output format/structrue code
    if informat != "TSD" && informat != "TCD" && informat != "CTSD" && informat != "CTCD"
        error("The input JLDFORMATCODE must be one of: TSD, TCD (default), CTSD, or CTCD. Run jld22sac() for detailed explanations.\n")
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
            println("-- will only save subset data for: ")
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
            if informat == "TSD" || informat == "TCD" #only one level group
                println("Working on group: ",g1)
                dlist = keys(jfile[g1]) #data list
                for dfile = dlist
                    d = jfile[joinpath(g1,dfile)]
                    if informat == "TCD" # data file has CorrData type
                        # println("CorrData to SAC")
                        stemp = split(d.name,".")
                        srname = join([stemp[1],stemp[2]],".")  #use the first entry in location as the source name
                        rcname = join([stemp[5],stemp[6]],".")
                        comp = d.comp
                        if outformat == "SRC" #Source -> Receiver -> SAC
                            if subsetflag_sta
                                if in(srname,subset[subsetkey_sta]) || in(rcname,subset[subsetkey_sta])
                                    if subsetflag_comp
                                        if in(comp,subset[subsetkey_comp])
                                            if verbose
                                                println("  --> converting: ",dfile)
                                            end
                                            S=corr2seis(d)
                                            writesac_corr(S,outdir=string(joinpath(sacrootdir,srname,rcname,comp)))
                                        end
                                    else
                                        if verbose
                                            println("  --> converting: ",dfile)
                                        end
                                        S=corr2seis(d)
                                        writesac_corr(S,outdir=string(joinpath(sacrootdir,srname,rcname,comp)))
                                    end
                                end
                            else
                                if subsetflag_comp
                                    if in(comp,subset[subsetkey_comp])
                                        if verbose
                                            println("  --> converting: ",dfile)
                                        end
                                        S=corr2seis(d)
                                        writesac_corr(S,outdir=string(joinpath(sacrootdir,srname,rcname,comp)))
                                    end
                                else
                                    if verbose
                                        println("  --> converting: ",dfile)
                                    end
                                    S=corr2seis(d)
                                    writesac_corr(S,outdir=string(joinpath(sacrootdir,srname,rcname,comp)))
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
                                            S=corr2seis(d)
                                            writesac_corr(S,outdir=string(joinpath(sacrootdir,g1)))
                                        end
                                    else
                                        if verbose
                                            println("  --> converting: ",dfile)
                                        end
                                        S=corr2seis(d)
                                        writesac_corr(S,outdir=string(joinpath(sacrootdir,g1)))
                                    end
                                end
                            else
                                if subsetflag_comp
                                    if in(comp,subset[subsetkey_comp])
                                        if verbose
                                            println("  --> converting: ",dfile)
                                        end
                                        S=corr2seis(d)
                                        writesac_corr(S,outdir=string(joinpath(sacrootdir,g1)))
                                    end
                                else
                                    if verbose
                                        println("  --> converting: ",dfile)
                                    end
                                    S=corr2seis(d)
                                    writesac_corr(S,outdir=string(joinpath(sacrootdir,g1)))
                                end
                            end
                        end
                    else # data file has SeisData type
                        # println("CorrData to SAC")
                        stemp = split(d.id,".")
                        rcname = join([stemp[1],stemp[2]],".")
                        comp = stemp[4]
                        if outformat == "SRC" #Source -> Receiver -> SAC
                            if subsetflag_sta
                                if in(rcname,subset[subsetkey_sta])
                                    if subsetflag_comp
                                        if in(comp,subset[subsetkey_comp])
                                            if verbose
                                                println("  --> converting: ",dfile)
                                            end
                                            writesac_seis(d,outdir=string(joinpath(sacrootdir,rcname,comp)))
                                        end
                                    else
                                        if verbose
                                            println("  --> converting: ",dfile)
                                        end
                                        writesac_seis(d,outdir=string(joinpath(sacrootdir,rcname,comp)))
                                    end
                                end
                            else
                                if subsetflag_comp
                                    if in(comp,subset[subsetkey_comp])
                                        if verbose
                                            println("  --> converting: ",dfile)
                                        end
                                        writesac_seis(d,outdir=string(joinpath(sacrootdir,rcname,comp)))
                                    end
                                else
                                    if verbose
                                        println("  --> converting: ",dfile)
                                    end
                                    writesac_seis(d,outdir=string(joinpath(sacrootdir,rcname,comp)))
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
                                            writesac_seis(d,outdir=string(joinpath(sacrootdir,g1)))
                                        end
                                    else
                                        if verbose
                                            println("  --> converting: ",dfile)
                                        end
                                        writesac_seis(d,outdir=string(joinpath(sacrootdir,g1)))
                                    end
                                end
                            else
                                if subsetflag_comp
                                    if in(comp,subset[subsetkey_comp])
                                        if verbose
                                            println("  --> converting: ",dfile)
                                        end
                                        writesac_seis(d,outdir=string(joinpath(sacrootdir,g1)))
                                    end
                                else
                                    if verbose
                                        println("  --> converting: ",dfile)
                                    end
                                    writesac_seis(d,outdir=string(joinpath(sacrootdir,g1)))
                                end
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
