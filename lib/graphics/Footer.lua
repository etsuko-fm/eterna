Footer = {
    x = 0,
    y = 0,
    height = 8,
    hide = false,
    foreground_fill = 3,
    background_fill = 1,
    on = false,
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

    local x1 = 0
    local x2 = 128 / 4
    local x3 = (128 / 4) * 2
    local x4 = (128 / 4) * 3

    screen.level(1)
    screen.rect(x1, 56, 128 / 4 - 1, 8)
    screen.rect(x2, 56, 128 / 4 - 1, 8)
    screen.rect(x3, 56, 128 / 4 - 1, 8)
    screen.rect(x4, 56, 128 / 4 - 1, 8)
    screen.fill()
    screen.level(3)
    screen.circle(x1 + 5, self.y, 2)
    screen.fill()

    screen.move(x1 + 9, self.y + 2)
    screen.font_face(1)
    screen.text("x")

    screen.move(x2 + 5, self.y)
    screen.circle(x2 + 5, self.y, 2)
    screen.fill()

    screen.move(x2 + 9, self.y + 3)
    screen.text("Y")

    screen.move(x3 + 4, self.y)
    screen.line(x3 + 6, self.y)
    screen.move(x3 + 3, self.y + 1)
    screen.line(x3 + 7, self.y + 1)
    screen.stroke()

    screen.move(x4 + 4, self.y)
    screen.line(x4 + 6, self.y)
    screen.move(x4 + 3, self.y + 1)
    screen.line(x4 + 7, self.y + 1)
    screen.stroke()
    screen.update()
end

return Toggle
