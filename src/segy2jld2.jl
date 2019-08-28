using SeisIO, JLD2, Distributed, Sockets

export segy2jld2
#


# Converting PASSCAL segy data to JLD2 format. There are options to save to JLD2 format
# as single file or separate files for each segy file.
"""
Key features:
1. Can be used to convert individual SEGY (PASSCAL VARIATION FORMAT ONLY FOR NOW) file or a group/list of SEGY files.
2. Handles the situation when multiple data files were download for the same station
    and channel. Those files will be merged into one single SeisData object with
    multiple SeisChannel entries.
3. All SEGY headers are kept and saved in :misc filed of the SeisData object.

"""


"""

    segy2jld2(infile)

Saves individual segy file (in) to JLD2 file.
The output file name will be the same as the input, with new extension *.jld2.

"""

function segy2jld2(infile::String)
    print("Same file, new extension of jld2.\n")
    print("Converting PASSCAL SEGY file: [ ",infile," ] ... \n")
    if occursin("segy",infile) || occursin("SEGY",infile)
        outfile = join([infile[1:end-4],"jld2"]); #trim the file name to remove .segy
    else
        outfile = join([infile,".jld2"]);
    end
    datin = SeisIO.read_data("passcal",infile, swap=true, full=true);
    datin.misc[1]["dlerror"] = 0

    stationlist = String[];
    push!(stationlist,datin.id[1])  #pass the 1st element of datin.id[] to the station list
    # stationinfo = Dict(["stationlist" => stationlist,"stationmethod" => "SEGY2jld2","stationsrc" => "converted"])
    stimetemp = datin.t[1][3]*1e-6; #convert mseconds to seconds;
    datlength = datin.t[1][2]/datin.fs; #convert from number of samples to time duration.
    starttime = u2d(stimetemp[1]); #convert union time to calendar time;
    endtime = u2d(stimetemp[1] + datlength[1]);
    DLtimestamplist = String[];
    push!(DLtimestamplist,replace(string(starttime),"-" => "."));

    #save to jld2
    stemp = joinpath(DLtimestamplist[1],stationlist[1]);
    file = jldopen(outfile, "w");
    file["info/DLtimestamplist"] = DLtimestamplist;
    file["info/stationlist"] = stationlist;
    file["info/starttime"]   = string(starttime)
    file["info/endtime"]     = string(endtime)
    file["info/DL_time_unit"]= datlength[1]; #length of the data in time (duration), not number of samples

    #save the waveform data as SeisData format.
    file[stemp] = SeisData(datin);

    JLD2.close(file);

    print("Saved JLD2 file to: ", outfile, "\n");
end

"""

    segy2jld2(infile,outfile)

Saves individual segy file (in) to JLD2 file (out), which is explicitly specified.

"""

function segy2jld2(infile::String,outfile::String)
    print("Converting PASSCAL SEGY file: [ ",infile," ] ... \n")

    datin = SeisIO.read_data("passcal",infile, swap=true, full=true);
    datin.misc[1]["dlerror"] = 0

    stationlist = String[];
    push!(stationlist,datin.id[1])  #pass the 1st element of datin.id[] to the station list
    # stationinfo = Dict(["stationlist" => stationlist,"stationmethod" => "SEGY2jld2","stationsrc" => "converted"])
    stimetemp = datin.t[1][3]*1e-6; #convert mseconds to seconds;
    datlength = datin.t[1][2]/datin.fs; #convert from number of samples to time duration.
    starttime = u2d(stimetemp[1]); #convert union time to calendar time;
    endtime = u2d(stimetemp[1] + datlength[1]);
    DLtimestamplist = String[];
    push!(DLtimestamplist,replace(string(starttime),"-" => "."));

    #save to jld2
    stemp = joinpath(DLtimestamplist[1],stationlist[1]);
    file = jldopen(outfile, "w");
    file["info/DLtimestamplist"] = DLtimestamplist;
    file["info/stationlist"] = stationlist;
    file["info/starttime"]   = string(starttime)
    file["info/endtime"]     = string(endtime)
    file["info/DL_time_unit"]= datlength[1]; #length of the data in time (duration), not number of samples

    #save the waveform data as SeisData format.
    file[stemp] = SeisData(datin);

    JLD2.close(file);

    print("Saved JLD2 file to: ", outfile, "\n");
end

"""

    segy2jld2(filelist,timestamp,outfile;verbose=false)

Saves segy files based on a filelist generated using ls() in Julia to
JLD2 file (out), which is explicitly specified.

    Arguments:
    filelist: An String Array including all segyfiles with the same tiemstamp, e.g., same day
    tiemstamp: this must be specified for the segy files, assuming they all share
                the same time stamp. Suggested format: 2019.06.27T00.00.00
    outfile: output file name for the JLD2 file. All data fiels will be readin and
                saved to a single JLD2 file.
    verbose: if true, the code will print out more messages. Default is false.
"""

function segy2jld2(filelist::Array{String,1},timestamp::String,outfile::String;verbose::Bool=false)
    # print("I convert and pack all SEGY files to a JLD2 file.\n")

    #read the filenames from the infilelist into a strinng array
    # filelist = readfilelist(infilelist)

    stationlist = String[];
    DLtimestamplist = String[];
    push!(DLtimestamplist,timestamp); #use the specified timestamp for the group.

    #get some intial information from the first SEGY file.
    datin0 = SeisIO.read_data("passcal",filelist[1], swap=true, full=true);
    stimemin = datin0.t[1][3]*1e-6; #initial starttime in seconds;
    ftemp = datin0.t[1][2]/datin0.fs; #convert from number of samples to time duration.
    datlengthmax = ftemp[1]
    etimemax = stimemin + datlengthmax;

    file = jldopen(outfile, "w");
    file["info/DLtimestamplist"] = DLtimestamplist;
    stemp_pre = "-"
    count = 0
    # stationlisttemp = String[];
    #To deal with multiple channel issue, I am doing the loop twice.
    # 1. The first loop with collect multiple channels into one SeisData object.
    # 2. The second loop will work through the actual number of SeisData objects, counted by `count`
    Sall = SeisData[];
    Str_all = String[];

    #in the loop for each SEGY file. we will find the minimum starttime, maximum endtime, and maximum SEGYlength.
    for infile = filelist
        println("Converting SEGY file: [ ",infile," ]")

        datin = SeisIO.read_data("passcal",infile, swap=true, full=true);
        datin.misc[1]["dlerror"] = 0
        push!(stationlist,datin.id[1])  #pass the 1st element of datin.id[] to the station list
        stimetemp = datin.t[1][3]*1e-6; #convert mseconds to seconds;
        if stimetemp < stimemin
            stimemin = stimetemp
        end
        SEGYlength = datin.t[1][2]/datin.fs; #convert from number of samples to time duration.
        if SEGYlength[1] > datlengthmax
            datlengthmax = SEGYlength[1]
        end
        etimetemp = stimetemp + SEGYlength[1]
        if etimetemp > etimemax
            etimemax = etimetemp
        end

        #save to jld2
        stemp = joinpath(timestamp,datin.id[1]);
        if stemp == stemp_pre
            println(stemp," exists. Appending to form multiple channels.")
            append!(Sall[count],SeisData(datin))
        else
            push!(Sall,SeisData(datin))
            push!(Str_all,stemp)
            count += 1
            # file[stemp] = SeisData(datin);
        end
        stemp_pre = stemp
    end
    starttime = u2d(stimemin); #convert union time to calendar time;
    endtime = u2d(etimemax);
    #the following info dat is saved after running through the whole group.
    file["info/stationlist"] = unique(stationlist);
    file["info/starttime"]   = string(starttime)
    file["info/endtime"]     = string(endtime)
    file["info/DL_time_unit"]= datlengthmax; #length of the data in time (duration), not number of samples

    #2. start to save the data to jld2
    for i = 1:count
        file[Str_all[i]] = Sall[i]
    end #end of loop for all SEGY files within one group/directory

    JLD2.close(file);

    print("Saved JLD2 file to: ", outfile, "\n");
end

"""

    segy2jld2(datdirlist,timestamplist,outfile;verbose=false)

Searches for all segy files scanning throgh the datdirlist (Array{String,1}). The segy files
    in each segy directory are assigned to one time stamp based on timestamplist (Array{String,1}).
    The two Arrays must be equal in size. The list can be generated from a file list (using ls in shell),
    using a utility function in this package: readfilelist(infilelist::String).

All segy files will be saved into one single JLD2 file (out), which is explicitly specified as outfile.

    Arguments:
    datdirlist: An array of strings storing the directories grouped by time stamp, e.g., one day.
    timestamplist: An array of strings storing the time stamps assigning to each SEGY file group.
    outfile: output file name for the JLD2 file. All data fiels will be readin and
                saved to a single JLD2 file.
    verbose: if true, the code will print out more messages. Default is false.
"""

function segy2jld2(datdirlist::Array{String,1},timestamplist::Array{String,1},outfile::String;verbose::Bool=false)
    if length(datdirlist) != length(timestamplist)
        error("datdirlist and timestamplist must be the same length!")
    end

    stationlist = String[];

    # datlengthmax = 0; #initiate the length as zero, will find the maximum value after looping through the files.

    file = jldopen(outfile, "w");
    file["info/DLtimestamplist"] = timestamplist;
    file["info/starttime"] = timestamplist[1];
    #here we use the first value in timestamplist as the starttime for a group of multiple timestamp data.
    file["info/endtime"] = timestamplist[end]; #similar to starttime, here we use the last value in timestamplist as the endtime.

    #in the loop for each segy file in each SEGY directory. we will find the maximum datlength.
    # countdir=1;
    t1all=0
    t2all=0
    for (datdir,ts) in zip(datdirlist,timestamplist)

        t0=time()
        filelist=ls(joinpath(datdir,"*"));

        print("Converting for directory: [ ",datdir," ] ... \n")

        count = 0
        # stationlisttemp = String[];
        #To deal with multiple channel issue, I am doing the loop twice.
        # 1. The first loop with collect multiple channels into one SeisData object.
        # 2. The second loop will work through the actual number of SeisData objects, counted by `count`
        Sall = SeisData[];
        Str_all = String[];
        stemp_pre = "-"
        for infile = filelist
            datin = SeisIO.read_data("passcal",infile,swap=true,full=true);
            datin.misc[1]["dlerror"] = 0

            if datdir == datdirlist[1] && infile == filelist[1]
                # println(datdir)
                file["info/DL_time_unit"]= datin.t[1][2]/datin.fs; #length of the data in time (duration), not number of samples;
                #convert from number of samples to time duration.
            end

            stemp = joinpath(ts,datin.id[1]);

            if stemp == stemp_pre
                if verbose == true
                    println(stemp," exists. Append to form multiple channels.")
                end
                append!(Sall[count],SeisData(datin))
            else
                push!(Sall,SeisData(datin))
                push!(Str_all,stemp)
                count += 1
                # file[stemp] = SeisData(datin);
            end

            stemp_pre = stemp;

        end #end of loop for all segy files within one group/directory

        #2. start to save the data to jld2
        for i = 1:count
            file[Str_all[i]] = Sall[i]
        end #end of loop for all segy files within one group/directory

        stationlist = unique(vcat(stationlist,keys(file[ts])))
        if verbose == true
            print("                ----------------> ",length(filelist)," segy files, time used: ",time() - t0,"\n")
        end

    end #end of loop for all SEGY directories.

    # println([t1all, t2all])
    #the following info is saved after running through the whole group.
    file["info/stationlist"] = stationlist;

    JLD2.close(file);

    print("Saved JLD2 file to: ", outfile, "\n");
end
