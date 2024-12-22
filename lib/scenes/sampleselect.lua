local Scene = include("bits/lib/scenes/Scene")
local scene_name = "SampleSelect"
local fileselect = require('fileselect')
local scene_disabled = false
local selected_file = 'none'


-- get waveform:

-- softcut.render_buffer(ch, start, dur, samples)
-- softcut.event_render(func)
-- https://monome.org/docs/norns/softcut/#8-copy--waveform-data
-- https://github.com/monome/softcut-studies/blob/main/8-copy.lua


local function select_sample(state)
    local function callback(file_path)
        if file_path ~= 'cancel' then
            local split_at = string.match(file_path, "^.*()/")
            selected_file = string.sub(file_path, split_at + 1)
            state.selected_sample = file_path
            state.events.event_switch_sample = true
        end
        scene_disabled = false -- proceed with rendering scene instead of file menu
        print('selected ' .. file_path)
        update_content(1, 0, state.sample_length, 64)
    end
    fileselect.enter(_path.dust, callback, "audio")
    scene_disabled = true
end

function update_content(buffer, winstart, winend, samples)
    -- args bound to UI so should be part of scene
    if samples == nil then samples = 128 end
    softcut.render_buffer(buffer, winstart, winend - winstart, samples)
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
    screen.clear()
    screen.level(15)
    screen.move(0, 40)
    screen.text(selected_file)
    screen.move(0, 60)
    screen.text('K2: select file')

    -- waveform
    local x_pos = 0
    screen.level(4)

    for i, s in ipairs(state.waveform_samples) do
        local height = util.round(math.abs(s) * state.scale_waveform)
        screen.move(util.linlin(0, 128, 10, 120, x_pos), 20 - height)
        screen.line_rel(0, 2 * height)
        screen.stroke()
        x_pos = x_pos + 1
    end

    screen.update()
end

function scene:initialize(state)
    function on_render(ch, start, i, s)
        print('buffer contents rendered')
        state.waveform_samples = s
        state.interval = i -- represents the interval at which the waveform is sampled for rendering
        print("interval: " .. i)
    end

    softcut.event_render(on_render)
    update_content(1, 0, state.sample_length, 64)
end

return scene
