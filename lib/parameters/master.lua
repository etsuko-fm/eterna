-- in dB
local MASTER_DRIVE_MIN = -12
local MASTER_DRIVE_MAX = 18

MASTER_OUT_MIN = -40
local MASTER_OUT_MAX = 6

ID_MASTER_MONO_FREQ = "master_mono_freq"
ID_MASTER_COMP_DRIVE = "master_comp_drive"
ID_MASTER_COMP_AMOUNT = "master_comp_amount"
ID_MASTER_OUTPUT = "master_output"

BASS_MONO_FREQS_STR = {"OFF", "50Hz", "100Hz", "200Hz", "FULL"}
BASS_MONO_FREQS_INT = {20, 50, 100, 200, 20000}

COMP_AMOUNTS = {"OFF", "SOFT", "MEDIUM", "HARD"}

controlspec_master_drive = controlspec.def {
    min = MASTER_DRIVE_MIN,
    max = MASTER_DRIVE_MAX,
    warp = 'lin',
    step = 0.01,
    default = 0,
    units = 'dB',
    quantum = 0.1 / (MASTER_DRIVE_MAX - MASTER_DRIVE_MIN),
    wrap = false
}

controlspec_master_output = controlspec.def {
    min = MASTER_OUT_MIN,
    max = MASTER_OUT_MAX,
    warp = 'lin',
    step = 0.1,
    default = 1,
    units = '',
    quantum = 0.2 / (MASTER_OUT_MAX - MASTER_OUT_MIN),
    wrap = false
}

params:add_separator("MASTER", "MASTER")
params:add_option(ID_MASTER_MONO_FREQ, "bass mono freq", BASS_MONO_FREQS_STR, 2)
params:add_control(ID_MASTER_COMP_DRIVE, "compressor drive", controlspec_master_drive)
params:add_option(ID_MASTER_COMP_AMOUNT, "compressor amount", COMP_AMOUNTS, 2)
params:add_control(ID_MASTER_OUTPUT, "output", controlspec_master_output)
params:set_raw(ID_MASTER_OUTPUT, 1.0) -- default to unity gain
