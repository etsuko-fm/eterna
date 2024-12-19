local Scene = include("bits/lib/scenes/Scene")
local scene_name = "TimeControls"

local statex = {
    size = 8.0,
    fade = 0.5
}

function adjust_size(d)
    adjust_param(statex.size, d, 0.1)
end

function adjust_fade(d)
    adjust_param(statex.fade, d, 0.1)
end

function adjust_param(param, d, mult)
    fraction = d * mult
    if param + fraction < 0 then
        param = 0
    else
        param = param + fraction
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
    screen.text("slice")
    screen.move(128/8 * 2, 64/8 * 5)
    screen.font_size(16)
    screen.text(string.format("%.1f", statex.size))

    screen.font_size(8)
    screen.move(128/8 * 6, 64/8 * 3)
    screen.text_right("fade")
    screen.move(128/8 * 6, 64/8 * 5)
    screen.font_size(16)
    screen.text_right(string.format("%.1f", statex.fade))

    screen.update()
    if math.random() > .95 then print('rendering time controls') end
end


function scene:initialize()
    -- empty
end

return scene
