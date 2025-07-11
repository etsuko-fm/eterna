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

local LEVELS_LFO_DEFAULT_RATE_INDEX = 20
local LEVELS_LFO_DEFAULT_RATE = lfo_util.lfo_period_values[LEVELS_LFO_DEFAULT_RATE_INDEX]

params:add_separator("BITS_LEVELS", "LEVELS")
params:add_binary(ID_LEVELS_LFO_ENABLED, "LFO enabled", "toggle", 0)
params:add_option(ID_LEVELS_LFO_SHAPE, "LFO shape", LEVELS_LFO_SHAPES, 1)
params:add_option(ID_LEVELS_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, LEVELS_LFO_DEFAULT_RATE_INDEX)
params:add_control(ID_LEVELS_POS, "position", controlspec_pos)
params:add_control(ID_LEVELS_AMP, "amp", controlspec_amp)

ID_PITCH_DIRECTION = "pitch_direction"
ID_PITCH_QUANTIZE = "pitch_quantize"
ID_PITCH_CENTER = "pitch_center"
ID_PITCH_SPREAD = "pitch_spread"

-- voice directions; also used for other pages, hence global
function get_voice_dir_param_id(i)
  return "pitch_v" .. i .. "_dir"
end

PITCH_CENTER_MIN = -2
PITCH_CENTER_MAX = 2
PITCH_CENTER_QUANTUM = 1 / 120
PITCH_CENTER_QUANTUM_QNT = 1.0

PITCH_SPREAD_MIN = -2
PITCH_SPREAD_MAX = 2
PITCH_SPREAD_MIN_QNT = -2
PITCH_SPREAD_MAX_QNT = 2
PITCH_SPREAD_QUANTUM = 0.01
PITCH_SPREAD_QUANTUM_QNT = 0.5

FWD = "FWD"
REV = "REV"
FWD_REV = "FWD+REV"
PLAYBACK_TABLE = { FWD, REV, FWD_REV }

OFF = "OFF"
OCTAVES = "OCTAV"
QUANTIZE_TABLE = { OFF, OCTAVES }
QUANTIZE_DEFAULT = 2 -- octave quantization by default

controlspec_center = controlspec.def {
    min = PITCH_CENTER_MIN,                   -- the minimum value
    max = PITCH_CENTER_MAX,                   -- the maximum value
    warp = 'lin',                       -- a shaping option for the raw value
    step = 1 / 120,                     -- output value quantization
    default = 0.0,                      -- default value
    units = '',                         -- displayed on PARAMS UI
    quantum = PITCH_CENTER_QUANTUM_QNT, -- each delta will change raw value by this much
    wrap = false                        -- wrap around on overflow (true) or clamp (false)
}

controlspec_spread = controlspec.def {
    min = PITCH_SPREAD_MIN_QNT,         -- the minimum value
    max = PITCH_SPREAD_MAX_QNT,         -- the maximum value
    warp = 'lin',                       -- a shaping option for the raw value
    step = 0.01,                        -- output value quantization
    default = 0.0,                      -- default value
    units = '',                         -- displayed on PARAMS UI
    quantum = PITCH_SPREAD_QUANTUM_QNT, -- each delta will change raw value by this much
    wrap = false                        -- wrap around on overflow (true) or clamp (false)
}

params:add_separator("PLAYBACK_RATES", "PLAYBACK RATES")
params:add_option(ID_PITCH_QUANTIZE, 'quantize', QUANTIZE_TABLE, QUANTIZE_DEFAULT)
params:add_control(ID_PITCH_CENTER, "center", controlspec_center)
params:add_control(ID_PITCH_SPREAD, "spread", controlspec_spread)
params:add_option(ID_PITCH_DIRECTION, "direction", PLAYBACK_TABLE, 1)
