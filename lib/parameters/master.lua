local MASTER_DRIVE_MIN = 0.1
local MASTER_DRIVE_MAX = 20
local MASTER_RATIO_MIN = 1
local MASTER_RATIO_MAX = 8


ID_MASTER_MONO_FREQ = "master_mono_freq"
ID_MASTER_COMP_RATIO = "master_comp_ratio"
ID_MASTER_COMP_DRIVE = "master_comp_drive"
ID_MASTER_OUTPUT = "master_output"

BASS_MONO_FREQS = {"OFF", "50Hz", "100Hz", "200Hz"}

controlspec_master_drive = controlspec.def {
    min = MASTER_DRIVE_MIN,
    max = MASTER_DRIVE_MAX,
    warp = 'lin',
    step = 0.01,
    default = 1,
    units = '',
    quantum = 0.1 / (MASTER_DRIVE_MAX - MASTER_DRIVE_MIN),
    wrap = false
}

controlspec_master_ratio = controlspec.def {
    min = MASTER_RATIO_MIN,
    max = MASTER_RATIO_MAX,
    warp = 'lin',
    step = 0.01,
    default = 1,
    units = '',
    quantum = 0.1 / (MASTER_RATIO_MAX - MASTER_RATIO_MIN),
    wrap = false
}

controlspec_master_output = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = 0.01,
    default = 1,
    units = '',
    quantum = 0.01,
    wrap = false
}

params:add_separator("MASTER", "MASTER")
params:add_control(ID_MASTER_COMP_DRIVE, "compressor drive", controlspec_master_drive)
params:add_option(ID_MASTER_MONO_FREQ, "bass mono freq", BASS_MONO_FREQS, 2)
params:add_control(ID_MASTER_OUTPUT, "output", controlspec_master_output)