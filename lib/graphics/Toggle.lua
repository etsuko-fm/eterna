Toggle = {
    x = 0,
    y = 0,
    size = 4,
    hide = false,
    on = false,
}

function Toggle:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function Toggle:render()
    if self.hide then return end
    screen.line_width(1)
    screen.move(self.x, self.y)
    screen.level(15)
    local txt
    if self.on then
        screen.rect(self.x - 1, self.y - 1, self.size + 1, self.size + 1)
        screen.fill()

        txt = 'ON'
    else
        screen.rect(self.x, self.y, self.size, self.size)
        screen.stroke()
        txt = "OFF"
    end
    screen.move(self.x + self.size + 3, self.y + 4)

    screen.text(txt)
    screen.update()
end

return Toggle
