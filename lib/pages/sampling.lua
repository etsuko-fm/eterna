local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local Waveform = include("bits/lib/graphics/Waveform")
local misc_util = include("bits/lib/util/misc")
local SliceGraphic = include("bits/lib/graphics/SliceGraphic")

local page_name = "SAMPLING"
local fileselect = require('fileselect')
local page_disabled = false

local waveform_graphic
local waveform_samples
local window
local waveform_width = 63
local waveform_h = 10

local filename = ""
local selected_sample = "audio/etsuko/neon-light/neon intro.wav"
local sample_length

local PARAM_ID_AUDIO_FILE = "sampling_audio_file"
local PARAM_ID_NUM_SLICES = "sampling_num_slices"
local PARAM_ID_SLICE_START = "sampling_slice_start"

local SLICE_PARAM_IDS = {}

-- slice locations; also used for other pages, hence global
function get_slice_start_param_id(voice)
    return "sampling_" .. voice .. "_start"
end

function get_slice_end_param_id(voice)
    return "sampling_" .. voice .. "_end"
end

for voice = 1, 6 do
    SLICE_PARAM_IDS[voice] = {
        loop_start = get_slice_start_param_id(voice),
        loop_end = get_slice_end_param_id(voice),
    }
end

local debug_mode = true

local SLICES_MIN = 1
local SLICES_MAX = 32
local SLICES_DEFAULT = 6

local START_MIN = 1
local START_MAX = 32 -- dynamic, todo: deal with that

local controlspec_slices = controlspec.def {
    min = SLICES_MIN, -- the minimum value
    max = SLICES_MAX, -- the maximum value
    warp = 'lin',     -- a shaping option for the raw value
    step = 1,         -- output value quantization
    default = SLICES_DEFAULT,      -- default value
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

local function path_to_file_name(file_path)
    -- strips '/foo/bar/audio.wav' to 'audio.wav'
    local split_at = string.match(file_path, "^.*()/")
    return string.sub(file_path, split_at + 1)
end

function table.slice(tbl, first, last)
    local result = {}
    for i = first, last do
        result[#result + 1] = tbl[i]
    end
    return result
end

local function update_waveform()
    local scale_waveform = 1
    if waveform_samples[1] then
        -- adjust scale so scale at peak == 1, is waveform_h; lower amp is higher scaling
        scale_waveform = waveform_h / math.max(table.unpack(waveform_samples))
    end

    waveform_graphic.samples = waveform_samples
    waveform_graphic.vertical_scale = scale_waveform
end

local function get_slice_length()
    -- returns slice length in seconds
    local n_slices = params:get(PARAM_ID_NUM_SLICES)
    return (1 / n_slices) * sample_length
end

local function remove_extension(filename)
    return filename:match("^(.*)%.[^%.]+$") or filename
end

local function to_sample_name(path)
    return misc_util.trim(string.upper(remove_extension(path_to_file_name(path))), 28)
end

local function update_slice_graphic()
    local num_slices = params:get(PARAM_ID_NUM_SLICES)
    local slice_start = params:get(PARAM_ID_SLICE_START)
    local slice_len = 1 / num_slices

    slice_graphic.num_slices = num_slices
    slice_graphic.slice_start = slice_start
    slice_graphic.slice_len = slice_len
end

local function update_softcut_ranges()
    local n_slices = params:get(PARAM_ID_NUM_SLICES)
    local start = params:get(PARAM_ID_SLICE_START)

    -- edit buffer ranges per softcut voice
    local slice_start_timestamps = {}
    local slice_length = get_slice_length()

    for i = 1, n_slices do
        -- start at 0
        slice_start_timestamps[i] = (i - 1) * slice_length
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
        local end_pos = start_pos + (slice_length * .999)  -- leave a small gap to prevent overlap
        softcut.loop_end(voice, end_pos)

        -- save in params, so waveforms can render correctly
        params:set(SLICE_PARAM_IDS[voice].loop_start, start_pos)
        params:set(SLICE_PARAM_IDS[voice].loop_end, end_pos)
        voice_position_to_start(voice) --todo: fix, order of initalization bug
    end
    -- reflect changes in graphic
    update_slice_graphic()
end

local function load_sample(state, file)
    -- use specified `file` as a sample and store enabled length of softcut buffer in state
    sample_length = audio_util.load_sample(file, true)
    softcut.render_buffer(1, 0, sample_length, waveform_width)
    update_softcut_ranges()
end

local function select_sample()
    local function callback(file_path)
        if file_path ~= 'cancel' then
            filename = to_sample_name(file_path)
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
        controlspec_start.maxval = 1 + num_slices - num_voices
    else
        controlspec_start.maxval = 1
    end
end

local function shuffle()
    -- randomizes number of slices and slice start
    local new_num_slices = math.random(SLICES_MIN, SLICES_MAX)
    local new_start = math.random(1, math.max(1, new_num_slices - 6))
    params:set(PARAM_ID_NUM_SLICES, new_num_slices)
    params:set(PARAM_ID_SLICE_START, new_start)
end


local function action_num_slices(v)
    -- update max start based on number of slices
    constrain_max_start(v)
    update_softcut_ranges()
end

local function action_slice_start(v)
    update_softcut_ranges()
end

local function adjust_num_slices(d)
    local p = PARAM_ID_NUM_SLICES
    params:set(p, params:get(p) + d * controlspec_slices.quantum)
end

local function adjust_slice_start(d)
    local p = PARAM_ID_SLICE_START
    local new = params:get(p) + d * controlspec_start.quantum
    params:set(p, new)
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

function page:render()
    if page_disabled then
        fileselect:redraw()
        return
    end -- for rendering the fileselect interface

    waveform_graphic:render()
    slice_graphic:render()

    page.footer.button_text.e2.value = params:get(PARAM_ID_NUM_SLICES)
    page.footer.button_text.e3.value = params:get(PARAM_ID_SLICE_START)

    window.title = filename

    window:render()
    page.footer:render()
end

local function add_params()
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
    constrain_max_start(SLICES_DEFAULT)

    for i = 1, 6 do
        -- ranges per slice
        params:add_number(SLICE_PARAM_IDS[i].loop_start, SLICE_PARAM_IDS[i].loop_start, 0)
        params:add_number(SLICE_PARAM_IDS[i].loop_end, SLICE_PARAM_IDS[i].loop_end, 0)

        params:hide(SLICE_PARAM_IDS[i].loop_start)
        params:hide(SLICE_PARAM_IDS[i].loop_end)
    end
end

function page:initialize()
    add_params()

    filename = to_sample_name(selected_sample)

    -- add waveform
    waveform_graphic = Waveform:new({
        x = 33,
        y = 28,
        highlight = false,
        sample_length = sample_length,
        vertical_scale = 1,
        samples = {},
        render_samples = waveform_width,
    })

    slice_graphic = SliceGraphic:new()
    -- init softcut
    if debug_mode then load_sample(state, _path.dust .. selected_sample) end

    local function on_render(ch, start, i, s)
        -- this is a callback, for every softcut.render_buffer() invocation
        waveform_samples = as_abs_values(s)
        state.interval = i -- represents the interval at which the waveform is sampled for rendering
        update_waveform()
    end

    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "SAMPLING",
        font_face = TITLE_FONT,
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
                name = "SLCS",
                value = "",
            },
            e3 = {
                name = "START",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })

    -- setup callback
    softcut.event_render(on_render)
    softcut.render_buffer(1, 0, sample_length, waveform_width)
end

return page
