local specs = include("bits/lib/specs")

---
--- GLOBAL
---
params:add_separator("BITS", "BITS")


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
