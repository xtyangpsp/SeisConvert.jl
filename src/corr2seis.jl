# convert CorrData to SeisData
using SeisIO, SeisNoise, Dates
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

function corr2seis(C::CorrData)
    #get the size of CorrData, to determine how many channels needed.

    #create an empty SeisData object with the right size.
    S = SeisData(size(C.corr,2))

    #loop through the CorrData (corr) and pass the header values to SeisData object
    # in loop, save customzed headers to misc dictionary.
    # save freqmin and freqmax twice:
    # 1. use real field names. 2. use USER0 and USER1, to be saved to SAC for later use.
    evname = collect(keys(C.misc["location"]))[1]  #use the first entry in location as the event name
    stname = collect(keys(C.misc["location"]))[2]
    evla = C.misc["location"][evname].lat
    evlo = C.misc["location"][evname].lon
    evdp = C.misc["location"][evname].el
    stla = C.misc["location"][stname].lat
    stlo = C.misc["location"][stname].lon
    stel = C.misc["location"][stname].el

    for i = 1:size(S)[1]
        for tv in C.corr[:,i]
            push!(S[i].x,tv)
        end

        S[i].id = C.id
        S[i].name = C.name
        S[i].loc = C.loc #todo: put source and receiver coordinates in the headers
        S[i].fs = C.fs
        S[i].gain = C.gain
        S[i].resp = C.resp
        S[i].src = C.name
        S[i].t = [1 C.t[i]; size(C.corr,1) 0]
        S[i].notes = C.notes
        # TO-DO get misc values
        S[i].misc = C.misc

        #update some values in misc for SAC headers.
        S[i].misc["b"] = -1.0*C.maxlag
        S[i].misc["e"] = C.maxlag
        S[i].misc["delta"] = 1.0/C.fs
        S[i].misc["npts"] = size(C.corr,1)
        S[i].misc["depmin"] = minimum(C.corr[:,i])
        S[i].misc["depmax"] = maximum(C.corr[:,i])
        S[i].misc["depmen"] = sum(C.corr[:,i])/size(C.corr,1)
        S[i].misc["kevnm"] = evname
        S[i].misc["evla"] = evla
        S[i].misc["evlo"] = evlo
        S[i].misc["evdp"] = evdp
        S[i].misc["stla"] = stla
        S[i].misc["stlo"] = stlo
        S[i].misc["stel"] = stel
        S[i].misc["nzyear"] = Dates.year(u2d(C.t[i]))
        S[i].misc["nzjday"] = Dates.date2epochdays(Date(u2d(C.t[i]))) - Dates.date2epochdays(Date(string(Dates.year(u2d(C.t[i])))*"-01-01")) + 1
        S[i].misc["nzhour"] = Dates.hour(u2d(C.t[i]))
        S[i].misc["nzmin"] = Dates.minute(u2d(C.t[i]))
        S[i].misc["nzsec"] = Dates.second(u2d(C.t[i]))
        S[i].misc["nzmsec"] = Dates.millisecond(u2d(C.t[i]))

        S[i].misc["rotated"] = C.rotated
        S[i].misc["corr_type"] =  C.corr_type
        S[i].misc["kuser0"] =  C.corr_type
        S[i].misc["freqmin"] = C.freqmin
        S[i].misc["freqmax"] = C.freqmax
        S[i].misc["user0"] = C.freqmin
        S[i].misc["user1"] = C.freqmax
        S[i].misc["cc_len"] = C.cc_len
        S[i].misc["cc_step"] = C.cc_step
        S[i].misc["user2"] = C.cc_len
        S[i].misc["user3"] = C.cc_step
        S[i].misc["whitened"] = C.whitened
        S[i].misc["time_norm"] = C.time_norm
        if C.whitened
            S[i].misc["kuser1"] =  "NOWHITND"
        else
            S[i].misc["kuser1"] =  "WHITENED"
        end
        if C.time_norm
            S[i].misc["kuser2"] =  "TIMENORM"
        else
            S[i].misc["kuser2"] =  "NOTIMENM"
        end

    end

    return(S)
end
