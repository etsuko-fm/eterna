local MASTER_MONO_FREQ_MIN = 10
local MASTER_MONO_FREQ_MAX = 1000
local MASTER_DRIVE_MIN = 0.2
local MASTER_DRIVE_MAX = 10


ID_MASTER_MONO_FREQ = "master_mono_freq"
ID_MASTER_COMP_DRIVE = "master_comp_drive"

controlspec_master_mono = controlspec.def {
    min = MASTER_MONO_FREQ_MIN,
    max = MASTER_MONO_FREQ_MAX,
    warp = 'exp',
    step = 0.1,
    default = MASTER_MONO_FREQ_MIN,
    units = '',
    quantum = 0.005,
    wrap = false
}

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

params:add_separator("MASTER", "MASTER")
params:add_control(ID_MASTER_MONO_FREQ, "bass mono freq", controlspec_master_mono)
params:add_control(ID_MASTER_COMP_DRIVE, "compressor drive", controlspec_master_drive)
