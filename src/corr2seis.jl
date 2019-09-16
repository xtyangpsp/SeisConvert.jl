# convert CorrData to SeisData
using SeisIO, SeisNoise, Dates, Logging
""" Example of CorrData

CorrData with 1 Corrs
      NAME: "YW.FACR..BHZ.YW.FACR..BHZ"
        ID: "2010-01-01"
       LOC: 0.0 N, 0.0 E, 0.0 m
      COMP: "ZZ"
   ROTATED: false
 CORR_TYPE: "cross-correlation"
        FS: 5.0
      GAIN: 1.0
   FREQMIN: 0.1
   FREQMAX: 2.4
    CC_LEN: 3600
   CC_STEP: 1800
  WHITENED: false
 TIME_NORM: false
      RESP: c = 0.0, 0 zeros, 0 poles
      MISC: 2 entries
     NOTES: 3 entries
    MAXLAG: 100.0
         T: 2010-01-01T00:00:00.000            …
      CORR: 1001×1 Array{Float32,2}
"""

""" Example of CorrData.misc
Dict{String,Any} with 27 entries:
  "e"        => 86399.8
  "dist"     => 0.0
  "scale"    => 1.0
  "location" => Dict("YW.FACO..BHZ"=>0.0 N, 0.0 E, 0.0 m,"TA.G05D..BHZ"=>0.0 N, 0.0 E, 0.0 m)
  "iztype"   => 9
  "khole"    => "       \xb0"
  "lcalda"   => 0
  "nzhour"   => 0
  "nvhdr"    => 6
  "nzjday"   => 40
  "kcmpnm"   => "BHZ\0\0\0\0\0"
  "depmin"   => -7.54567e-8
  "iftype"   => 1
  "depmax"   => 9.53069e-8
  "nzmin"    => 0
  "b"        => 0.0
  "delta"    => 0.2
  "npts"     => 432000
  "kstnm"    => "G05D\0\0\0\0"
  "nzyear"   => 2010
  "nzmsec"   => 0
  "leven"    => 1
  "lpspol"   => 1
  "depmen"   => -7.11344e-16
  "nzsec"    => 0
  "lovrok"   => 1
  "knetwk"   => "TA\0\0\0\0\0\0"
"""

""" Example of SeisData

SeisChannel with 432000 samples
    ID: YW.FACO..BHZ
  NAME:
   LOC: 0.0 N, 0.0 E, 0.0 m
    FS: 5.0
  GAIN: 1.0
  RESP: c = 0.0, 0 zeros, 0 poles
 UNITS:
   SRC: /Users/xiaotaoyang/Work/Cascadia/Raw/Event_2010_001/YW.FACO.BHZ.sac
  MISC: 0 entries
 NOTES: 1 entries
     T: 2010-01-01T00:00:00.010 (0 gaps)
     X: +1.595e-18
        +1.421e-14
            ...
        +6.933e-11
        (nx = 432000)

"""
# richmisc: true if include location
function corr2seis(C::CorrData)
    #get the size of CorrData, to determine how many channels needed.

    #create an empty SeisData object with the right size.
    S = SeisData(size(C.corr,2))

    #loop through the CorrData (corr) and pass the header values to SeisData object
    # in loop, save customzed headers to misc dictionary.
    # save freqmin and freqmax twice:
    # 1. use real field names. 2. use USER0 and USER1, to be saved to SAC for later use.
    stemp = split(C.name,".")
    evname = join([stemp[1],stemp[2],stemp[3],stemp[4]],".")  #use the first entry in location as the event name
    stname = join([stemp[5],stemp[6],stemp[7],stemp[8]],".")
    evla = 0.0
    evlo = 0.0
    evdp = 0.0
    stla = 0.0
    stlo = 0.0
    stel = 0.0
    if in("location",collect(keys(C.misc)))
        # println(C.name,": ",collect(keys(C.misc["location"])))
        # evname = collect(keys(C.misc["location"]))[1]  #use the first entry in location as the event name
        # stname = collect(keys(C.misc["location"]))[2]
        evla = C.misc["location"][evname].lat
        evlo = C.misc["location"][evname].lon
        evdp = C.misc["location"][evname].el
        stla = C.misc["location"][stname].lat
        stlo = C.misc["location"][stname].lon
        stel = C.misc["location"][stname].el
    else
        @warn "$(C.name) : 'location' field not defined in misc. Use default locations (0.0)."
    end

    for i = 1:size(S)[1]
        SC = SeisChannel();
        # for tv in C.corr[:,i]
        #     push!(SC.x,tv)
        # end
        SC.x = C.corr[:,i]
        SC.id = C.id
        SC.name = C.name
        setfield!(SC.loc,:lat,stla)
        setfield!(SC.loc,:lon,stlo)
        setfield!(SC.loc,:dep,stel)
        # = C.loc
        SC.fs = C.fs
        SC.gain = C.gain
        SC.resp = C.resp
        SC.src = C.name
        SC.t = [1 Int64(C.t[i]*1e6);size(C.corr,1) 0]
        SC.notes = C.notes
        # TO-DO get misc values
        SC.misc = C.misc

        #update some values in misc for SAC headers.
        SC.misc["b"] = -1.0*C.maxlag
        SC.misc["e"] = C.maxlag
        SC.misc["delta"] = 1.0/C.fs
        SC.misc["npts"] = size(C.corr,1)
        SC.misc["depmin"] = minimum(C.corr[:,i])
        SC.misc["depmax"] = maximum(C.corr[:,i])
        SC.misc["depmen"] = sum(C.corr[:,i])/size(C.corr,1)
        SC.misc["kevnm"] = evname
        SC.misc["evla"] = evla
        SC.misc["evlo"] = evlo
        SC.misc["evdp"] = evdp
        SC.misc["stla"] = stla
        SC.misc["stlo"] = stlo
        SC.misc["stel"] = stel
        SC.misc["nzyear"] = Dates.year(u2d(C.t[i]))
        SC.misc["nzjday"] = Dates.date2epochdays(Date(u2d(C.t[i]))) - Dates.date2epochdays(Date(string(Dates.year(u2d(C.t[i])))*"-01-01")) + 1
        SC.misc["nzhour"] = Dates.hour(u2d(C.t[i]))
        SC.misc["nzmin"] = Dates.minute(u2d(C.t[i]))
        SC.misc["nzsec"] = Dates.second(u2d(C.t[i]))
        SC.misc["nzmsec"] = Dates.millisecond(u2d(C.t[i]))
        SC.misc["comp"] = C.comp
        SC.misc["rotated"] = C.rotated
        SC.misc["corr_type"] =  C.corr_type
        # SC.misc["kuser0"] =  C.corr_type
        SC.misc["freqmin"] = C.freqmin
        SC.misc["freqmax"] = C.freqmax
        # SC.misc["user0"] = C.freqmin
        # SC.misc["user1"] = C.freqmax
        SC.misc["cc_len"] = C.cc_len
        SC.misc["cc_step"] = C.cc_step
        # SC.misc["user2"] = C.cc_len
        # SC.misc["user3"] = C.cc_step
        # SC.misc["whitened"] = C.whitened
        # SC.misc["time_norm"] = C.time_norm
        # if C.whitened
        #     SC.misc["kuser1"] =  "NOWHITND"
        # else
        #     SC.misc["kuser1"] =  "WHITENED"
        # end
        # if C.time_norm
        #     SC.misc["kuser2"] =  "TIMENORM"
        # else
        #     SC.misc["kuser2"] =  "NOTIMENM"
        # end
        if C.whitened
            SC.misc["whitened"] =  "NOWHITND"
        else
            SC.misc["whitened"] =  "WHITENED"
        end
        if typeof(C.time_norm) == Bool
            if C.time_norm
                SC.misc["time_norm"] =  "TIMENORM"
            else
                SC.misc["time_norm"] =  "NOTIMENM"
            end
        else
            SC.misc["time_norm"] =  C.time_norm
        end
        S[i] = SC
    end

    return(S)
end
