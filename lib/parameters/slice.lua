---
--- SLICES
---

SLICES_MIN = 1
SLICES_MAX = 32
SLICES_DEFAULT = 16

controlspec_slices = controlspec.def {
    min = SLICES_MIN,
    max = SLICES_MAX,
    warp = 'lin',
    step = 1,
    default = SLICES_DEFAULT,
    units = '',
    quantum = 1/SLICES_MAX,
    wrap = false
}

local START_MIN = 1
local START_MAX = 32 -- dynamic, todo: deal with that

controlspec_slice_start = controlspec.def {
    min = START_MIN,
    max = START_MAX,
    warp = 'lin',
    step = 1,
    default = 1,
    units = '',
    quantum = 1/START_MAX,
    wrap = true
}

ID_SLICES_AUDIO_FILE = "slices_audio_file"
ID_SLICES_NUM_SLICES = "slices_num_slices"
ID_SLICES_START = "slices_slice_start"
ID_SLICES_LFO = "slices_lfo"
SLICES_LFO_SHAPES = { "off", "up", "down", "random" }

ID_SLICES_SECTIONS = {}

function get_slice_start_param_id(voice)
    return "slices_" .. voice .. "_start"
end

function get_slice_end_param_id(voice)
    return "slices_" .. voice .. "_end"
end

for voice = 1, 6 do
    ID_SLICES_SECTIONS[voice] = {
        loop_start = get_slice_start_param_id(voice),
        loop_end = get_slice_end_param_id(voice),
    }
end

params:add_separator("SAMPLE_SLICES", "SAMPLE SLICES")
params:add_file(ID_SLICES_AUDIO_FILE, 'sample', nil)
params:add_option(ID_SLICES_LFO, "lfo", SLICES_LFO_SHAPES)
params:add_control(ID_SLICES_NUM_SLICES, "slices", controlspec_slices)
params:add_control(ID_SLICES_START, "start", controlspec_slice_start)

for voice = 1, 6 do
    -- ranges per slice
    params:add_number(ID_SLICES_SECTIONS[voice].loop_start, ID_SLICES_SECTIONS[voice].loop_start, 0)
    params:add_number(ID_SLICES_SECTIONS[voice].loop_end, ID_SLICES_SECTIONS[voice].loop_end, 0)
    params:hide(ID_SLICES_SECTIONS[voice].loop_start)
    params:hide(ID_SLICES_SECTIONS[voice].loop_end)
end
