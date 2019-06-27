__precompile__()
module SeisConvert
#This module contains a series of functions to convert seismic data
#between different formats.
# By Xiaotao Yang
#
###############################################################
# Data format for: SeisData, SeisChannel, SeisEvent.data
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
###############################################################
# JLD2 file format:
# The JLD2 data includes the following metadata (based on the format defined in SeisDownload):
# info/DLtimestamplist: this saves the tiem stamps as indices of each time group
# info/stationlist: this is the list of stations in each time group, defined by the timestamplist
# info/starttime: starttime of the group, can be the minimum start time for multiple data segments.
# info/endtime: endtime of the group, can be the maximum end time for multiple data segments.
# info/DL_time_unit: length of the data in time (duration), not number of samples
# SeisData under each timestamp group, the data file (attribute) is named by the stationname in stationlist.
#           Usually in the format of NET.STA.LOC.CHAN
#
###############################################################
# SAC data format:
# Follows the standard SAC format.
#

using SeisIO

# import individual function for each conversion
include("utilities.jl")
include("sac2jld2.jl")

end # module
