local GraphicBase = require(from_root("lib/graphics/GraphicBase"))

EchoGraphic = {
    x = 64,
    y = 23,
    radius = 12,
    hide = false,
    curve = 'lin', --lin, convex, concave
    selected = 1,  -- time slice selected
    feedback = 1,
    wet = 1,
    time = 7,
}

setmetatable(EchoGraphic, { __index = GraphicBase })

local function draw_slider(x, y, w, h, fraction)
    screen.level(1)
    for i = 1, w, 2 do
        screen.rect(x + i, y, 1, h)
        screen.fill()
    end
    screen.level(15)
    screen.rect(2 + math.floor((x + (w - 2) * fraction) / 2) * 2, y, 1, h)
    screen.fill()
end

function EchoGraphic:draw_circles()
    local num_options = 9
    for i = 0, num_options - 1 do
        local current_option = i + 1
        screen.arc(self.x, self.y + 10, 1 + i * 2.3, math.pi, math.pi * 2)
        if current_option == self.time then
            screen.level(15)
        else
            screen.level(1)
        end
        screen.line_width(1)
        screen.stroke()
    end
end

function EchoGraphic:render()
    if self.hide then return end
    self:draw_circles()

    screen.level(1)
    local w = 41
    local h = 3

    screen.level(1)
    local x = self.x - w / 2
    local y = self.y + 16

    draw_slider(x, y - 4, w, h, self.feedback)
    draw_slider(x, y + 1, w, h, self.wet)
end

return EchoGraphic
