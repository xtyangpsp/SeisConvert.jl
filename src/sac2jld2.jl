export sac2jld2
#
using Dates, SeisIO, JLD2

# Converting sac data to JLD2 format. There are options to save to JLD2 format
# as single file or separate files for each sac file.

"""

    sac2jld2(infile)

Saves individual sac file (in) to JLD2 file.
The output file name will be the same as the input, with new extension *.jld2.

"""

function sac2jld2(infile::String)
    print("Same file, new extension of jld2.\n")
    print("Converting SAC file: [ ",infile," ] ... \n")
    outfile = join([infile[1:end-3],"jld2"]); #trim the file name to remove .sac
    sacin = SeisIO.read_data("sac",infile);

    stationlist = String[];
    push!(stationlist,sacin.id[1])  #pass the 1st element of sacin.id[] to the station list
    # stationinfo = Dict(["stationlist" => stationlist,"stationmethod" => "sac2jld2","stationsrc" => "converted"])
    stimetemp = sacin.t[1][3]*1e-6; #convert mseconds to seconds;
    saclength = sacin.t[1][2]/sacin.fs; #convert from number of samples to time duration.
    starttime = u2d(stimetemp); #convert union time to calendar time;
    endtime = u2d(stimetemp + saclength);
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
    # print("I convert SAC file to JLD2 file.\n")
    print("Converting SAC file: [ ",infile," ] ... \n")
    sacin = SeisIO.read_data("sac",infile);

    stationlist = String[];
    push!(stationlist,sacin.id[1])  #pass the 1st element of sacin.id[] to the station list
    # stationinfo = Dict(["stationlist" => stationlist,"stationmethod" => "sac2jld2","stationsrc" => "converted"])
    stimetemp = sacin.t[1][3]*1e-6; #convert mseconds to seconds;
    saclength = sacin.t[1][2]/sacin.fs; #convert from number of samples to time duration.
    starttime = u2d(stimetemp); #convert union time to calendar time;
    endtime = u2d(stimetemp + saclength);
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
                the same time stamp. Suggested format: 2019.06.27T00.00.00
    outfile: output file name for the JLD2 file. All data fiels will be readin and
                saved to a single JLD2 file.
"""

function sac2jld2(infilelist::String,timestamp::String,outfile::String)
    # print("I convert and pack all SAC files to a JLD2 file.\n")

    #read the filenames from the infilelist into a strinng array
    filelist = readfilelist(infilelist)

    stationlist = String[];
    DLtimestamplist = String[];
    push!(DLtimestamplist,timestamp); #use the specified timestamp for the group.

    count=1;

    #get some intial information from the first sac file.
    sacin0 = SeisIO.read_data("sac",filelist[1]);
    stimemin = sacin0.t[1][3]*1e-6; #initial starttime in seconds;
    ftemp = sacin0.t[1][2]/sacin0.fs; #convert from number of samples to time duration.
    saclengthmax = ftemp[1]
    etimemax = stimemin + saclengthmax;

    file = jldopen(outfile, "w");
    file["info/DLtimestamplist"] = DLtimestamplist;

    #in the loop for each sac file. we will find the minimum starttime, maximum endtime, and maximum saclength.
    for infile = filelist
        print("Converting SAC file: [ ",infile," ] ... ",count,"\n")

        sacin = SeisIO.read_data("sac",infile);
        push!(stationlist,sacin.id[1])  #pass the 1st element of sacin.id[] to the station list
        # stationinfo = Dict(["stationlist" => stationlist,"stationmethod" => "sac2jld2","stationsrc" => "converted"])
        stimetemp = sacin.t[1][3]*1e-6; #convert mseconds to seconds;
        if stimetemp < stimemin
            stimemin = stimetemp
        end
        saclength = sacin.t[1][2]/sacin.fs; #convert from number of samples to time duration.
        if saclength[1] > saclengthmax
            saclengthmax = saclength[1]
        end
        etimetemp = stimetemp + saclength[1]
        if etimetemp > etimemax
            etimemax = etimetemp
        end

        #save to jld2
        stemp = joinpath(timestamp,sacin.id[1]);

        #save the waveform data as SeisData format.
        file[stemp] = SeisData(sacin[1])[1];
        count += 1;
    end
    starttime = u2d(stimemin); #convert union time to calendar time;
    endtime = u2d(etimemax);
    #the following info dat is saved after running through the whole group.
    file["info/stationlist"] = stationlist;
    file["info/starttime"]   = string(starttime)
    file["info/endtime"]     = string(endtime)
    file["info/DL_time_unit"]= saclengthmax; #length of the data in time (duration), not number of samples

    JLD2.close(file);

    print("Saved JLD2 file to: ", outfile, "\n");
end

"""

    sac2jld2(sacdirlist,timestamplist,outfile)

Searches for all sac files scanning throgh the sacdirlist (Array{String,1}). The sac files
    in each sac directory are assigned to one time stamp based on timestamplist (Array{String,1}).
    The two Arrays must be equal in size. The list can be generated from a file list (using ls in shell),
    using a utility function in this package: readfilelist(infilelist::String).

All sac files will be saved into one single JLD2 file (out), which is explicitly specified as outfile.
    sacdirlist: An array of strings storing the directories grouped by time stamp, e.g., one day.
    timestamplist: An array of strings storing the time stamps assigning to each SAC file group.
    outfile: output file name for the JLD2 file. All data fiels will be readin and
                saved to a single JLD2 file.
"""

function sac2jld2(sacdirlist::Array{String,1},timestamplist::Array{String,1},outfile::String)
    print("Not finished.\n")

    #read the filenames from the infilelist into a strinng array
    filelist = readfilelist(infilelist)

    stationlist = String[];
    DLtimestamplist = String[];
    push!(DLtimestamplist,timestamp); #use the specified timestamp for the group.

    count=1;

    #get some intial information from the first sac file.
    sacin0 = SeisIO.read_data("sac",filelist[1]);
    stimemin = sacin0.t[1][3]*1e-6; #initial starttime in seconds;
    ftemp = sacin0.t[1][2]/sacin0.fs; #convert from number of samples to time duration.
    saclengthmax = ftemp[1]
    etimemax = stimemin + saclengthmax;

    file = jldopen(outfile, "w");
    file["info/DLtimestamplist"] = timestamplist;

    #in the loop for each sac file. we will find the minimum starttime, maximum endtime, and maximum saclength.
    for infile = filelist
        print("Converting SAC file: [ ",infile," ] ... ",count,"\n")

        sacin = SeisIO.read_data("sac",infile);
        push!(stationlist,sacin.id[1])  #pass the 1st element of sacin.id[] to the station list
        # stationinfo = Dict(["stationlist" => stationlist,"stationmethod" => "sac2jld2","stationsrc" => "converted"])
        stimetemp = sacin.t[1][3]*1e-6; #convert mseconds to seconds;
        if stimetemp < stimemin
            stimemin = stimetemp
        end
        saclength = sacin.t[1][2]/sacin.fs; #convert from number of samples to time duration.
        if saclength[1] > saclengthmax
            saclengthmax = saclength[1]
        end
        etimetemp = stimetemp + saclength[1]
        if etimetemp > etimemax
            etimemax = etimetemp
        end

        #save to jld2
        stemp = joinpath(timestamp,sacin.id[1]);

        #save the waveform data as SeisData format.
        file[stemp] = SeisData(sacin[1])[1];
        count += 1;
    end
    starttime = u2d(stimemin); #convert union time to calendar time;
    endtime = u2d(etimemax);
    #the following info dat is saved after running through the whole group.
    file["info/stationlist"] = stationlist;
    file["info/starttime"]   = string(starttime)
    file["info/endtime"]     = string(endtime)
    file["info/DL_time_unit"]= saclengthmax; #length of the data in time (duration), not number of samples

    JLD2.close(file);

    print("Saved JLD2 file to: ", outfile, "\n");
end
