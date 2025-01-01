local Scene = include("bits/lib/scenes/Scene")
local scene_name = "SampleSelect"
local fileselect = require('fileselect')
local scene_disabled = false

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
    e2 = nil,
    e3 = nil,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = select_sample,
    k2_off = nil,
    k3_on = nil,
    k3_off = nil,
})

function scene:render(state)
    if scene_disabled then return end -- for rendering the fileselect interface

    -- todo: reusable button graphic (rect + text, selected/deselected)
    screen.clear()
    screen.level(15)
    screen.move(0, 45)
    screen.text(state.filename)
    screen.move(0, 60)
    screen.text('FILE  ZOOM  LOOP  SIZE')

    -- waveform
    local x_pos = 0
    screen.level(2)

    for i, s in ipairs(state.waveform_samples) do
        local height = util.round(math.abs(s) * state.scale_waveform)
        screen.move(util.linlin(0, 128, 10, 120, x_pos), 20 - height)
        if i >= state.enabled_section[1] and i < state.enabled_section[2] then
            screen.level(15)
        else
            screen.level(4)
        end
        screen.line_rel(0, 2 * height)
        screen.stroke()
        x_pos = x_pos + 1
    end

    screen.update()
end

function scene:initialize(state)
    function on_render(ch, start, i, s)
        -- this is a callback, for every softcut.render_buffer() invocation
        print('buffer contents rendered')
        state.waveform_samples = s
        state.interval = i -- represents the interval at which the waveform is sampled for rendering
        state.filename = path_to_file_name(state.selected_sample)
        print("interval: " .. i)
    end

    -- setup callback
    softcut.event_render(on_render)
    softcut.render_buffer(1, 0, state.sample_length, 128)
end

return scene
