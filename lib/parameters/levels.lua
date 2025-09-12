---
--- LEVELS
---

-- Sigma (σ in normal distribution)
LEVELS_SIGMA_MIN = 0.3
LEVELS_SIGMA_MAX = 15
LEVELS_LFO_SHAPES = { "sine", "up", "down", "random" }

local LEVELS_POSITION_MIN = 0
local LEVELS_POSITION_MAX = 1

controlspec_pos = controlspec.def {
    min = LEVELS_POSITION_MIN,
    max = LEVELS_POSITION_MAX,
    warp = 'lin',
    step = 1/180,
    default = 0.42,
    units = '',
    quantum = 1/180,
    wrap = true
}

-- Amp maps the arbitrary sigma range from 0 to 1
local LEVELS_AMP_MIN = 0
local LEVELS_AMP_MAX = 1

controlspec_amp = controlspec.def {
    min = LEVELS_AMP_MIN,
    max = LEVELS_AMP_MAX,
    warp = 'lin',
    step = 0.01,
    default = 0.45,
    units = '',
    quantum = 0.01,
    wrap = false
}

ID_LEVELS_LFO_ENABLED = "levels_lfo_enabled"
ID_LEVELS_LFO_SHAPE = "levels_lfo_shape"
ID_LEVELS_LFO_RATE = "levels_lfo_rate"
ID_LEVELS_POS = "levels_pos"
ID_LEVELS_AMP = "levels_sigma"

local LEVELS_LFO_DEFAULT_RATE_INDEX = 20

params:add_separator("BITS_LEVELS", "LEVELS")
params:add_binary(ID_LEVELS_LFO_ENABLED, "LFO enabled", "toggle", 1)
params:add_option(ID_LEVELS_LFO_SHAPE, "LFO shape", LEVELS_LFO_SHAPES, 2)
params:add_option(ID_LEVELS_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, LEVELS_LFO_DEFAULT_RATE_INDEX)
params:add_control(ID_LEVELS_POS, "position", controlspec_pos)
params:add_control(ID_LEVELS_AMP, "amp", controlspec_amp)
