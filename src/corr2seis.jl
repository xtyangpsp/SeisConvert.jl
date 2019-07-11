# convert CorrData to SeisData
using SeisIO, SeisNoise
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
    for i = 1:size(S)[1]
        S[i].x = C.corr[:,i] #waveform data

        S[i].id = C.id
        S[i].name = C.name
        S[i].loc = C.loc #todo: put source and receiver coordinates in the headers
        S[i].fs = C.fs
        S[i].gain = C.gain
        S[i].resp = C.resp
        S[i].src = C.name
        S[i].t = [1 C.t[i]; size(C.corr,1) 0]

        # TO-DO get misc values


    end

    return(S)
end
