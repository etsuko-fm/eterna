---
--- SAMPLING
---

SLICES_MIN = 1
SLICES_MAX = 32
SLICES_DEFAULT = 6

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

controlspec_start = controlspec.def {
    min = START_MIN,
    max = START_MAX,
    warp = 'lin',
    step = 1,
    default = 1,
    units = '',
    quantum = 1/START_MAX,
    wrap = true
}

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
