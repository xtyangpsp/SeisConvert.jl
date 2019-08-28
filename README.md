# SeisConvert.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://xtyangpsp.github.io/SeisConvert.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://xtyangpsp.github.io/SeisConvert.jl/dev)
[![Build Status](https://travis-ci.com/xtyangpsp/SeisConvert.jl.svg?branch=master)](https://travis-ci.com/xtyangpsp/SeisConvert.jl)
[![Codecov](https://codecov.io/gh/xtyangpsp/SeisConvert.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/xtyangpsp/SeisConvert.jl)

**A tool box to convert seismic data between different formats**

## Major tools
1. `sac2jld2`: converts SAC files to JLD2 file, structured as timestamp -> SeisData
2. `segy2jld2`: converts PASSCAL SEGY files to JLD2 file, organized as timestamp -> SeisData
3. `jld22sac`: converts JLD2 file, with option of handling multiple structures, to SAC files
4. `corr2seis`: converts CorrData type data to SeisData type, with rich header information stored in `misc` field

## Installation

From the Julia command prompt:

1. Press ] to enter pkg.
2. Type or copy: `add https://github.com/xtyangpsp/SeisConvert.jl`
3. In package model: `build; precompile`
4. Press backspace to exit pkg.
5. Type or copy: `using SeisConvert`

## Example
See examples of using each tool in Examples directory.
1. cd to the individual example directory, e.g., sac2jld2
2. run in terminal: `julia exec.jl`
