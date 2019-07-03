# convert CorrData to SeisData
using SeisIO, SeisNoise

function corr2seis(C::CorrData)

    #get the size of CorrData, to determine how many channels needed.

    #create an empty SeisData object with the right size.
    S = SeisData()

    #loop through the CorrData (corr) and pass the header values to SeisData object


    # in loop, save customzed headers to misc dictionary.
    # save freqmin and freqmax twice:
    # 1. use real field name. 2. use USER0 and USER1, to be saved to SAC for later use.

    return(S)
end
