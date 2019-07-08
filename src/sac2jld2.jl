using SeisIO, JLD2, Distributed

export sac2jld2, sac2jld2_par
#


# Converting sac data to JLD2 format. There are options to save to JLD2 format
# as single file or separate files for each sac file.
"""
Key features:
1. Can be used to convert individual SAC file or a group/list of SAC files.
2. Handles the situation when multiple data files were download for the same station
    and channel. Those files will be merged into one single SeisData object with
    multiple SeisChannel entries.
3. All SAC headers are kept and saved in :misc filed of the SeisData object.

"""


"""

    sac2jld2(infile)

Saves individual sac file (in) to JLD2 file.
The output file name will be the same as the input, with new extension *.jld2.

"""

function sac2jld2(infile::String)
    print("Same file, new extension of jld2.\n")
    print("Converting SAC file: [ ",infile," ] ... \n")
    outfile = join([infile[1:end-3],"jld2"]); #trim the file name to remove .sac
    sacin = SeisIO.read_data("sac",infile,full=true);

    stationlist = String[];
    push!(stationlist,sacin.id[1])  #pass the 1st element of sacin.id[] to the station list
    # stationinfo = Dict(["stationlist" => stationlist,"stationmethod" => "sac2jld2","stationsrc" => "converted"])
    stimetemp = sacin.t[1][3]*1e-6; #convert mseconds to seconds;
    saclength = sacin.t[1][2]/sacin.fs; #convert from number of samples to time duration.
    starttime = u2d(stimetemp[1]); #convert union time to calendar time;
    endtime = u2d(stimetemp[1] + saclength[1]);
    DLtimestamplist = String[];
    push!(DLtimestamplist,replace(string(starttime),"-" => "."));

    #save to jld2
    stemp = joinpath(DLtimestamplist[1],stationlist[1]);
    file = jldopen(outfile, "w");
    file["info/DLtimestamplist"] = DLtimestamplist;
    file["info/stationlist"] = stationlist;
    file["info/starttime"]   = string(starttime)
    file["info/endtime"]     = string(endtime)
    file["info/DL_time_unit"]= saclength[1]; #length of the data in time (duration), not number of samples

    #save the waveform data as SeisData format.
    file[stemp] = SeisData(sacin);

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
    sacin = SeisIO.read_data("sac",infile,full=true);

    stationlist = String[];
    push!(stationlist,sacin.id[1])  #pass the 1st element of sacin.id[] to the station list
    # stationinfo = Dict(["stationlist" => stationlist,"stationmethod" => "sac2jld2","stationsrc" => "converted"])
    stimetemp = sacin.t[1][3]*1e-6; #convert mseconds to seconds;
    saclength = sacin.t[1][2]/sacin.fs; #convert from number of samples to time duration.
    starttime = u2d(stimetemp[1]); #convert union time to calendar time;
    endtime = u2d(stimetemp[1] + saclength[1]);
    DLtimestamplist = String[];
    push!(DLtimestamplist,replace(string(starttime),"-" => "."));

    #save to jld2
    stemp = joinpath(DLtimestamplist[1],stationlist[1]);
    file = jldopen(outfile, "w");
    file["info/DLtimestamplist"] = DLtimestamplist;
    file["info/stationlist"] = stationlist;
    file["info/starttime"]   = string(starttime)
    file["info/endtime"]     = string(endtime)
    file["info/DL_time_unit"]= saclength[1]; #length of the data in time (duration), not number of samples

    #save the waveform data as SeisData format.
    file[stemp] = SeisData(sacin);

    JLD2.close(file);

    print("Saved JLD2 file to: ", outfile, "\n");
end

"""

    sac2jld2(filelist,timestamp,outfile,verbose=false)

Saves sac files based on a filelist generated using ls() in Julia to
JLD2 file (out), which is explicitly specified.

    Arguments:
    filelist: An String Array including all sacfiles with the same tiemstamp, e.g., same day
    tiemstamp: this must be specified for the sac fiels, assuming they all share
                the same time stamp. Suggested format: 2019.06.27T00.00.00
    outfile: output file name for the JLD2 file. All data fiels will be readin and
                saved to a single JLD2 file.
    verbose: if true, the code will print out more messages. Default is false.
"""

function sac2jld2(filelist::Array{String,1},timestamp::String,outfile::String,verbose::Bool=false)
    # print("I convert and pack all SAC files to a JLD2 file.\n")

    #read the filenames from the infilelist into a strinng array
    # filelist = readfilelist(infilelist)

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
    stemp_pre = "-"
    #in the loop for each sac file. we will find the minimum starttime, maximum endtime, and maximum saclength.
    for infile = filelist
        print("Converting SAC file: [ ",infile," ] ... ",count,"\n")

        sacin = SeisIO.read_data("sac",infile,full=true);
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
        if stemp == stemp_pre
            println(stemp," exists. Appending to form multiple channels.")
            append!(file[stemp],SeisData(sacin))
        else
            file[stemp] = SeisData(sacin);
        end
        stemp_pre = stemp
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

    sac2jld2(fhandle::JLDfile, sacdir::String,timestamp::String,verbose::Bool=false)

Saves sac files based in sacdir to JLD2 file handle (fhandle), tagged as timestamp.

    Arguments:
    fhandle: A JLD2 file handle, generated using jldopen(), with write permission.
    sacdir: directory containing the sac files need to convert.
    tiemstamp: this must be specified for the sac fiels, assuming they all share
                the same time stamp. Suggested format: 2019.06.27T00.00.00
    verbose: if true, the code will print out more messages. Default is false.
"""

function sac2jld2(fhandle::JLD2.JLDFile, sacdir::String,timestamp::String,verbose::Bool=false)
    # print("I convert and pack all SAC files to a JLD2 file.\n")

    filelist=ls(joinpath(sacdir,"*.sac"));
    println("Converting SAC dir: ",sacdir,"=> ",length(filelist)," files.")

    stemp_pre = "-"
    #in the loop for each sac file. we will find the minimum starttime, maximum endtime, and maximum saclength.
    for infile = filelist
        if verbose == true
            print("Converting SAC file: [ ",infile," ] ... ",count,"\n")
        end

        sacin = SeisIO.read_data("sac",infile,full=true);

        #save to jld2
        stemp = joinpath(timestamp,sacin.id[1]);
        if stemp == stemp_pre
            println(stemp," exists. Appending to form multiple channels.")
            append!(fhandle[stemp],SeisData(sacin))
        else
            fhandle[stemp] = SeisData(sacin);
        end
        stemp_pre = stemp
    end
end

"""

    sac2jld2(sacdirlist,timestamplist,outfile,verbose=false)

Searches for all sac files scanning throgh the sacdirlist (Array{String,1}). The sac files
    in each sac directory are assigned to one time stamp based on timestamplist (Array{String,1}).
    The two Arrays must be equal in size. The list can be generated from a file list (using ls in shell),
    using a utility function in this package: readfilelist(infilelist::String).

All sac files will be saved into one single JLD2 file (out), which is explicitly specified as outfile.

    Arguments:
    sacdirlist: An array of strings storing the directories grouped by time stamp, e.g., one day.
    timestamplist: An array of strings storing the time stamps assigning to each SAC file group.
    outfile: output file name for the JLD2 file. All data fiels will be readin and
                saved to a single JLD2 file.
    verbose: if true, the code will print out more messages. Default is false.
"""

function sac2jld2(sacdirlist::Array{String,1},timestamplist::Array{String,1},outfile::String,verbose::Bool=false)
    if length(sacdirlist) != length(timestamplist)
        error("sacdirlist and timestamplist must be the same length!")
    end

    stationlist = String[];

    saclengthmax = 0; #initiate the length as zero, will find the maximum value after looping through the files.

    file = jldopen(outfile, "w");
    file["info/DLtimestamplist"] = timestamplist;
    file["info/starttime"] = timestamplist[1];
    #here we use the first value in timestamplist as the starttime for a group of multiple timestamp data.
    file["info/endtime"] = timestamplist[end]; #similar to starttime, here we use the last value in timestamplist as the endtime.

    #in the loop for each sac file in each SAC directory. we will find the maximum saclength.
    countdir=1;
    for sacdir = sacdirlist
        filelist=ls(joinpath(sacdir,"*.sac"));

        print("Converting for directory: [ ",sacdir," ] ... \n")

        count = 0
        stationlisttemp = String[];
        stemp_pre = "-"
        for infile = filelist
            sacin = SeisIO.read_data("sac",infile,full=true);
            push!(stationlisttemp,sacin.id[1])  #pass the 1st element of sacin.id[] to the station list

            saclength = sacin.t[1][2]/sacin.fs; #convert from number of samples to time duration.
            if saclength[1] > saclengthmax
                saclengthmax = saclength[1]
            end

            #save to jld2
            #save the waveform data as SeisData format.
            stemp = joinpath(timestamplist[countdir],sacin.id[1]);
            # if verbose == true
            #     println("00 current: ",stemp)
            #     println("11 previous: ",stemp_pre)
            # end
            if stemp == stemp_pre
                println(stemp," exists. Append to form multiple channels.")
                append!(file[stemp],SeisData(sacin))
            else
                file[stemp] = SeisData(sacin);
            end
            """
            # try
                    file[stemp] = SeisData(sacin);
                end
            # catch saveerror
                # stemp = joinpath(timestamplist[countdir],sacin.id[1]);
                # append!(file[stemp],SeisData(sacin))
                # println(saveerror)
                # if occursin("already present within this group",string(saveerror))
                #     stemp = joinpath(timestamplist[countdir],sacin.id[1]);
                #     # creating multiple channels
                #     println(stemp,"::Appending to form multiple channels.")
                #     append!(file[stemp],SeisData(sacin))
                # else
                #     error("Cannot save group: ",stemp," to ",outfile)
                # end
            end
            """
            stemp_pre = stemp;
            if verbose == true
                count += 1
            end
        end #end of loop for all sac files within one group/directory
        if verbose == true
            print("-----------------------> ",count," sac files \n")
        end
        countdir += 1;

        stationlist=unique(stationlisttemp)
    end #end of loop for all SAC directories.

    #the following info dat is saved after running through the whole group.
    file["info/stationlist"] = stationlist;
    file["info/DL_time_unit"]= saclengthmax; #length of the data in time (duration), not number of samples

    JLD2.close(file);

    print("Saved JLD2 file to: ", outfile, "\n");
end

"""
    sac2jld2_par(sacdirlist,timestamplist,outfile,verbose=false)

Searches for all sac files scanning throgh the sacdirlist (Array{String,1}). The sac files
    in each sac directory are assigned to one time stamp based on timestamplist (Array{String,1}).
    The two Arrays must be equal in size. The list can be generated from a file list (using ls in shell),
    using a utility function in this package: readfilelist(infilelist::String).

All sac files will be saved into one single JLD2 file (out), which is explicitly specified as outfile.

    Arguments:
    sacdirlist: An array of strings storing the directories grouped by time stamp, e.g., one day.
    timestamplist: An array of strings storing the time stamps assigning to each SAC file group.
    outfile: output file name for the JLD2 file. All data fiels will be readin and
                saved to a single JLD2 file.
    verbose: if true, the code will print out more messages. Default is false.
"""
# For parallel processing, the "info/DL_time_unit" is based on ONLY the first sac file.
function sac2jld2_par(sacdirlist::Array{String,1},timestamplist::Array{String,1},outfile::String,verbose::Bool=false)
    if length(sacdirlist) != length(timestamplist)
        error("sacdirlist and timestamplist must be the same length!")
    end

    stationlist = String[];
    filelisttemp=ls(joinpath(sacdirlist[1],"*.sac"));
    sacin0 = SeisIO.read_data("sac",filelisttemp[1],full=true);

    file = jldopen(outfile, "w");
    saclengthmax = sacin0.t[1][2]/sacin0.fs; #initiate the length as zero, will find the maximum value after looping through the files.
    file["info/DL_time_unit"]= saclengthmax; #length of the data in time (duration), not number of samples

    file["info/DLtimestamplist"] = timestamplist;
    file["info/starttime"] = timestamplist[1];
    #here we use the first value in timestamplist as the starttime for a group of multiple timestamp data.
    file["info/endtime"] = timestamplist[end]; #similar to starttime, here we use the last value in timestamplist as the endtime.

    #call pmap to accomplish the prallel processing
    perror=pmap((x,y)->sac2jld2(file,x,y,verbose),sacdirlist,timestamplist)

    #loop through timestamplist to get the stationlist
    for ts in timestamplist
        stationlist = unique(vcat(stationlist,keys(file[ts])))
    end

    #the following info dat is saved after running through the whole group.
    file["info/stationlist"] = stationlist;

    JLD2.close(file);

    print("Saved JLD2 file to: ", outfile, "\n");
end
