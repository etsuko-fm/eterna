---
--- FILTER params
---

local page_id = "filter_"
ID_FILTER_FREQ = page_id.."freq"
ID_FILTER_RES = page_id.."res"
ID_FILTER_DRIVE = page_id.."drive"
ID_FILTER_TYPE = page_id.."type"
ID_FILTER_LFO_ENABLED = page_id.."lfo_enabled"
ID_FILTER_LFO_SHAPE = page_id.."lfo_shape"
ID_FILTER_LFO_RATE = page_id.."lfo_rate"
FILTER_LFO_SHAPES = { "sine", "up", "down", "random" }
FILTER_TYPES = { "HP", "LP", "SWIRL", "NONE" }
local FILTER_DRIVE_MIN = 0.5
local FILTER_DRIVE_MAX = 5.0
local FILTER_FREQ_MIN = 25
local FILTER_FREQ_MAX = 20000
local FILTER_RES_MIN = 0.0
local FILTER_RES_MAX = 0.98

controlspec_filter_freq = controlspec.def {
    min = FILTER_FREQ_MIN,
    max = FILTER_FREQ_MAX,
    warp = 'lin',
    step = 1.0,
    default = 25.0,
    units = '',
    quantum = 1/(FILTER_FREQ_MAX-FILTER_FREQ_MIN),
    wrap = false
}

controlspec_filter_res = controlspec.def {
    min = FILTER_RES_MIN,
    max = FILTER_RES_MAX,
    warp = 'lin',
    step = 0.01,
    default = 0.2,
    units = '',
    quantum = 0.01,
    wrap = false
}

controlspec_filter_drive = controlspec.def {
    min = FILTER_DRIVE_MIN,
    max = FILTER_DRIVE_MAX,
    warp = 'lin',
    step = 0.01,
    default = 1.0,
    units = '',
    quantum = 0.1/(FILTER_DRIVE_MAX-FILTER_DRIVE_MIN),
    wrap = false
}

params:add_separator("FILTER", "FILTER")
params:add_binary(ID_FILTER_LFO_ENABLED, "LFO enabled", "toggle", 0)
params:add_option(ID_FILTER_LFO_SHAPE, "LFO shape", FILTER_LFO_SHAPES, 1)
params:add_option(ID_FILTER_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, 8)
params:add_option(ID_FILTER_TYPE, "filter type", FILTER_TYPES, 1)
params:add_control(ID_FILTER_FREQ, "frequency", controlspec_filter_freq)
params:add_control(ID_FILTER_RES, "resonance", controlspec_filter_res)
params:add_control(ID_FILTER_DRIVE, "drive", controlspec_filter_drive)
