local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local Waveform = include("bits/lib/graphics/Waveform")
local EchoGraphic = include("bits/lib/graphics/EchoGraphic")
local page_name = "SampleSelect"
local fileselect = require('fileselect')
local page_disabled = false
local debug = include("bits/lib/util/debug")
local state_util = include("bits/lib/util/state")
local misc_util = include("bits/lib/util/misc")

local max_length_dirty = false
local waveform
local echo_graphic
local window

local min_feedback = 0
local max_feedback = 100

local min_time = 0.1
local max_time = 2.0


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

local function adjust_time(state, d)
    state_util.adjust_param(state.pages.sample.echo, 'time', d, 0.1, min_time, max_time)
    state.enabled_section = { 0, state.pages.sample.echo.time }
    state.sample_length = state.pages.sample.echo.time
    state.max_sample_length = state.pages.sample.echo.time
    state.events['event_randomize_softcut'] = true
end

local function adjust_feedback(state, d)
    state_util.adjust_param(
        state.pages.sample.echo,
        'feedback',
        d,
        1 + 10 ^ math.log(state.pages.sample.echo.feedback, 100) / 25,
        min_feedback,
        max_feedback
    )

    for i = 1, 6 do
        softcut.pre_level(i, state.pages.sample.echo.feedback / 100)
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
            state.pages.sample.selected_sample = file_path
            state.events.event_switch_sample = true
        end
        page_disabled = false -- proceed with rendering page instead of file menu
        print('selected ' .. file_path)
    end
    fileselect.enter(_path.audio, callback, "audio")
    page_disabled = true -- don't render current page
end



local function switch_mode(state)
    -- switch between delay mode and sample mode
    if state.pages.sample.mode == SAMPLE_MODE["SAMPLE"] then
        state.pages.sample.mode = SAMPLE_MODE["DELAY"]

        -- voice 1 will be recording to buffer 2

        -- adc is analog-to-digital, i.e. analog input channels
        audio.level_adc_cut(1)
        audio.level_eng_cut(0)
        audio.level_tape_cut(0)
        local rec = 1.0
        local pre = state.pages.sample.echo.feedback / 100 -- 0 to 1 
        local delay_time = 4                               -- seconds
        state.enabled_section = { 0, delay_time }
        state.sample_length = delay_time
        state.max_sample_length = delay_time
        -- all voices playback from buffer 2
        for i = 1, 6 do
            -- buffer beperken tot delay_time
            softcut.buffer(i, 2)
            softcut.rec(i, 1)
            softcut.level_input_cut(1, i, 0.5)
            softcut.level_input_cut(2, i, 0.5)
            softcut.rec_level(i, rec)
            -- set voice 1 pre level
            softcut.pre_level(i, pre)
        end
        state.events['event_randomize_softcut'] = true
    else
        -- turn off recording, switch back to buffer 1
        state.pages.sample.mode = SAMPLE_MODE["SAMPLE"]
        softcut.rec(1, 0)
        for i = 1, 6 do
            softcut.buffer(i, 1)
            softcut.rec(i, 0)
        end
    end
end

local function e2(state, d)
    if state.pages.sample.mode == SAMPLE_MODE["DELAY"] then
        adjust_time(state, d)
    end
end

local function e3(state, d)
    if state.pages.sample.mode == SAMPLE_MODE["DELAY"] then
        adjust_feedback(state, d)
    end
end

local page = Page:create({
    name = page_name,
    e2 = e2,
    e3 = e3,
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


    page.footer.button_text.k2.value = state.pages.sample.mode
    if state.pages.sample.mode == SAMPLE_MODE["DELAY"] then
        page.footer.button_text.k3.name = "STYLE"
        page.footer.button_text.e2.name = "TIME"
        page.footer.button_text.e3.name = "FEEDB"
        page.footer.button_text.e3.value = "FEEDB"
        page.footer.button_text.e2.value = misc_util.trim(tostring(state.pages.sample.echo.time), 5)
        page.footer.button_text.e3.value = misc_util.trim(tostring(state.pages.sample.echo.feedback), 5)
        echo_graphic.feedback = util.linlin(min_feedback, max_feedback, 0, 1, state.pages.sample.echo.feedback)
        echo_graphic.time = util.linlin(min_time,max_time, 0, 1, state.pages.sample.echo.time)
        echo_graphic:render()
    else
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
    end
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

    echo_graphic = EchoGraphic:new({
        feedback = state.pages.sample.echo.feedback,
        max_feedback = max_feedback,
        time = state.pages.sample.echo.time,
    })

    -- setup callback1
    softcut.event_render(on_render)
    softcut.render_buffer(1, 0, state.sample_length, state.pages.sample.waveform_width)
end

return page
