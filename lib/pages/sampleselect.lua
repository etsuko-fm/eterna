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
    waveform.samples = state.pages.sample.waveform_samples

    if state.pages.sample.waveform_samples[1] then
        state.pages.sample.scale_waveform = 14 / math.max(table.unpack(state.pages.sample.waveform_samples))
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
    fileselect.enter(_path.audio, callback, "audio")
    page_disabled = true -- don't render current page
end

local function scale_waveform(state, d)
    state_util.adjust_param(state.pages.sample, 'scale_waveform', d, 1, 1, 20, false)
end

local function switch_mode(state)
    if state.pages.sample.mode == SAMPLE_MODE["SAMPLE"] then
        state.pages.sample.mode = SAMPLE_MODE["DELAY"]

        -- voice 1 will be recording to buffer 2

        -- adc is analog-to-digital, i.e. analog input channels
        audio.level_adc_cut(1)
        audio.level_eng_cut(0)
        audio.level_tape_cut(0)
        local rec = 1.0
        local pre = 0.75
        local delay_time = 4 -- seconds
        state.enabled_section = {0, delay_time}
        state.sample_length = delay_time
        state.max_sample_length = delay_time
        -- all voices playback from buffer 2
        for i=1,6 do
            -- buffer beperken tot delay_time
            softcut.buffer(i,2)
            softcut.rec(i,1)
            softcut.level_input_cut(1, i, 0.5)
            softcut.level_input_cut(2, i, 0.5)
            softcut.rec_level(i,rec)
            -- set voice 1 pre level
            softcut.pre_level(i,pre)
        end
        state.events['event_randomize_softcut'] = true

    else
        -- turn off recording, switch back to buffer 1
        state.pages.sample.mode = SAMPLE_MODE["SAMPLE"]
        softcut.rec(1,0)
        for i=1,6 do
            softcut.buffer(i,1)
            softcut.rec(i,0)
        end
    end



end

local page = Page:create({
    name = page_name,
    e2 = scale_waveform,
    e3 = scale_waveform,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = switch_mode,
    k3_on = nil,
    k3_off = select_sample,
})

function page:render(state)
    if page_disabled then 
        fileselect:redraw()
        return    
    end -- for rendering the fileselect interface

    -- show filename and sample length
    screen.font_face(state.default_font)
    screen.level(10)
    screen.move(10, 46)
    screen.text(state.pages.sample.filename)

    page.footer.button_text.k2.value = state.pages.sample.mode
    if state.pages.sample.mode == SAMPLE_MODE["DELAY"] then
        page.footer.button_text.k3.name = ""
    else
        page.footer.button_text.k3.name = "LOAD"
    end


    update_waveform(state)

    waveform.vertical_scale = state.pages.sample.scale_waveform
    waveform:render()
    window:render()
    update_segment_lengths(state)
    -- screen.update()
    page.footer:render()
end

function page:initialize(state)
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
