local Waveform = include("symbiosis/lib/graphics/Waveform")
local SliceGraphic = include("symbiosis/lib/graphics/SliceGraphic")

local page_name = "SAMPLING"
local fileselect = require('fileselect')
local page_disabled = false

local waveform_graphics = {}
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
    print("file path: " .. file_path)
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

function update_waveform(waveform, ch)
    -- called by root module when OSC event received for updating waveform
    waveform_graphics[ch].samples = waveform
end

local function get_slice_length()
    -- returns slice length in seconds
    local n_slices = params:get(ID_SLICES_NUM_SLICES)
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
    return util.trim_string_to_width(s, 100)
end

local function update_loop_ranges()
    local n_slices = params:get(ID_SLICES_NUM_SLICES)

    -- if slices > num_voices, not all slices can be assigned to a voice
    -- 6 consecutive slices are assigned to voice 1-6
    local start = params:get(ID_SLICES_START)

    -- edit buffer ranges per voice
    local slice_start_timestamps = {} -- start position of each slice, in seconds
    local slice_length = get_slice_length()
    if not slice_length then return end

    for i = 1, n_slices do
        -- slice 1 starts at 0.0 seconds;
        -- slice 2 starts at 1*slice_length,
        -- slice 3 starts at 2*slice_length, etc
        slice_start_timestamps[i] = (i - 1) * slice_length
    end

    for i = 0, 5 do
        local voice = i + 1

        -- start >= 1; table indexing starts at 1;
        --- start + i maps from 1 to 6 when start = 1,
        --- or 26-32 when start=26.
        --- this works fine for n_slices > 6; else, voices need to recycle slices;
        --- hence the modulo.
        local slice_index = util.wrap(start + i, 1, n_slices)
        slice_graphic.active_slices[voice] = slice_index --update slice graphic
        local start_pos = slice_start_timestamps[slice_index]
        -- loop start/end works as buffer range when loop not enabled
        -- end point is where the next slice starts
        local end_pos = start_pos + (slice_length * .999) -- leave a small gap to prevent overlap

        -- save in params, so waveforms can render correctly
        params:set(ID_SLICES_SECTIONS[voice].loop_start, start_pos)
        params:set(ID_SLICES_SECTIONS[voice].loop_end, end_pos)
        -- voice_position_to_start(voice) --todo: fix, order of initalization bug
    end
    -- reflect changes in graphic (it'll get params from state)
end

local function load_sample(file)
    -- use specified `file` as a sample and store enabled length of buffer in state
    if not file or file == "-" then return end
    local num_channels = audio_util.num_channels(file)
    selected_sample = file
    engine.load_file(file)
    if num_channels > 1 then
        waveform_h = 5
        waveform_graphics[1].y = 20
    else
        waveform_h = 10
        waveform_graphics[1].y = 26
    end
    update_loop_ranges()
end

local function select_sample()
    local function callback(file_path)
        if file_path ~= 'cancel' then
            params:set(ID_SLICES_AUDIO_FILE, file_path)
        end
        page_disabled = false -- proceed with rendering page instead of file menu
        page_indicator_disabled = false
    end
    fileselect.enter(_path.audio, callback, "audio")
    page_disabled = true           -- don't render current page
    page_indicator_disabled = true -- hide page indicator
end

local function constrain_max_start(num_slices)
    -- side effect of adjusting controlspec_slice_start.maxval, is that (raw * maxval) of the controlspec
    -- is a new value, which is why this method implicitly adjusts the value of slice start
    controlspec_slice_start.maxval = num_slices
end

local function action_num_slices(v)
    -- update max start based on number of slices
    constrain_max_start(v)
    slice_graphic.slice_len = 1 / v
    slice_graphic.num_slices = v
    update_loop_ranges()
end

local function action_slice_start(v)
    update_loop_ranges()
end

local function adjust_num_slices(d)
    if selected_sample then
        local p = ID_SLICES_NUM_SLICES
        params:set_raw(p, params:get_raw(p) + d * controlspec_slices.quantum)
    end
end

local function adjust_slice_start(d)
    if selected_sample then
        local p = ID_SLICES_START
        local max_slices = params:get(ID_SLICES_NUM_SLICES)
        local new = util.wrap(params:get(p) + d, 1, max_slices)
        params:set(p, new)
    end
end

local function cycle_lfo()
    local p = ID_SLICES_LFO
    local new_val = util.wrap(params:get(p) + 1, 1, #SLICES_LFO_SHAPES)
    params:set(p, new_val)
end

local function action_lfo(v)
    lfo_util.action_lfo(v, slice_lfo, SLICES_LFO_SHAPES, params:get(ID_SLICES_START))
end

local function e2(d)
    -- todo: can you make this a function of the lfo util?
    if slice_lfo:get("enabled") == 1 then
        lfo_util.adjust_lfo_rate_quant(d, slice_lfo)
    else
        adjust_slice_start(d)
    end
end


local page = Page:create({
    name = page_name,
    e2 = e2,
    e3 = adjust_num_slices,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_off = cycle_lfo,
    k3_off = select_sample,
})

function page:render()
    if page_disabled then
        fileselect:redraw()
        return
    end -- for rendering the fileselect interface
    local lfo_val = SLICES_LFO_SHAPES[params:get(ID_SLICES_LFO)]

    if selected_sample then
        -- show filename of selecteed sample in title bar
        window.title = filename
        waveform_graphics[1]:render()
        if is_stereo then
            waveform_graphics[2]:render()
        end
        slice_graphic:render()

        page.footer.button_text.e2.value = params:get(ID_SLICES_START)
        page.footer.button_text.e3.value = params:get(ID_SLICES_NUM_SLICES)


        page.footer.button_text.k2.value = string.upper(lfo_val)

        if slice_lfo:get("enabled") == 1 then
            -- When LFO is disabled, E2 controls LFO rate
            page.footer.button_text.e2.name = "RATE"
            -- convert period to label representation
            local period = slice_lfo:get('period')
            page.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]
        else
            -- When LFO is disabled, E2 controls pan position
            -- page.footer.button_text.k2.value = "OFF"
            page.footer.button_text.e2.name = "START"
            -- page.footer.button_text.e2.value = misc_util.trim(tostring(), 5)
        end
    else
        screen.level(3)
        screen.font_face(DEFAULT_FONT)
        window.title = "SAMPLING"
        screen.move(64, 32)
        screen.text_center("PRESS K2 TO LOAD SAMPLE")
    end

    window:render()
    page.footer:render()
end

local function add_params()
    -- file selection
    params:set_action(ID_SLICES_AUDIO_FILE,
        function(file)
            if file ~= "-" then
                filename = to_sample_name(file)
                load_sample(file)
            end
        end
    )

    -- number of slices
    params:set_action(ID_SLICES_NUM_SLICES, action_num_slices)

    -- starting slice
    params:set_action(ID_SLICES_START, action_slice_start)
    constrain_max_start(SLICES_DEFAULT)
    for voice = 1, 6 do
        params:set_action(ID_SLICES_SECTIONS[voice].loop_start, function(v) UPDATE_SLICES = true end)
        params:set_action(ID_SLICES_SECTIONS[voice].loop_end, function(v) UPDATE_SLICES = true end)
    end

    -- lfo
    params:set_action(ID_SLICES_LFO, action_lfo)
    params:bang()
end

function page:initialize()
    slice_graphic = SliceGraphic:new()

    -- lfo
    slice_lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'clocked',
        period = 8,
        phase = 0,
        action = function(scaled, raw)
            params:set(ID_SLICES_START, controlspec_slice_start:map(scaled))
        end
    }
    slice_lfo:set('reset_target', 'mid: rising')

    add_params()

    -- engine.load_file("/home/we/dust/"..selected_sample)
    loaded_poll:update()

    -- add waveform
    waveform_graphics[1] = Waveform:new({
        x = 33,
        y = 20,
        sample_length = sample_length,
        waveform_width = waveform_width,
    })

    waveform_graphics[2] = Waveform:new({
        x = 33,
        y = 32,
        sample_length = sample_length,
        waveform_width = waveform_width,
    })

    if selected_sample then
        filename = to_sample_name(selected_sample)
        if debug_mode then load_sample(_path.dust .. selected_sample) end
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
                name = "LFO",
                value = "",
            },
            k3 = {
                name = "LOAD",
                value = "",
            },
            e2 = {
                name = "START",
                value = "",
            },
            e3 = {
                name = "SLCS",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })
end

return page
