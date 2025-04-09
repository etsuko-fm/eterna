local Page = include("bits/lib/pages/Page")
local Window = include("bits/lib/graphics/Window")
local Waveform = include("bits/lib/graphics/Waveform")
local page_name = "SampleSelect"
local fileselect = require('fileselect')
local page_disabled = false
local debug = include("bits/lib/util/debug")
local state_util = include("bits/lib/util/state")

local max_length_dirty = false
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
    waveform.enabled_section[1] = state.enabled_section[1]
    waveform.enabled_section[2] = state.enabled_section[2]
    waveform.samples = state.waveform_samples

    if state.waveform_samples[1] then
        state.scale_waveform = 14 / math.max(table.unpack(state.waveform_samples))
    end


end


local function update_segment_lengths(state)
    -- update loop end points when max length has changed
    if max_length_dirty == false then return end
    for i = 1, 6 do
        if state.loop_sections[i][2] - state.loop_sections[i][1] > state.max_sample_length then
            -- no need to protect for empty buffer, as it's shortening it only
            state.loop_sections[i][2] = state.loop_sections[i][1] + state.max_sample_length
            softcut.loop_end(i, state.loop_sections[i][2])
        end
    end
    max_length_dirty = false
end

local function path_to_file_name(file_path)
    -- strips '/foo/bar/audio.wav' to 'audio.wav'
    local split_at = string.match(file_path, "^.*()/")
    return string.sub(file_path, split_at + 1)
end


local function select_sample(state)
    local function callback(file_path)
        if file_path ~= 'cancel' then
            state.selected_sample = file_path
            state.events.event_switch_sample = true
        end
        page_disabled = false -- proceed with rendering page instead of file menu
        print('selected ' .. file_path)
    end
    fileselect.enter(_path.dust, callback, "audio")
    page_disabled = true -- don't render current page
end

function scale_waveform(state, d)
    state_util.adjust_param(state, 'scale_waveform', d, 1, 1, 20, false)
end


local page = Page:create({
    name = page_name,
    e2 = scale_waveform,
    e3 = scale_waveform,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = select_sample,
    k3_on = nil,
    k3_off = nil,
})

function page:render(state)
    if page_disabled then return end -- for rendering the fileselect interface

    -- show filename and sample length
    screen.font_face(state.default_font)
    screen.level(10)
    screen.move(10, 46)
    screen.text(state.filename)
    -- screen.move(10, 47)
    -- screen.font_size(8)
    -- screen.text(math.floor(state.sample_length / 60) .. "'" .. string.format("%02d", math.floor(state.sample_length) % 60) .. "\"")
    -- screen.text(" [" .. state.max_sample_length .. "]")

    update_waveform(state)

    waveform.vertical_scale = state.scale_waveform
    waveform:render()
    window:render()
    update_segment_lengths(state)
    -- screen.update()
    page.footer:render()
end

function page:initialize(state)
    function on_render(ch, start, i, s)
        -- this is a callback, for every softcut.render_buffer() invocation
        print('buffer contents rendered')
        state.waveform_samples = as_abs_values(s)
        state.interval = i -- represents the interval at which the waveform is sampled for rendering
        state.filename = path_to_file_name(state.selected_sample)
        print("interval: " .. i)
        print('max sample val:' .. math.max(table.unpack(state.waveform_samples)))
        update_waveform(state)
    end

    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "SAMPLE BROWSER",
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
        font_face=state.footer_font
    })

    waveform = Waveform:new({
        x = (128 - state.waveform_width) / 2,
        y = 25,
        w = state.waveform_width,
        highlight = false,
        sample_length = state.sample_length,
        enabled_section = state.enabled_section,
        vertical_scale = state.scale_waveform,
        samples = state.waveform_samples,
    })
    -- setup callback
    softcut.event_render(on_render)
    softcut.render_buffer(1, 0, state.sample_length, state.waveform_width)
end

return page
