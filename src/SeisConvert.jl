__precompile__()
module SeisConvert
#This module contains a series of functions to convert seismic data
#between different formats.

# Fields: SeisData, SeisChannel, SeisEvent.data
# 
# Field	Description
# :n	Number of channels [^1]
# :c	TCP connections feeding data to this object [^1]
# :id	Channel ids. use NET.STA.LOC.CHAN format when possible
# :name	Freeform channel names
# :loc	Location (position) vector; any subtype of InstrumentPosition
# :fs	Sampling frequency in Hz; set to 0.0 for irregularly-sampled data.
# :gain	Scalar gain; divide data by the gain to convert to units
# :resp	Instrument response; any subtype of InstrumentResponse
# :units	String describing data units. UCUM standards are assumed.
# :src	Freeform string describing data source.
# :misc	Dictionary for non-critical information.
# :notes	Timestamped notes; includes automatically-logged acquisition and
# | processing information.
# :t	Matrix of time gaps, formatted [Sample# GapLength]
# | gaps are in μs measured from the Unix epoch
# :x	Data
# [^1]: Not present in SeisChannel objects.
#

using JLD2, SeisIO, Printf, Dates

# import individual function for each conversion
include("sac2jld2.jl")

end # module
