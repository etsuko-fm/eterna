local Scene = include("bits/lib/scenes/Scene")
local scene_name = "Scan"


local scene = Scene:create({
    name = scene_name,
    e1 = nil,
    e2 = nil,
    e3 = nil,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = nil,
    k3_on = nil,
    k3_off = nil,
})

function scene:render(state)
    screen.clear()
    screen.level(15)
    screen.move(64,32)
    screen.text_center("Scan")
    screen.update()
end

function scene:initialize()
    -- empty
end

return scene
