local lfo_util = include("bits/lib/util/lfo")

-- Params for levels page
ID_LEVELS_LFO_ENABLED = "levels_lfo_enabled"
ID_LEVELS_LFO_SHAPE = "levels_lfo_shape"
ID_LEVELS_LFO_RATE = "levels_lfo_rate"
ID_LEVELS_POS = "levels_pos"
ID_LEVELS_AMP = "levels_sigma"

-- Sigma - i.e. the Gaussian distribution concept
LEVELS_SIGMA_MIN = 0.3
LEVELS_SIGMA_MAX = 15

-- Amp maps the arbitrary sigma range from 0 to 1
local LEVELS_AMP_MIN = 0
local LEVELS_AMP_MAX = 1

local LEVELS_POSITION_MIN = 0
local LEVELS_POSITION_MAX = 1

LEVELS_LFO_SHAPES = { "sine", "up", "down", "random" }

controlspec_pos = controlspec.def {
    min = LEVELS_POSITION_MIN, -- the minimum value
    max = LEVELS_POSITION_MAX, -- the maximum value
    warp = 'lin',       -- a shaping option for the raw value
    step = 0.01,        -- output value quantization
    default = 0.42,      -- default value
    units = '',         -- displayed on PARAMS UI
    quantum = 0.01,     -- each delta will change raw value by this much
    wrap = true         -- wrap around on overflow (true) or clamp (false)
}

controlspec_amp = controlspec.def {
    min = LEVELS_AMP_MIN, -- the minimum value
    max = LEVELS_AMP_MAX, -- the maximum value
    warp = 'lin',    -- a shaping option for the raw value
    step = 0.01,     -- output value quantization
    default = 0.6,   -- default value
    units = '',      -- displayed on PARAMS UI
    quantum = 0.01,  -- each delta will change raw value by this much
    wrap = false     -- wrap around on overflow (true) or clamp (false)
}

local default_rate_index = 20
local default_rate = lfo_util.lfo_period_values[default_rate_index]

params:add_separator("BITS_LEVELS", "LEVELS")
params:add_binary(ID_LEVELS_LFO_ENABLED, "LFO enabled", "toggle", 0)
params:add_option(ID_LEVELS_LFO_SHAPE, "LFO shape", LEVELS_LFO_SHAPES, 1)
params:add_option(ID_LEVELS_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, default_rate)
params:add_control(ID_LEVELS_POS, "position", controlspec_pos)
params:add_control(ID_LEVELS_AMP, "amp", controlspec_amp)
