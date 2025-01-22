Footer = {
    x = 0,
    y = 55,
    graphics_y = 59,
    height = 9,
    text_y = 3,
    knob_y = 3,
    enc_y = 3,
    hide = false,
    active_fill = 15,
    foreground_fill = 3,
    background_fill = 1,
    e2 = '',
    e3 = '',
    k2 = '',
    k3 = '',
    active_knob = nil,
}

function Footer:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function Footer:render()
    if self.hide then return end

    screen.line_width(1)
    local x1 = 0
    local x2 = 128 / 4
    local x3 = (128 / 4) * 2
    local x4 = (128 / 4) * 3

    screen.level(self.background_fill)
    screen.rect(x1, self.y, 128 / 4 - 1, self.height)
    screen.rect(x2, self.y, 128 / 4 - 1, self.height)
    screen.rect(x3, self.y, 128 / 4 - 1, self.height)
    screen.rect(x4, self.y, 128 / 4 - 1, self.height)
    screen.fill()

    local fill = self.foreground_fill
    if self.active_knob == "e2" then fill = self.active_fill else fill = self.foreground_fill end

    screen.level(fill)
    screen.circle(x1 + 5, self.graphics_y, 2)
    screen.fill()

    screen.move(x1 + 9, self.graphics_y + self.text_y)
    screen.font_face(1)
    screen.text(self.e2)

    if self.active_knob == "e3" then fill = self.active_fill else fill = self.foreground_fill end
    screen.level(fill)

    screen.move(x2 + 5, self.graphics_y)
    screen.circle(x2 + 5, self.graphics_y, 2)
    screen.fill()

    screen.move(x2 + 9, self.graphics_y + self.text_y)
    screen.text(self.e3)

    if self.active_knob == "k2" then fill = self.active_fill else fill = self.foreground_fill end
    screen.level(fill)

    screen.move(x3 + 4, self.graphics_y)
    screen.line(x3 + 6, self.graphics_y)
    screen.move(x3 + 3, self.graphics_y + 1)
    screen.line(x3 + 7, self.graphics_y + 1)
    screen.stroke()

    screen.move(x3 + 9, self.graphics_y + self.text_y)
    screen.text(self.k2)

    if self.active_knob == "k3" then fill = self.active_fill else fill = self.foreground_fill end
    screen.level(fill)

    screen.move(x4 + 4, self.graphics_y)
    screen.line(x4 + 6, self.graphics_y)
    screen.move(x4 + 3, self.graphics_y + 1)
    screen.line(x4 + 7, self.graphics_y + 1)

    screen.move(x4 + 9, self.graphics_y + self.text_y)
    screen.text(self.k3)

    screen.stroke()
    screen.update()
end

return Footer
