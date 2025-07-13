local lfo_util = include("bits/lib/util/lfo")
local specs = include("bits/lib/specs")

---
--- GLOBAL
---
params:add_separator("BITS", "BITS")

---
--- LEVELS
---
ID_LEVELS_LFO_ENABLED = "levels_lfo_enabled"
ID_LEVELS_LFO_SHAPE = "levels_lfo_shape"
ID_LEVELS_LFO_RATE = "levels_lfo_rate"
ID_LEVELS_POS = "levels_pos"
ID_LEVELS_AMP = "levels_sigma"

params:add_separator("BITS_LEVELS", "LEVELS")
params:add_binary(ID_LEVELS_LFO_ENABLED, "LFO enabled", "toggle", 0)
params:add_option(ID_LEVELS_LFO_SHAPE, "LFO shape", LEVELS_LFO_SHAPES, 1)
params:add_option(ID_LEVELS_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, LEVELS_LFO_DEFAULT_RATE_INDEX)
params:add_control(ID_LEVELS_POS, "position", controlspec_pos)
params:add_control(ID_LEVELS_AMP, "amp", controlspec_amp)

---
--- PLAYBACK RATES
---
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


params:add_separator("PLAYBACK_RATES", "PLAYBACK RATES")
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

---
--- SEQUENCER
---
ID_SEQ_PERLIN_X = "sequencer_perlin_x"
ID_SEQ_PERLIN_Y = "sequencer_perlin_y"
ID_SEQ_PERLIN_Z = "sequencer_perlin_z"
ID_SEQ_EVOLVE = "sequencer_evolve"
ID_SEQ_PERLIN_DENSITY = "sequencer_perlin_density"
ID_SEQ_PB_STYLE = "sequencer_momentary"

SEQ_EVOLVE_TABLE = {"OFF", "SLOW", "MED", "FAST"}
LOOP_TABLE = {"STREA", "MOMEN"}
SEQ_PARAM_IDS = {}

params:add_separator("SEQUENCER", "SEQUENCER")
params:add_control(ID_SEQ_PERLIN_X, "perlin x", controlspec_perlin)
params:add_control(ID_SEQ_PERLIN_Y, "perlin y", controlspec_perlin)
params:add_control(ID_SEQ_PERLIN_Z, "perlin z", controlspec_perlin)
params:add_control(ID_SEQ_PERLIN_DENSITY, "sequence density", controlspec_perlin_density)
params:add_option(ID_SEQ_EVOLVE, "evolve", SEQ_EVOLVE_TABLE, 1)
params:add_option(ID_SEQ_PB_STYLE, "playback style", LOOP_TABLE, 1)

-- add 96 params for sequence step status
for y = 1, 6 do
    SEQ_PARAM_IDS[y] = {}
    for x = 1, 16 do
        SEQ_PARAM_IDS[y][x] = "sequencer_step_" .. y .. "_" .. x
        -- params:add_binary(SEQ_PARAM_IDS[y][x], SEQ_PARAM_IDS[y][x], "toggle", 0)
        params:add_number(SEQ_PARAM_IDS[y][x], SEQ_PARAM_IDS[y][x], -1, 1,0)
        params:hide(SEQ_PARAM_IDS[y][x])
    end
end

params:bang()