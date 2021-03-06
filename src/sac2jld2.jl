using SeisIO, JLD2, Distributed, Sockets

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
    sacin.misc[1]["dlerror"] = 0

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
    sacin.misc[1]["dlerror"] = 0

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

    #get some intial information from the first sac file.
    sacin0 = SeisIO.read_data("sac",filelist[1]);
    stimemin = sacin0.t[1][3]*1e-6; #initial starttime in seconds;
    ftemp = sacin0.t[1][2]/sacin0.fs; #convert from number of samples to time duration.
    saclengthmax = ftemp[1]
    etimemax = stimemin + saclengthmax;

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

    #in the loop for each sac file. we will find the minimum starttime, maximum endtime, and maximum saclength.
    for infile = filelist
        println("Converting SAC file: [ ",infile," ]")

        sacin = SeisIO.read_data("sac",infile,full=true);
        sacin.misc[1]["dlerror"] = 0
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
            append!(Sall[count],SeisData(sacin))
        else
            push!(Sall,SeisData(sacin))
            push!(Str_all,stemp)
            count += 1
            # file[stemp] = SeisData(sacin);
        end
        stemp_pre = stemp
    end
    starttime = u2d(stimemin); #convert union time to calendar time;
    endtime = u2d(etimemax);
    #the following info dat is saved after running through the whole group.
    file["info/stationlist"] = unique(stationlist);
    file["info/starttime"]   = string(starttime)
    file["info/endtime"]     = string(endtime)
    file["info/DL_time_unit"]= saclengthmax; #length of the data in time (duration), not number of samples

    #2. start to save the data to jld2
    for i = 1:count
        file[Str_all[i]] = Sall[i]
    end #end of loop for all sac files within one group/directory

    JLD2.close(file);

    print("Saved JLD2 file to: ", outfile, "\n");
end

"""

    sac2jld2(filelist,timestamplist,outfile,verbose=false)

Saves sac files based on a filelist generated using ls() in Julia to
JLD2 file (out), which is explicitly specified. This function assumes each file in
filelist is assigned a timestamp in timestamplist.

    Arguments:
    filelist: An String Array including all sacfiles with the same tiemstamp, e.g., same day
    tiemstamplist: this must be specified for all the sac files in filelist. This list has to be
                the same length as filelist.
    outfile: output file name for the JLD2 file. All data fiels will be readin and
                saved to a single JLD2 file.
    verbose: if true, the code will print out more messages. Default is false.
"""

function sac2jld2(filelist::Array{String,1};timestamplist::Array{String,1},outfile::String,verbose::Bool=false)
    if length(filelist) != length(timestamplist)
        error("filelist and timestamplist must be the same length!")
    end
    stationlist = String[];

    #get some intial information from the first sac file.
    sacin0 = SeisIO.read_data("sac",filelist[1]);
    stimemin = sacin0.t[1][3]*1e-6; #initial starttime in seconds;
    ftemp = sacin0.t[1][2]/sacin0.fs; #convert from number of samples to time duration.
    saclengthmax = ftemp[1]
    etimemax = stimemin + saclengthmax;

    file = jldopen(outfile, "w");
    file["info/DLtimestamplist"] = unique(timestamplist);
    stemp_pre = "-"
    count = 0
    # stationlisttemp = String[];
    #To deal with multiple channel issue, I am doing the loop twice.
    # 1. The first loop with collect multiple channels into one SeisData object.
    # 2. The second loop will work through the actual number of SeisData objects, counted by `count`
    Sall = SeisData[];
    Str_all = String[];

    #in the loop for each sac file. we will find the minimum starttime, maximum endtime, and maximum saclength.
    for (infile,ts) in zip(filelist,timestamplist)
        println("Converting SAC file: [ ",infile," ]")

        sacin = SeisIO.read_data("sac",infile,full=true);
        sacin.misc[1]["dlerror"] = 0
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
        stemp = joinpath(ts,sacin.id[1]);
        if stemp == stemp_pre
            println(stemp," exists. Appending to form multiple channels.")
            append!(Sall[count],SeisData(sacin))
        else
            push!(Sall,SeisData(sacin))
            push!(Str_all,stemp)
            count += 1
            # file[stemp] = SeisData(sacin);
        end
        stemp_pre = stemp
    end
    starttime = u2d(stimemin); #convert union time to calendar time;
    endtime = u2d(etimemax);
    #the following info dat is saved after running through the whole group.
    file["info/stationlist"] = unique(stationlist);
    file["info/starttime"]   = string(starttime)
    file["info/endtime"]     = string(endtime)
    file["info/DL_time_unit"]= saclengthmax; #length of the data in time (duration), not number of samples

    #2. start to save the data to jld2
    for i = 1:count
        file[Str_all[i]] = Sall[i]
    end #end of loop for all sac files within one group/directory

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
    count = 0
    #To deal with multiple channel issue, I am doing the loop twice.
    # 1. The first loop with collect multiple channels into one SeisData object.
    # 2. The second loop will work through the actual number of SeisData objects, counted by `count`
    Sall = SeisData[];
    Str_all = String[];
    #in the loop for each sac file. we will find the minimum starttime, maximum endtime, and maximum saclength.
    for infile = filelist
        if verbose == true
            print("Converting SAC file: [ ",infile," ] ...\n")
        end

        sacin = SeisIO.read_data("sac",infile,full=true);
        sacin.misc[1]["dlerror"] = 0

        #save to jld2
        stemp = joinpath(timestamp,sacin.id[1]);
        println(stemp)
        if stemp == stemp_pre
            if verbose == true
                println(stemp," exists. Appending to form multiple channels.")
            end
            append!(Sall[count],SeisData(sacin))
        else
            push!(Sall,SeisData(sacin))
            push!(Str_all,stemp)
            count += 1
            # file[stemp] = SeisData(sacin);
        end
        stemp_pre = stemp
    end

    #2. start to save the data to jld2
    for i = 1:count
        fhandle[Str_all[i]] = Sall[i]
    end #end of loop for all sac files within one group/directory
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

    # saclengthmax = 0; #initiate the length as zero, will find the maximum value after looping through the files.

    file = jldopen(outfile, "w");
    file["info/DLtimestamplist"] = timestamplist;
    file["info/starttime"] = timestamplist[1];
    #here we use the first value in timestamplist as the starttime for a group of multiple timestamp data.
    file["info/endtime"] = timestamplist[end]; #similar to starttime, here we use the last value in timestamplist as the endtime.

    #in the loop for each sac file in each SAC directory. we will find the maximum saclength.
    # countdir=1;
    t1all=0
    t2all=0
    for (sacdir,ts) in zip(sacdirlist,timestamplist)

        t0=time()
        filelist=ls(joinpath(sacdir,"*.sac"));

        print("Converting for directory: [ ",sacdir," ] ... \n")

        count = 0
        # stationlisttemp = String[];
        #To deal with multiple channel issue, I am doing the loop twice.
        # 1. The first loop with collect multiple channels into one SeisData object.
        # 2. The second loop will work through the actual number of SeisData objects, counted by `count`
        Sall = SeisData[];
        Str_all = String[];
        stemp_pre = "-"
        for infile = filelist
            # t1=@elapsed sacin = SeisIO.read_data("sac",infile,full=true);
            sacin = SeisIO.read_data("sac",infile,full=true);
            sacin.misc[1]["dlerror"] = 0

            if sacdir == sacdirlist[1] && infile == filelist[1]
                # println(sacdir)
                file["info/DL_time_unit"]= sacin.t[1][2]/sacin.fs; #length of the data in time (duration), not number of samples;
                #convert from number of samples to time duration.
            end

            stemp = joinpath(ts,sacin.id[1]);
            # if verbose == true
            #     println("00 current: ",stemp)
            #     println("11 previous: ",stemp_pre)
            # end
            # t2=@elapsed if stemp == stemp_pre
            if stemp == stemp_pre
                if verbose == true
                    println(stemp," exists. Append to form multiple channels.")
                end
                append!(Sall[count],SeisData(sacin))
            else
                push!(Sall,SeisData(sacin))
                push!(Str_all,stemp)
                count += 1
                # file[stemp] = SeisData(sacin);
            end

            stemp_pre = stemp;

        end #end of loop for all sac files within one group/directory

        #2. start to save the data to jld2
        for i = 1:count
            file[Str_all[i]] = Sall[i]
        end #end of loop for all sac files within one group/directory

        stationlist = unique(vcat(stationlist,keys(file[ts])))
        if verbose == true
            print("                ----------------> ",length(filelist)," sac files, time used: ",time() - t0,"\n")
        end

    end #end of loop for all SAC directories.

    # println([t1all, t2all])
    #the following info dat is saved after running through the whole group.
    file["info/stationlist"] = stationlist;

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
    #length of the data in time (duration), not number of samples
    file = jldopen(outfile,"w")

    file["info/DLtimestamplist"] = timestamplist;
    file["info/starttime"] = timestamplist[1];
    #here we use the first value in timestamplist as the starttime for a group of multiple timestamp data.
    file["info/endtime"] = timestamplist[end]; #similar to starttime, here we use the last value in timestamplist as the endtime.

    # function testread(x, filelist)
    #     #println(myid())
    #     SeisIO.read_data("sac",filelist[x],full=true)
    # end

    t1all = 0
    t2all = 0
    t3all = 0

    for (sacdir,ts) in zip(sacdirlist,timestamplist)
        t0=time()
        filelist=ls(joinpath(sacdir,"*.sac"));

        print("Converting for directory: [ ",sacdir," ] ... \n")

        S=pmap(x->SeisIO.read_data("sac",x,full=true),filelist)

        if ts == timestamplist[1]
            file["info/DL_time_unit"]= S[1].t[1][2]/S[1].fs;
        end
        count = 0
        # stationlisttemp = String[];
        #To deal with multiple channel issue, I am doing the loop twice.
        # 1. The first loop with collect multiple channels into one SeisData object.
        # 2. The second loop will work through the actual number of SeisData objects, counted by `count`
        Sall = SeisData[];
        Str_all = String[];

        stemp_pre = "-"
        for Sdata = S
            Sdata.misc[1]["dlerror"] = 0
            stemp = joinpath(ts,Sdata.id[1])
            if stemp == stemp_pre
                println(stemp," exists. Append to form multiple channels.")
                append!(Sall[count],SeisData(Sdata))
            else
                push!(Sall,SeisData(Sdata))
                push!(Str_all,stemp)
                count += 1
                # file[stemp] = SeisData(sacin);
            end
            stemp_pre = stemp;
        end

        #2. start to save the data to jld2
        for i = 1:count
            file[Str_all[i]] = Sall[i]
        end #end of loop for all sac files within one group/directory

        stationlist = unique(vcat(stationlist,keys(file[ts])))
        if verbose == true
            print("                ----------------> ",length(filelist)," sac files, time used: ",time() - t0,"\n")
        end

        # t1all += t1
    end #end of loop for all SAC directories.

    # println([t1all, t2all, t3all])

    #the following info dat is saved after running through the whole group.
    file["info/stationlist"] = stationlist;

    JLD2.close(file);

    print("Saved JLD2 file to: ", outfile, "\n");
    rmprocs(workers())
end
