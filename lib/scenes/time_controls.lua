local Scene = include("bits/lib/scenes/Scene")
local scene_name = "TimeControls"

local size = 8.0
local fade = 0.5

function adjust_size(d)
    fraction = d/10
    if size + fraction < 0 then
        size = 0
    else
        size = size + fraction
    end
end

function adjust_fade(d)
    fraction = d/10
    if fade + fraction < 0 then
        fade = 0
    else
        fade = fade + fraction
    end
end

local scene = Scene:create({
    name = scene_name,
    e1 = nil,
    e2 = adjust_size,
    e3 = adjust_fade,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = nil,
    k3_on = nil,
    k3_off = nil,
})

function scene:render(state)
    screen.clear()
    screen.font_size(8)
    screen.move(128/8 * 2, 64/8 * 3)
    screen.text("size")
    screen.move(128/8 * 2, 64/8 * 5)
    screen.font_size(16)
    screen.text(string.format("%.1f", size))

    screen.font_size(8)
    screen.move(128/8 * 6, 64/8 * 3)
    screen.text_right("fade")
    screen.move(128/8 * 6, 64/8 * 5)
    screen.font_size(16)
    screen.text_right(string.format("%.1f", fade))

    screen.update()
    if math.random() > .95 then print('rendering time controls') end
end


function scene:initialize()
    -- empty
end

return scene
