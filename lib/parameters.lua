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

local LEVELS_LFO_DEFAULT_RATE_INDEX = 20

params:add_separator("BITS_LEVELS", "LEVELS")
params:add_binary(ID_LEVELS_LFO_ENABLED, "LFO enabled", "toggle", 0)
params:add_option(ID_LEVELS_LFO_SHAPE, "LFO shape", LEVELS_LFO_SHAPES, 2)
params:add_option(ID_LEVELS_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, LEVELS_LFO_DEFAULT_RATE_INDEX)
params:add_control(ID_LEVELS_POS, "position", controlspec_pos)
params:add_control(ID_LEVELS_AMP, "amp", controlspec_amp)


---
--- SEQUENCER
---
ID_SEQ_PERLIN_X = "sequencer_perlin_x"
ID_SEQ_PERLIN_Y = "sequencer_perlin_y"
ID_SEQ_PERLIN_Z = "sequencer_perlin_z"
ID_SEQ_EVOLVE = "sequencer_evolve"
ID_SEQ_PERLIN_DENSITY = "sequencer_perlin_density"
ID_SEQ_STYLE = "sequencer_style"

SEQ_EVOLVE_TABLE = {"OFF", "SLOW", "MED", "FAST"}
SEQ_STREAM = "STREA"
SEQ_GRID = "MANUA"
SEQ_MOMENTARY = "MOMEN"
SEQ_GATE = "GATE"
SEQUENCE_STYLE_TABLE = {SEQ_GATE, SEQ_GRID}
ID_SEQ_STEP = {}

params:add_separator("SEQUENCER", "SEQUENCER")
params:add_control(ID_SEQ_PERLIN_X, "perlin x", controlspec_perlin)
params:add_control(ID_SEQ_PERLIN_Y, "perlin y", controlspec_perlin_y)
params:hide(ID_SEQ_PERLIN_Y)
params:add_control(ID_SEQ_PERLIN_Z, "perlin z", controlspec_perlin)
params:hide(ID_SEQ_PERLIN_Z)
params:add_control(ID_SEQ_PERLIN_DENSITY, "sequence density", controlspec_perlin_density)
params:add_option(ID_SEQ_EVOLVE, "evolve", SEQ_EVOLVE_TABLE, 1)
params:add_option(ID_SEQ_STYLE, "sequence style", SEQUENCE_STYLE_TABLE, 1)

-- add 96 params for sequence step status
for y = 1, 6 do
    ID_SEQ_STEP[y] = {}
    for x = 1, 16 do
        ID_SEQ_STEP[y][x] = "sequencer_step_" .. y .. "_" .. x
        -- params:add_binary(ID_SEQ_STEP[y][x], ID_SEQ_STEP[y][x], "toggle", 0)
        params:add_number(ID_SEQ_STEP[y][x], ID_SEQ_STEP[y][x], -1, 1,0)
        params:hide(ID_SEQ_STEP[y][x])
    end
end

---
--- PANNING
---
ID_PANNING_LFO_ENABLED = "panning_lfo_enabled"
ID_PANNING_LFO_SHAPE = "panning_lfo_shape"
ID_PANNING_LFO_RATE = "panning_lfo_rate"
ID_PANNING_TWIST = "panning_twist"
ID_PANNING_SPREAD = "panning_spread"
-- todo: add tri?
PANNING_LFO_SHAPES = { "sine", "up", "down", "random" }
DEFAULT_PANNING_LFO_RATE_IDX = 16

params:add_separator("PANNING", "PANNING")
params:add_binary(ID_PANNING_LFO_ENABLED, "LFO enabled", "toggle", 1)
params:add_option(ID_PANNING_LFO_SHAPE, "LFO shape", PANNING_LFO_SHAPES, 2)
params:add_option(ID_PANNING_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, DEFAULT_PANNING_LFO_RATE_IDX)
params:add_control(ID_PANNING_TWIST, "twist", controlspec_pan_twist)
params:add_control(ID_PANNING_SPREAD, "spread", controlspec_pan_spread)

---
--- SAMPLING
---
ID_SAMPLING_AUDIO_FILE = "sampling_audio_file"
ID_SAMPLING_NUM_SLICES = "sampling_num_slices"
ID_SAMPLING_SLICE_START = "sampling_slice_start"
ID_SAMPLING_SLICE_SECTIONS = {}

function get_slice_start_param_id(voice)
    return "sampling_" .. voice .. "_start"
end
function get_slice_end_param_id(voice)
    return "sampling_" .. voice .. "_end"
end

for voice = 1, 6 do
    ID_SAMPLING_SLICE_SECTIONS[voice] = {
        loop_start = get_slice_start_param_id(voice),
        loop_end = get_slice_end_param_id(voice),
    }
end

params:add_separator("SAMPLING", "SAMPLING")
params:add_file(ID_SAMPLING_AUDIO_FILE, 'sample', nil)
params:add_control(ID_SAMPLING_NUM_SLICES, "slices", controlspec_slices)
params:add_control(ID_SAMPLING_SLICE_START, "start", controlspec_start)

for voice = 1, 6 do
    -- ranges per slice
    params:add_number(ID_SAMPLING_SLICE_SECTIONS[voice].loop_start, ID_SAMPLING_SLICE_SECTIONS[voice].loop_start, 0)
    params:add_number(ID_SAMPLING_SLICE_SECTIONS[voice].loop_end, ID_SAMPLING_SLICE_SECTIONS[voice].loop_end, 0)

    params:hide(ID_SAMPLING_SLICE_SECTIONS[voice].loop_start)
    params:hide(ID_SAMPLING_SLICE_SECTIONS[voice].loop_end)
end

