export sac2jld2
#
# using Dates, SeisIO, JLD2

# Converting sac data to JLD2 format. There are options to save to JLD2 format
# as single file or separate files for each sac file.

"""

    sac2jld2(infile)

Saves individual sac file (in) to JLD2 file.
The output file name will be the same as the input, with new extension *.jld2.

"""

function sac2jld2(infile::String)
    print("I convert SAC file to JLD2 file, same file, new extension of jld2.\n")
    outfile = join([infile[1:end-3],"jld2"]); #trim the file name to remove .sac
    sacin = SeisIO.read_data("sac",infile);

    stationlist = String[];
    push!(stationlist,sacin.id[1])  #pass the 1st element of sacin.id[] to the station list
    stationinfo = Dict(["stationlist" => stationlist,"stationmethod" => "sac2jld2","stationsrc" => "converted"])
    stimetemp = sacin.t[1][3]*1e-6; #convert mseconds to seconds;
    saclength = sacin.t[1][2]/sacin.fs; #convert from number of samples to time duration.
    starttime = u2d(stimetemp); #convert union time to calendar time;
    endtime = u2d(stimetemp);
    DLtimestamplist = String[];
    push!(DLtimestamplist,replace(string(starttime),"-" => "."));

    #save to jld2
    stemp = joinpath(DLtimestamplist[1],stationlist[1]);
    file = jldopen(outfile, "w");
    file["info/DLtimestamplist"] = DLtimestamplist;
    file["info/stationlist"] = stationlist;
    file["info/starttime"]   = string(starttime)
    file["info/endtime"]     = string(endtime)
    file["info/DL_time_unit"]= saclength; #length of the data in time (duration), not number of samples

    #save the waveform data as SeisData format.
    file[stemp] = SeisData(sacin[1])[1];

    JLD2.close(file);

    print("Saved JLD2 file to: ", outfile, "\n");
end

"""

    sac2jld2(infile,outfile)

Saves individual sac file (in) to JLD2 file (out), which is explicitly specified.

"""

function sac2jld2(infile::String,outfile::String)
    print("I convert SAC file to JLD2 file.\n")
    sacin = SeisIO.read_data("sac",infile);

    stationlist = String[];
    push!(stationlist,sacin.id[1])  #pass the 1st element of sacin.id[] to the station list
    stationinfo = Dict(["stationlist" => stationlist,"stationmethod" => "sac2jld2","stationsrc" => "converted"])
    stimetemp = sacin.t[1][3]*1e-6; #convert mseconds to seconds;
    saclength = sacin.t[1][2]/sacin.fs; #convert from number of samples to time duration.
    starttime = u2d(stimetemp); #convert union time to calendar time;
    endtime = u2d(stimetemp);
    DLtimestamplist = String[];
    push!(DLtimestamplist,replace(string(starttime),"-" => "."));

    #save to jld2
    stemp = joinpath(DLtimestamplist[1],stationlist[1]);
    file = jldopen(outfile, "w");
    file["info/DLtimestamplist"] = DLtimestamplist;
    file["info/stationlist"] = stationlist;
    file["info/starttime"]   = string(starttime)
    file["info/endtime"]     = string(endtime)
    file["info/DL_time_unit"]= saclength; #length of the data in time (duration), not number of samples

    #save the waveform data as SeisData format.
    file[stemp] = SeisData(sacin[1])[1];

    JLD2.close(file);

    print("Saved JLD2 file to: ", outfile, "\n");
end

"""

    sac2jld2(infilelist,timestamp,outfile)

Saves sac files based on a filelist generated using ls or other methods (in) to
JLD2 file (out), which is explicitly specified.
    infilelist: filelist including all sacfiles with the same tiemstamp, e.g., same day
    tiemstamp: this must be specified for the sac fiels, assuming they all share
                the same time stamp.
    outfile: output file name for the JLD2 file. All data fiels will be readin and
                saved to a single JLD2 file.
"""

function sac2jld2(infilelist::String,timestamp::String,outfile::String)
    print("I convert and pack all SAC files to a JLD2 file.\n")

    #read the filenames from the infilelist into a strinng array
    filelist=***** #to be worked on
    stationlist=****
    file = jldopen(outfile, "w");
    file["info/DLtimestamplist"] = DLtimestamplist;
    file["info/stationlist"] = stationlist;
    file["info/starttime"]   = string(starttime)
    file["info/endtime"]     = string(endtime)
    file["info/DL_time_unit"]= saclength; #length of the data in time (duration), not number of samples
    count=1;
    for infile = filelist
        sacin = SeisIO.read_data("sac",infile);

        stationlist = String[];
        push!(stationlist,sacin.id[1])  #pass the 1st element of sacin.id[] to the station list
        stationinfo = Dict(["stationlist" => stationlist,"stationmethod" => "sac2jld2","stationsrc" => "converted"])
        stimetemp = sacin.t[1][3]*1e-6; #convert mseconds to seconds;
        saclength = sacin.t[1][2]/sacin.fs; #convert from number of samples to time duration.
        starttime = u2d(stimetemp); #convert union time to calendar time;
        endtime = u2d(stimetemp);
        DLtimestamplist = String[];
        push!(DLtimestamplist,replace(string(starttime),"-" => "."));

        #save to jld2
        stemp = joinpath(DLtimestamplist[1],stationlist[1]);



        #save the waveform data as SeisData format.
        file[stemp] = SeisData(sacin[1])[1];
        count=count+1;
    end
    JLD2.close(file);


    print("Saved JLD2 file to: ", outfile, "\n");
end
