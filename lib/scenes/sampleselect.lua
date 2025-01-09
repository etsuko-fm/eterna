local Scene = include("bits/lib/scenes/Scene")
local scene_name = "SampleSelect"
local fileselect = require('fileselect')
local scene_disabled = false
local debug = include("bits/lib/util/debug")
local max_length_dirty = false

--[[
Sample select scene
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
    for i = 1, #tbl do 
        tbl[i] = math.abs(tbl[i])
    end
    return tbl
end

local function adjust_param(tbl, param, d, mult, min, max)
    -- todo: unify with adjust_param in timecontrols
    local fraction = d * mult
    if min == nil then min = 0 end
    if max == nil then max = 128 end
    if tbl[param] + fraction < min then
        tbl[param] = min
    elseif tbl[param] + fraction > max then
        tbl[param] = max
    else
        tbl[param] = tbl[param] + fraction
    end
    return tbl[param] -- for inspection
end

local function adjust_loop_pos(state, d)
    print(state.enabled_section[1] .. ',' .. state.enabled_section[2])
    adjust_param(state.enabled_section, 1, d, 1, 0, state.sample_length - state.max_sample_length)
    adjust_param(state.enabled_section, 2, d, 1, state.max_sample_length, state.sample_length)
    max_length_dirty = true
    state.events['event_randomize_softcut'] = true
end


local function adjust_loop_len(state, d)
    print(state.enabled_section[1] .. ',' .. state.enabled_section[2])
    adjust_param(state, 'max_sample_length', d, 0.1, 0.01, 10)
    state.enabled_section[2] = state.enabled_section[1] + state.max_sample_length
    max_length_dirty = true
    state.events['event_randomize_softcut'] = true
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

function smooth_with_mean(tbl, n)
    local smoothed_table = {}
    for i = 1, #tbl do
        local sum = 0
        local count = 0

        -- Iterate over the surrounding elements
        for j = i - n, i + n do
            if j >= 1 and j <= #tbl then
                sum = sum + math.abs(tbl[j])
                count = count + 1
            end
        end

        -- Compute the mean and store it in the new table
        smoothed_table[i] = sum / count
    end
    return smoothed_table
end

function replace_with_mean(tbl)
    for i = 2, #tbl - 1, 2 do
        tbl[i] = (math.abs(tbl[i - 1]) + math.abs(tbl[i + 1])) / 2
    end
    return tbl
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
        scene_disabled = false -- proceed with rendering scene instead of file menu
        print('selected ' .. file_path)
    end
    fileselect.enter(_path.dust, callback, "audio")
    scene_disabled = true
end

function scale_waveform(state, d)
    state.scale_waveform = state.scale_waveform + d
end

local scene = Scene:create({
    name = scene_name,
    e1 = nil,
    e2 = adjust_loop_pos,
    e3 = adjust_loop_len,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = select_sample,
    k2_off = nil,
    k3_on = nil,
    k3_off = nil,
})

function scene:render(state)
    if scene_disabled then return end -- for rendering the fileselect interface
    screen.clear()

    -- window
    screen.move(0,0)
    screen.rect(0, 0, 128, 9)
    screen.level(8)
    screen.fill()
    screen.move(64, 6)
    screen.level(0)
    screen.font_face(68)
    screen.text_center("sample")

    -- todo: reusable button graphic (rect + text, selected/deselected)
    screen.level(15)
    screen.move(0, 45)
    screen.text(state.filename)
    screen.move(0, 55)
    screen.text(math.floor(state.sample_length / 60)  .. "'" .. string.format("%02d", state.sample_length % 60) .. "\"")
    screen.text(" [" .. state.max_sample_length .. "]")
    -- waveform
    local x_pos = 0
    screen.level(2)
    screen.font_face(68)
    screen.font_size(8)
    local enabled_start_sample = util.linlin(0, state.sample_length, 0, 128, state.enabled_section[1])
    local enabled_end_sample = util.linlin(0, state.sample_length, 0, 128, state.enabled_section[2])
    -- print('stt: ' .. enabled_start_sample)
    -- print('end: ' .. enabled_end_sample)
    for i, s in ipairs(state.waveform_samples) do
        local height = util.round(math.abs(s) * state.scale_waveform)
        screen.move(util.linlin(0, 128, 10, 120, x_pos), 20 - height)

        if i >= enabled_start_sample and i <= enabled_end_sample then
            -- brighten the selected part of the waveform 
            -- todo: this should be based on the number of seconds, not pixels
            screen.level(15)
        else
            screen.level(4)
        end
        screen.line_rel(0, 2 * height)
        screen.stroke()
        x_pos = x_pos + 1
    end

    update_segment_lengths(state)
    screen.update()
end

function scene:initialize(state)
    function on_render(ch, start, i, s)
        -- this is a callback, for every softcut.render_buffer() invocation
        print('buffer contents rendered')
        state.waveform_samples = as_abs_values(s)
        state.interval = i -- represents the interval at which the waveform is sampled for rendering
        state.filename = path_to_file_name(state.selected_sample)
        print("interval: " .. i)
        print('max sample val:' .. math.max(table.unpack(state.waveform_samples)))
    end

    -- setup callback
    softcut.event_render(on_render)
    softcut.render_buffer(1, 0, state.sample_length, 128)
end

return scene
