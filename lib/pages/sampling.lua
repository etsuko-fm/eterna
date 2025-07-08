local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local Waveform = include("bits/lib/graphics/Waveform")
local page_name = "SAMPLING"
local fileselect = require('fileselect')
local page_disabled = false
local debug = include("bits/lib/util/debug")
local misc_util = include("bits/lib/util/misc")

local waveform
local window

local PARAM_ID_AUDIO_FILE = "sampling_audio_file"
local PARAM_ID_NUM_SLICES = "sampling_num_slices"
local PARAM_ID_SLICE_START = "sampling_slice_start"

local SLICE_PARAM_IDS = {}

for i = 1,6 do
    SLICE_PARAM_IDS[i] = {
        loop_start = "sampling_" .. i .. "start",
        loop_end = "sampling_" .. i .. "end",
    }
end

local debug_mode = true

local SLICES_MIN = 1
local SLICES_MAX = 32

local START_MIN = 1
local START_MAX = 32 -- dynamic, todo: deal with that

local controlspec_slices = controlspec.def {
    min = SLICES_MIN, -- the minimum value
    max = SLICES_MAX, -- the maximum value
    warp = 'lin',     -- a shaping option for the raw value
    step = 1,         -- output value quantization
    default = 1,      -- default value
    units = '',       -- displayed on PARAMS UI
    quantum = 1,      -- each delta will change raw value by this much
    wrap = false      -- wrap around on overflow (true) or clamp (false)
}

local controlspec_start = controlspec.def {
    min = START_MIN, -- the minimum value
    max = START_MAX, -- the maximum value
    warp = 'lin',    -- a shaping option for the raw value
    step = 1,        -- output value quantization
    default = 1,     -- default value
    units = '',      -- displayed on PARAMS UI
    quantum = 1,     -- each delta will change raw value by this much
    wrap = false     -- wrap around on overflow (true) or clamp (false)
}


--[[
Sample select page
Graphics:
- Waveform with global loop points
- Instructions for sample loading
- Filename of selected sample

Interactions:
 K2: enter file browser (`fileselect`) - fileselect itself is a norns feature
 E2: select global loop position
 E3: select global loop length
]]


local function as_abs_values(tbl)
    -- used for waveform rendering
    for i = 1, #tbl do
        tbl[i] = math.abs(tbl[i])
    end
    return tbl
end

local function update_waveform(state)
    waveform.sample_length = state.sample_length
    waveform.samples = state.pages.sample.waveform_samples

    if state.pages.sample.waveform_samples[1] then
        -- adjust scale so scale at peak == 1, is norm_scale; lower amp is higher scaling
        local norm_scale = 12
        state.pages.sample.scale_waveform = norm_scale / math.max(table.unpack(state.pages.sample.waveform_samples))
    end
end

local function path_to_file_name(file_path)
    -- strips '/foo/bar/audio.wav' to 'audio.wav'
    local split_at = string.match(file_path, "^.*()/")
    return string.sub(file_path, split_at + 1)
end

local function update_waveforms()
    local w = state.pages.sample.waveform_width -- 59 currently, in px
    -- now need loop start/end per voice
    local s = params:get(SLICE_PARAM_IDS[1].loop_start)
    local e = params:get(SLICE_PARAM_IDS[1].loop_end)
    local idx_low = math.floor((s/state.sample_length) * #state.pages.sample.waveform_samples)
    local idx_hi = math.floor((e/state.sample_length) * #state.pages.sample.waveform_samples)
end

local function update_softcut_ranges()
    local n_slices = params:get(PARAM_ID_NUM_SLICES)
    local start = params:get(PARAM_ID_SLICE_START)

    -- edit buffer ranges per softcut voice
    local slice_start_timestamps = {}
    local slice_length = (1 / n_slices) * state.sample_length

    for i = 1, n_slices do
        -- start at 0
        slice_start_timestamps[i] = (i-1) * slice_length
    end

    for i = 0, 5 do
        local voice = i + 1

        -- start >= 1; table indexing starts at 1;
        --- start + i maps from 1 to 6 when start = 1, 
        --- or 26-32 when start=26.
        --- this works fine for n_slices > 6; else, voices need to recycle slices;
        --- hence the modulo.
        start_pos = slice_start_timestamps[((start - 1 + i) % n_slices) + 1]
        -- loop start/end works as buffer range when loop not enabled
        softcut.loop_start(voice, start_pos)

        -- end point is where the next slice starts
        local end_pos =  start_pos + (slice_length * .6) -- leave a small gap to prevent overlap
        softcut.loop_end(voice, end_pos)

        -- save in params, so waveforms can render correctly
        params:set(SLICE_PARAM_IDS[voice].loop_start, start_pos)
        params:set(SLICE_PARAM_IDS[voice].loop_end, end_pos)
    end

    -- let waveforms represent which section of buffer is active
    update_waveforms()
end
local function load_sample(state, file)
    -- use specified `file` as a sample and store enabled length of softcut buffer in state
    state.sample_length = audio_util.load_sample(file, true)
    state.pages.slice.enabled_section = { 0, state.max_sample_length }
    if state.sample_length < state.max_sample_length then
        state.pages.slice.enabled_section = { 0, state.sample_length }
    end

    softcut.render_buffer(1, 0, state.sample_length, state.pages.sample.waveform_width)
    update_softcut_ranges()
end


local function select_sample(state)
    local function callback(file_path)
        if file_path ~= 'cancel' then
            state.pages.sample.selected_sample = file_path
            load_sample(state, file_path)
        end
        page_disabled = false -- proceed with rendering page instead of file menu
        print('selected ' .. file_path)
    end
    fileselect.enter(_path.audio, callback, "audio")
    page_disabled = true -- don't render current page
end

local function constrain_max_start(num_slices)
    -- starting slice should always be 1 when num slices <= 6;
    -- when num slices > 6, its max is the (number of slices - 6)
    local num_voices = 6
    if num_slices > num_voices then
        controlspec_start.max = num_slices - num_voices
    else
        controlspec_start.max = 1
    end
end

local function shuffle()
    -- randomizes number of slices and slice start
    local new_num_slices = math.random(SLICES_MIN, SLICES_MAX)
    local new_start = 1
    constrain_max_start(new_num_slices)

    if new_num_slices > 6 then
        controlspec_start.max = new_num_slices - 6 -- 6 = num voices
        new_start = math.random(START_MIN, controlspec_start.max)
    else
        controlspec_start.max = 1
    end
    params:set(PARAM_ID_NUM_SLICES, new_num_slices)
    params:set(PARAM_ID_SLICE_START, new_start)
    print("shuffle!", new_num_slices, new_start)
end



local function action_num_slices(v)
    -- update max start based on number of slices
    constrain_max_start(v)
    update_softcut_ranges()
    screen_dirty = true
end

local function action_slice_start(v)
    update_softcut_ranges()
    screen_dirty = true
end

local function adjust_num_slices(state, d)
    local p = PARAM_ID_NUM_SLICES
    params:set(p, params:get(p) + d * controlspec_slices.quantum)
end

local function adjust_slice_start(state, d)
    local p = PARAM_ID_SLICE_START
    params:set(p, params:get(p) + d * controlspec_start.quantum)
end

local page = Page:create({
    name = page_name,
    e2 = adjust_num_slices,
    e3 = adjust_slice_start,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_off = select_sample,
    k3_off = shuffle,
})

function page:render(state)
    if page_disabled then
        fileselect:redraw()
        return
    end -- for rendering the fileselect interface

    update_waveform(state)
    waveform.vertical_scale = state.pages.sample.scale_waveform
    waveform:render()

    -- slices
    page.footer.button_text.e2.value = params:get(PARAM_ID_NUM_SLICES)
    page.footer.button_text.e3.value = params:get(PARAM_ID_SLICE_START)

    -- show filename and sample length
    screen.font_face(state.default_font)
    screen.level(5)
    screen.move(64, 46)
    screen.text_center(misc_util.trim(state.pages.sample.filename, 24))
    window:render()
    page.footer:render()
end

local function add_params(state)
    params:add_separator("SAMPLING", page_name)
    -- file selection
    params:add_file(PARAM_ID_AUDIO_FILE, 'file')
    params:set_action(PARAM_ID_AUDIO_FILE, function(file) load_sample(state, file) end)

    -- number of slices
    params:add_control(PARAM_ID_NUM_SLICES, "slices", controlspec_slices)
    params:set_action(PARAM_ID_NUM_SLICES, action_num_slices)

    -- starting slice
    params:add_control(PARAM_ID_SLICE_START, "start", controlspec_start)
    params:set_action(PARAM_ID_SLICE_START, action_slice_start)

    for i = 1,6 do
        -- ranges per slice
        params:add_number(SLICE_PARAM_IDS[i].loop_start, SLICE_PARAM_IDS[i].loop_start, 0)
        params:add_number(SLICE_PARAM_IDS[i].loop_end, SLICE_PARAM_IDS[i].loop_end, 0)

        params:hide(SLICE_PARAM_IDS[i].loop_start)
        params:hide(SLICE_PARAM_IDS[i].loop_end)
    end
end

function page:initialize(state)
    add_params(state)

    -- init softcut
    local sample1 = "audio/etsuko/sea-minor/sea-minor-chords.wav"
    local sample2 = "audio/etsuko/neon-light/neon intro.wav"
    if debug_mode then load_sample(state, _path.dust .. sample2) end

    local function on_render(ch, start, i, s)
        -- this is a callback, for every softcut.render_buffer() invocation
        state.pages.sample.waveform_samples = as_abs_values(s)
        state.interval = i -- represents the interval at which the waveform is sampled for rendering
        state.pages.sample.filename = path_to_file_name(state.pages.sample.selected_sample)
        update_waveform(state)
        screen_dirty = true
    end

    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "SAMPLING",
        font_face = state.title_font,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })

    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "LOAD",
                value = "",
            },
            k3 = {
                name = "SHUFF",
                value = "",
            },
            e2 = {
                name = "SLICE",
                value = "",
            },
            e3 = {
                name = "START",
                value = "",
            },
        },
        font_face = state.footer_font
    })

    waveform = Waveform:new({
        x = 64,
        y = 25,
        highlight = false,
        sample_length = state.sample_length,
        vertical_scale = state.pages.sample.scale_waveform,
        samples = state.pages.sample.waveform_samples,
    })

    -- setup callback
    softcut.event_render(on_render)
    softcut.render_buffer(1, 0, state.sample_length, state.pages.sample.waveform_width)
end

return page
