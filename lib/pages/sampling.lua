local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local Waveform = include("bits/lib/graphics/Waveform")
local page_name = "SAMPLING"
local fileselect = require('fileselect')
local page_disabled = false
local debug = include("bits/lib/util/debug")
local state_util = include("bits/lib/util/state")
local misc_util = include("bits/lib/util/misc")

local waveform
local window

local PARAM_ID_AUDIO_FILE = "sampling_audio_file"
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


local function load_sample(state, file)
    -- use specified `file` as a sample and store enabled length of softcut buffer in state
    state.sample_length = audio_util.load_sample(file, true)
    state.pages.slice.enabled_section = { 0, state.max_sample_length }
    if state.sample_length < state.max_sample_length then
        state.pages.slice.enabled_section = { 0, state.sample_length }
    end

    softcut.render_buffer(1, 0, state.sample_length, state.pages.sample.waveform_width)
    update_softcut(state)
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


local page = Page:create({
    name = page_name,
    e2 = nil,
    e3 = nil,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = select_sample,
    k3_on = nil,
    k3_off = nil,
})

function page:render(state)
    if page_disabled then
        fileselect:redraw()
        return
    end -- for rendering the fileselect interface

    page.footer.button_text.k3.name = "LOAD"
    page.footer.button_text.e2.name = ""
    page.footer.button_text.e3.name = ""
    page.footer.button_text.e2.value = ""
    page.footer.button_text.e3.value = ""
    update_waveform(state)
    waveform.vertical_scale = state.pages.sample.scale_waveform
    waveform:render()
    -- show filename and sample length
    screen.font_face(state.default_font)
    screen.level(5)
    screen.move(64, 46)
    screen.text_center(misc_util.trim(state.pages.sample.filename, 24))
    window:render()
    -- screen.update()
    page.footer:render()
end

local function add_params(state)
    params:add_separator("SAMPLING", page_name)
    -- file selection
    params:add_file(PARAM_ID_AUDIO_FILE, 'file')
    params:set_action(PARAM_ID_AUDIO_FILE, function(file) load_sample(state, file) end)
end

function page:initialize(state)
    add_params(state)

      -- init softcut
    local sample1 = "audio/etsuko/sea-minor/sea-minor-chords.wav"
    local sample2 = "audio/etsuko/neon-light/neon intro.wav"
    if debug_mode then load_sample(state, _path.dust .. sample2) end

    local function on_render(ch, start, i, s)
        -- this is a callback, for every softcut.render_buffer() invocation
        print('buffer contents rendered')
        state.pages.sample.waveform_samples = as_abs_values(s)
        state.interval = i -- represents the interval at which the waveform is sampled for rendering
        state.pages.sample.filename = path_to_file_name(state.pages.sample.selected_sample)
        print("interval: " .. i)
        print('max sample val:' .. math.max(table.unpack(state.pages.sample.waveform_samples)))
        update_waveform(state)
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
                name = "",
                value = "",
            },

            e2 = {
                name = "",
                value = "",
            },
            e3 = {
                name = "",
                value = "",
            },
        },
        font_face = state.footer_font
    })

    waveform = Waveform:new({
        x = (128 - state.pages.sample.waveform_width) / 2,
        y = 25,
        w = state.pages.sample.waveform_width,
        highlight = false,
        sample_length = state.sample_length,
        enabled_section = state.enabled_section,
        vertical_scale = state.pages.sample.scale_waveform,
        samples = state.pages.sample.waveform_samples,
    })

    -- setup callback
    softcut.event_render(on_render)
    softcut.render_buffer(1, 0, state.sample_length, state.pages.sample.waveform_width)
end

return page
