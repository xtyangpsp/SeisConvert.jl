__precompile__()
module SeisConvert
#This module contains a series of functions to convert seismic data
#between different formats.
# By Xiaotao Yang
#
###############################################################
"""
Data format for: SeisData, SeisChannel, SeisEvent.data
Field	Description
:n	Number of channels [^1]
:c	TCP connections feeding data to this object [^1]
:id	Channel ids. use NET.STA.LOC.CHAN format when possible
:name	Freeform channel names
:loc	Location (position) vector; any subtype of InstrumentPosition
:fs	Sampling frequency in Hz; set to 0.0 for irregularly-sampled data.
:gain	Scalar gain; divide data by the gain to convert to units
:resp	Instrument response; any subtype of InstrumentResponse
:units	String describing data units. UCUM standards are assumed.
:src	Freeform string describing data source.
:misc	Dictionary for non-critical information.
:notes	Timestamped notes; includes automatically-logged acquisition and
| processing information.
:t	Matrix of time gaps, formatted [Sample# GapLength]
| gaps are in μs measured from the Unix epoch
:x	Data
[^1]: Not present in SeisChannel objects.
"""
###############################################################
# JLD2 file format for RAW waveform data:
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
# JLD2 file format for seismic cross-correlation data, saved in CorrData type (defined by SeisNoise package):
# The CorrData is saved under each timestamp group. CorrData may include multiple correlation data may include
# multiple segments of data, e.g., multiple hourly stacks. These stacks share the same metadata for the same
# station pair.
# The following is from SeisNoise.
#
"""
   CorrData
A structure for cross-correlations of ambient noise data.
## Fields: CorrData
| **Field** | **Description** |
|:------------|:-------------|
| :name       | Freeform channel names |
| :id         | Channel ids. use NET.STA.LOC.CHAN format when possible. |
| :loc        | Location (position) object. |
| :comp       | 1st channel, 2nd channel [ZZ,RT,..]
| :rotated    | Rotation applied: true or false
| :corr_type  | Could be: "corr", "deconv", "coh"
| :fs         | Sampling frequency in Hz. |
| :gain       | Scalar gain; divide data by the gain to convert to units  |
| :freqmin    | Minimum frequency for whitening.  |
| :freqmax    | Maximum frequency for whitening. |
| :cc_len     | Length of each correlation in seconds. |
| :cc_step    | Spacing between correlation windows in seconds. |
| :whitened   | Whitening applied.
| :time_norm  | Apply one-bit whitening with "one_bit". |
| :resp       | Instrument response object, format [zeros poles] |
| :misc       | Dictionary for non-critical information. |
| :notes      | Timestamped notes; includes automatically-logged acquisition and |
|             | processing information. |
| :maxlag     | Maximum lag time in seconds to keep from correlations. |
| :t          | Starttime of each correlation. |
| :corr       | Correlations stored in columns. |
"""
###############################################################
# SAC data format:
# Follows the standard SAC format.
#

using SeisIO

# import individual function for each conversion
include("utilities.jl")
include("sac2jld2.jl")
include("segy2jld2.jl")
include("seisconvert_parallel.jl")
include("jld22sac.jl")  #converting jld2 format to sac
include("corr2seis.jl")

end # module
