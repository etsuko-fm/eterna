local lfo_util = include("bits/lib/util/lfo")
local specs = include("bits/lib/specs")

-- Params for LEVELS
ID_LEVELS_LFO_ENABLED = "levels_lfo_enabled"
ID_LEVELS_LFO_SHAPE = "levels_lfo_shape"
ID_LEVELS_LFO_RATE = "levels_lfo_rate"
ID_LEVELS_POS = "levels_pos"
ID_LEVELS_AMP = "levels_sigma"

-- Params for PITCH
ID_PITCH_DIRECTION = "pitch_direction"
ID_PITCH_QUANTIZE = "pitch_quantize"
ID_PITCH_CENTER = "pitch_center"
ID_PITCH_SPREAD = "pitch_spread"

FWD = "FWD"
REV = "REV"
FWD_REV = "BI"
PLAYBACK_TABLE = { FWD, REV, FWD_REV }

OFF = "OFF"
OCTAVES = "OCTAV"
QUANTIZE_TABLE = { OFF, OCTAVES }
QUANTIZE_DEFAULT = 2 -- octave quantization by default

-- voice directions; also used for other pages, hence global
function get_voice_dir_param_id(i)
  return "pitch_v" .. i .. "_dir"
end

local LEVELS_LFO_DEFAULT_RATE_INDEX = 20
local LEVELS_LFO_DEFAULT_RATE = lfo_util.lfo_period_values[LEVELS_LFO_DEFAULT_RATE_INDEX]

params:add_separator("BITS_LEVELS", "LEVELS")
params:add_binary(ID_LEVELS_LFO_ENABLED, "LFO enabled", "toggle", 0)
params:add_option(ID_LEVELS_LFO_SHAPE, "LFO shape", LEVELS_LFO_SHAPES, 1)
params:add_option(ID_LEVELS_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, LEVELS_LFO_DEFAULT_RATE_INDEX)
params:add_control(ID_LEVELS_POS, "position", controlspec_pos)
params:add_control(ID_LEVELS_AMP, "amp", controlspec_amp)

params:add_separator("PITCH", "PITCH")
params:add_option(ID_PITCH_QUANTIZE, 'quantize', QUANTIZE_TABLE, QUANTIZE_DEFAULT)
params:add_control(ID_PITCH_CENTER, "center", controlspec_center)
params:add_control(ID_PITCH_SPREAD, "spread", controlspec_spread)
params:add_option(ID_PITCH_DIRECTION, "direction", PLAYBACK_TABLE, 1)

-- voice directions (fwd/rev/both)
for voice = 1, 6 do
    local param_id = get_voice_dir_param_id(voice)
    params:add_option(param_id, param_id, PLAYBACK_TABLE, 1)
    params:hide(param_id)
end
