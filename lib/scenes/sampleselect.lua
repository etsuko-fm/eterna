local Scene = include("bits/lib/scenes/Scene")
local scene_name = "SampleSelect"
fileselect = require('fileselect')
local disabled = false
selected_file = 'none'
selected_file_path = 'none'


-- get waveform: 

-- softcut.render_buffer(ch, start, dur, samples)
-- softcut.event_render(func)
-- https://monome.org/docs/norns/softcut/#8-copy--waveform-data
-- https://github.com/monome/softcut-studies/blob/main/8-copy.lua

function callback(file_path)      -- this defines the callback function that is used in fileselect
    if file_path ~= 'cancel' then -- if a file is selected in fileselect
        -- the following are some common string functions to help organize the path that is returned from fileselect
        local split_at = string.match(file_path, "^.*()/")
        selected_file_path = string.sub(file_path, 9, split_at)
        selected_file_path = util.trim_string_to_width(selected_file_path, 128)
        selected_file = string.sub(file_path, split_at + 1)
        print(selected_file_path)
        print(selected_file)
    end
    disabled = false
end


local function select_sample()
     -- runs fileselect.enter; `_path.audio` in this example is the folder that will open when fileselect is run
    fileselect.enter(_path.audio, callback, "audio")
    disabled = true
    print('select sample')
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
    if disabled then return end
    screen.clear()
    screen.level(15)
    screen.move(0, 10)
    screen.text('selected file path:')
    screen.move(0, 20)
    screen.text(selected_file_path)
    screen.move(0, 30)
    screen.text('selected file:')
    screen.move(0, 40)
    screen.text(selected_file)
    screen.move(0, 60)
    screen.text('press K3 to select file')
    screen.update()
end

function scene:initialize(state)
end

return scene
