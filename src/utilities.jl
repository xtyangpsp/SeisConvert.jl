# some utility functions.
using SeisIO, Printf

export readfilelist, writesac_corr

const sac_nul_f = -12345.0f0
const sac_nul_i = Int32(-12345)
const sac_nul_start = 0x2d
const sac_nul_Int8 = UInt8[0x31, 0x32, 0x33, 0x34, 0x35]
const μs = 1.0e-6

function readfilelist(infilelist::String)
    outlist = String[];
    open(infilelist) do f
        for ln in eachline(f)
          push!(outlist,ln)
        end
    end
    return(outlist)
end

# this function and fill_sac_corr(), and writesac() were modified from those in SeisIO
# I modified it to save correlation data, which has two station information in the name.
function write_sac_file(fname::String, fv::Array{Float32,1}, iv::Array{Int32,1}, cv::Array{UInt8,1}, x::Array{Float32,1}; t=[Float32(0)]::Array{Float32,1}, ts=true::Bool)
  f = open(fname, "w")
  write(f, fv)
  write(f, iv)
  write(f, cv)
  write(f, x)
  if ts
    write(f, t)
  end
  close(f)
  return
end
function fill_sac_corr(S::GphysChannel, ts::Bool, leven::Bool)
  fv = sac_nul_f.*ones(Float32, 70)
  iv = sac_nul_i.*ones(Int32, 40)
  cv = repeat(vcat(sac_nul_Int8, sac_nul_start, 0x20, 0x20), 24)
  cv[17:22] .= 0x20

  # Ints
  T = getfield(S, :t)
  tt = Int32[Base.parse(Int32, i) for i in split(string(u2d(T[1,2]*μs)),r"[\.\:T\-]")]
  length(tt) == 6 && append!(tt, zero(Int32))
  y = tt[1]
  j = Int32(md2j(y, tt[2], tt[3]))
  iv[1:6] = prepend!(tt[4:7], [y, j])
  iv[7] = Int32(6)
  iv[10] = Int32(length(S.x))
  iv[16] = Int32(ts ? 4 : 1)
  iv[36] = Int32(leven ? 1 : 0)

  # Floats
  dt = 1.0/S.fs
  fv[1] = Float32(dt)
  fv[4] = Float32(S.gain)
  fv[6]=Float32(S.misc["b"])
  fv[7]=Float32(S.misc["e"])
  # fv[6] = rem(T[1,2], 1000)*1.0f-3
  # fv[7] = Float32(dt*length(S.x) + sum(T[2:end,2])*μs)
  # if !isempty(S.loc)
  #   loc = getfield(S, :loc)
  #   println(typeof(loc))
  #   if typeof(loc) == GeoLoc
  #     # println("getting locations.")
  #     fv[32] = Float32(getfield(loc, :lat))
  #     fv[33] = Float32(getfield(loc, :lon))
  #     fv[34] = Float32(getfield(loc, :el))
  #     fv[58] = Float32(getfield(loc, :az))
  #     fv[59] = Float32(getfield(loc, :inc))
  #   end
  # else
  #   println("loc field is empty")
  # end

  #get station and event locations from misc fiels, assuming they are saved.
  fv[36]=Float32(S.misc["evla"])
  fv[37]=Float32(S.misc["evlo"])
  fv[39]=Float32(S.misc["evdp"])
  fv[32]=Float32(S.misc["stla"])
  fv[33]=Float32(S.misc["stlo"])
  fv[34]=Float32(S.misc["stel"])

  # Chars (ugh...)
  id_temp = String.(split(S.name,'.')) #8 entries for CorrData naming convention: two stations.
  evname = id_temp[1]*"."*id_temp[2]*"."*id_temp[3]*"."*id_temp[4] #
  # println(evname)
  id = [evname; id_temp[5:8]]
  #change component name to CorrData.comp
  id[5] = S.misc["comp"]
  #make the first station as event
  ci = [9, 169, 1, 25, 161]
  Lc = [16, 8, 8, 8, 8]
  for i = 1:length(id)
    if !isempty(id[i])
      L_max = Lc[i]
      si = ci[i]
      ei = ci[i] + L_max - 1
      s = codeunits(id[i])
      Ls = length(s)
      L = min(Ls, L_max)
      copyto!(cv, si, s, 1, L)
      if L < L_max
        cv[si+L:ei] .= 0x20
      end
    end
  end
  #other character headers
  kh= String[]
  push!(kh,S.misc["corr_type"])
  push!(kh,S.misc["whitened"])
  push!(kh,S.misc["time_norm"])

  ci = [137, 145, 153]
  Lc = [8, 8, 8]
  for i = 1:length(kh)
    if !isempty(kh[i])
      L_max = Lc[i]
      si = ci[i]
      ei = ci[i] + L_max - 1
      s = codeunits(kh[i])
      Ls = length(s)
      L = min(Ls, L_max)
      copyto!(cv, si, s, 1, L)
      if L < L_max
        cv[si+L:ei] .= 0x20
      end
    end
  end


  #other header values.
  fv[2]=Float32(S.misc["depmin"])
  fv[3]=Float32(S.misc["depmax"])
  fv[57]=Float32(S.misc["depmen"])
  fv[41]=Float32(S.misc["freqmin"])
  fv[42]=Float32(S.misc["freqmax"])
  fv[43]=Float32(S.misc["cc_len"])
  fv[44]=Float32(S.misc["cc_step"])

  # Assign a filename
  y_s = string(y); y_s="0"^(4-length(y_s))*y_s
  j_s = string(j); j_s="0"^(3-length(j_s))*j_s
  h_s = string(tt[4]); h_s="0"^(2-length(h_s))*h_s
  m_s = string(tt[5]); m_s="0"^(2-length(m_s))*m_s
  s_s = string(tt[6]); s_s="0"^(2-length(s_s))*s_s
  ms_s = string(tt[7]); ms_s="0"^(3-length(ms_s))*ms_s
  fname = join([y_s, j_s,h_s, m_s, s_s, ms_s, id[1], id[2], id[3], id[4],id_temp[8],id[5],"sac"],'.')
  return (fv, iv, cv, fname)
end

"""
    writesac(S::Union{SeisData}[; ts=false, v=0])

Write all data in SeisData structure `S` to auto-generated SAC files.
"""
function writesac_corr(S::GphysData; outdir::String="", outfile::String="", ts::Bool=false, v::Int64=0)
  if ts
    ift = Int32(4); leven = false
  else
    ift = Int32(1); leven = true
  end
  tdata = Array{Float32}(undef, 0)
  N     = S.n
  for i = 1:N
    T = getindex(S, i)
    b = T.t[1,2]
    dt = 1.0/T.fs
    (fv, iv, cv, fname) = fill_sac_corr(T, ts, leven)

    # Data
    x = eltype(T.x) == Float32 ? getfield(T, :x) : map(Float32, T.x)
    ts && (tdata = map(Float32, μs*(t_expand(T.t, dt) .- b)))

    # Write to file
    # println(fname)
    if isempty(outfile)
      fname2 =fname[1:end-4]*"_"*string(i)*".sac"
    else
      fname2 = outfile
    end
    # println(fname2)
    if length(outdir) > 0
      mkpath(outdir)
      write_sac_file(outdir*"/"*fname2, fv, iv, cv, x, t=tdata, ts=ts)
    else
      write_sac_file(fname2, fv, iv, cv, x, t=tdata, ts=ts)
    end
    v > 0  && @printf(stdout, "%s: Wrote file %s from channel %i\n", string(now()), fname2, i)
  end
end

function writesac_seis(S::GphysData; outdir::String="", outfile::String="", ts::Bool=false, v::Int64=0)
  if ts
    ift = Int32(4); leven = false
  else
    ift = Int32(1); leven = true
  end
  tdata = Array{Float32}(undef, 0)
  N     = S.n
  for i = 1:N
    T = getindex(S, i)
    b = T.t[1,2]
    dt = 1.0/T.fs
    (fv, iv, cv, fname) = fill_sac(T, ts, leven)

    # Data
    x = eltype(T.x) == Float32 ? getfield(T, :x) : map(Float32, T.x)
    ts && (tdata = map(Float32, μs*(t_expand(T.t, dt) .- b)))

    # Write to file
    # println(fname)
    if isempty(outfile)
      fname2 =fname[1:end-6]*"_"*string(i)*".sac"
    else
      fname2 = outfile
    end
    # println(fname2)
    if length(outdir) > 0
      mkpath(outdir)
      write_sac_file(outdir*"/"*fname2, fv, iv, cv, x, t=tdata, ts=ts)
    else
      write_sac_file(fname2, fv, iv, cv, x, t=tdata, ts=ts)
    end
    v > 0  && @printf(stdout, "%s: Wrote file %s from channel %i\n", string(now()), fname2, i)
  end
end
