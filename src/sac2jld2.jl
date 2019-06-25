export sac2jld2

using Dates, SeisIO, JLD2

# Converting sac data to JLD2 format. There are options to save to JLD2 format
# as single file or separate files for each sac file.

"""

    sac2jld2(infile,outfile)

Saves individual sac file (in) to JLD2 file (out).

"""

function sac2jld2(infile::String,outfile::String)
    print("I convert SAC file to JLD2 file.\n")
    sacin = SeisIO.read_data("sac",infile);
    stationlist = String[];
    push!(stationlist,sacin.id[1])  #pass the 1st element of sacin.id[] to the station list
    stationinfo = Dict(["stationlist" => stationlist,"stationmethod" => "sac2jld2","stationsrc" => "converted"])
    stimetemp = sacin.t[1][3]*1e-6; #convert union time to calendar time;
    saclength = sacin.t[1][2]/sacin.fs; #convert from number of samples to time duration.
    starttime = u2d(stimetemp);
    endtime = u2d(stimetemp);
    #save to jld2
    jldopen(outfile, "w") do file
        file["info/DLtimestamplist"] = "placeholder";
        file["info/stationlist"] = stationlist;
        file["info/starttime"]   = string(starttime)
        file["info/endtime"]     = string(endtime)
        file["info/DL_time_unit"]= "placeholder";

    end


end
