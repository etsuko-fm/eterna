local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local Waveform = include("bits/lib/graphics/Waveform")
local misc_util = include("bits/lib/util/misc")
local SliceGraphic = include("bits/lib/graphics/SliceGraphic")

local page_name = "SAMPLING"
local fileselect = require('fileselect')
local page_disabled = false

local waveform_graphics = {}
local waveform_samples = {}
local window
local waveform_width = 63
local waveform_h = 6
local is_stereo

local filename = ""
selected_sample = "audio/etsuko/chris/play-safe.wav"
local sample_length

local slice_lfo
local debug_mode = true

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

local function update_waveform(ch)
    local scale_waveform = 1
    if waveform_samples[ch][1] then
        -- adjust scale so scale at peak == 1, is waveform_h; lower amp is higher scaling
        scale_waveform = waveform_h / math.max(table.unpack(waveform_samples[ch]))
    end

    waveform_graphics[ch].samples = waveform_samples[ch]
    waveform_graphics[ch].vertical_scale = scale_waveform
end

local function get_slice_length()
    -- returns slice length in seconds
    local n_slices = params:get(ID_SAMPLING_NUM_SLICES)
    if n_slices and sample_length then
        return (1 / n_slices) * sample_length
    else
        return nil
    end
end

local function remove_extension(filename)
    return filename:match("^(.*)%.[^%.]+$") or filename
end

local function to_sample_name(path)
    local s = string.upper(remove_extension(path_to_file_name(path)))
    return util.trim_string_to_width(s, 108)
end

local function update_slice_graphic()
    local num_slices = params:get(ID_SAMPLING_NUM_SLICES)
    local slice_start = params:get(ID_SAMPLING_SLICE_START)
    local slice_len = 1 / num_slices

    slice_graphic.num_slices = num_slices
    slice_graphic.slice_start = slice_start
    slice_graphic.slice_len = slice_len
end

local function update_softcut_ranges()
    local n_slices = params:get(ID_SAMPLING_NUM_SLICES)
    local start = params:get(ID_SAMPLING_SLICE_START)

    -- edit buffer ranges per softcut voice
    local slice_start_timestamps = {}
    local slice_length = get_slice_length()
    if not slice_length then return end

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
        local start_pos = slice_start_timestamps[((start - 1 + i) % n_slices) + 1]
        -- loop start/end works as buffer range when loop not enabled
        softcut.loop_start(voice, start_pos)

        -- end point is where the next slice starts
        local end_pos = start_pos + (slice_length * .999)  -- leave a small gap to prevent overlap
        softcut.loop_end(voice, end_pos)

        -- save in params, so waveforms can render correctly
        params:set(SLICE_PARAM_IDS[voice].loop_start, start_pos)
        params:set(SLICE_PARAM_IDS[voice].loop_end, end_pos)
        -- voice_position_to_start(voice) --todo: fix, order of initalization bug
    end
    -- reflect changes in graphic
    update_slice_graphic()
end

local function load_sample(file)
    -- use specified `file` as a sample and store enabled length of softcut buffer in state
    print("file: ", file)
    if not file or file == "-" then return end
    sample_length, is_stereo = audio_util.load_sample(file, false)
    selected_sample = file
    softcut.render_buffer(1, 0, sample_length, waveform_width)
    if is_stereo then
        softcut.render_buffer(2, 0, sample_length, waveform_width)
    end
    if is_stereo then
        waveform_h = 5
        waveform_graphics[1].y = 20
        for voice = 1,3 do
            softcut.buffer(voice, 1)
        end
        for voice = 4,6 do
            softcut.buffer(voice, 2)
        end
    else
        waveform_h = 10
        waveform_graphics[1].y = 26
        for voice=1,6 do
            softcut.buffer(voice, 1)
        end
    end
    update_softcut_ranges()
end

local function select_sample()
    local function callback(file_path)
        if file_path ~= 'cancel' then
            filename = to_sample_name(file_path)
            load_sample(file_path)
            for voice = 1,6 do
                softcut.play(voice, 1)
            end
        end
        page_disabled = false -- proceed with rendering page instead of file menu
        page_indicator_disabled = false
    end
    fileselect.enter(_path.audio, callback, "audio")
    page_disabled = true -- don't render current page
    page_indicator_disabled = true -- hide page indicator
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
    if selected_sample then 
        local new_num_slices = math.random(SLICES_MIN, SLICES_MAX)
        local new_start = math.random(1, math.max(1, new_num_slices - 6))
        params:set(ID_SAMPLING_NUM_SLICES, new_num_slices)
        params:set(ID_SAMPLING_SLICE_START, new_start)
    end
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
    if selected_sample then
        local p = ID_SAMPLING_NUM_SLICES
        params:set(p, params:get(p) + d * controlspec_slices.quantum)    
    end
end

local function adjust_slice_start(d)
    if selected_sample then
        local p = ID_SAMPLING_SLICE_START
        local new = params:get(p) + d * controlspec_start.quantum
        params:set(p, new)
    end
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

    if selected_sample then
        window.title = filename
        waveform_graphics[1]:render()
        if is_stereo then
            waveform_graphics[2]:render()
        end
        slice_graphic:render()
        page.footer.button_text.e2.value = params:get(ID_SAMPLING_NUM_SLICES)
        page.footer.button_text.e3.value = params:get(ID_SAMPLING_SLICE_START)
    else
        screen.level(3)
        screen.font_face(DEFAULT_FONT)
        window.title = "SAMPLING"
        screen.move(64,32)
        screen.text_center("PRESS K2 TO LOAD SAMPLE")
    end

    window:render()
    page.footer:render()
end

local function add_params()
    -- file selection
    params:set_action(ID_SAMPLING_AUDIO_FILE, function(file) load_sample(file) end)

    -- number of slices
    params:set_action(ID_SAMPLING_NUM_SLICES, action_num_slices)

    -- starting slice
    params:set_action(ID_SAMPLING_SLICE_START, action_slice_start)
    constrain_max_start(SLICES_DEFAULT)
    params:bang()
end

function page:initialize()
    add_params()

    -- engine.load_file("/home/we/dust/"..selected_sample, -1)
    -- loaded_poll:update()
    -- engine.rate(0.5)
    -- engine.trigger(0)

    -- add waveform
    waveform_graphics[1] = Waveform:new({
        x = 33,
        y = 20,
        highlight = false,
        sample_length = sample_length,
        vertical_scale = 1,
        samples = {},
        render_samples = waveform_width,
    })

    waveform_graphics[2] = Waveform:new({
        x = 33,
        y = 32,
        highlight = false,
        sample_length = sample_length,
        vertical_scale = 1,
        samples = {},
        render_samples = waveform_width,
    })

    slice_graphic = SliceGraphic:new() 

    local function on_render(ch, start, i, s)
        -- this is a callback, for every softcut.render_buffer() invocation
        waveform_samples[ch] = as_abs_values(s)
        state.interval = i -- represents the interval at which the waveform is sampled for rendering
        update_waveform(ch)
    end
    -- setup callback
    softcut.event_render(on_render)

    if selected_sample then
        filename = to_sample_name(selected_sample)
        if debug_mode then load_sample(_path.dust .. selected_sample) end
        softcut.render_buffer(1, 0, sample_length, waveform_width)    
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
    -- lfo
    slices_lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'clocked',
        period = 8,
        phase = 0,
        action = function(scaled, raw)
            params:set(ID_SAMPLING_SLICE_START, controlspec_start:map(scaled))
        end
    }
    slices_lfo:set('reset_target', 'mid: rising')
    -- slices_lfo:start()
end

return page
