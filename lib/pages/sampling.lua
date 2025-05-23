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


local function select_sample(state)
    local function callback(file_path)
        if file_path ~= 'cancel' then
            state.pages.sample.selected_sample = file_path
            state.events.event_switch_sample = true
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
    k2_off = nil,
    k3_on = nil,
    k3_off = select_sample,
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
    screen.move(34, 46)
    screen.text(misc_util.trim(state.pages.sample.filename, 16))
    window:render()
    -- screen.update()
    page.footer:render()
end

local function add_params(state)
    params:add_separator("SAMPLING", page_name)
end

function page:initialize(state)
    add_params(state)
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
                name = "MODE",
                value = "SAMPL",
            },
            k3 = {
                name = "LOAD",
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
