Slider = {
    x = 0,
    y = 0,
    w = 64,
    h = 4,
    dash_size = 2,
    dash_fill = 15,
    fill = 1,
    hide = false,
    val = 0, -- 0 < val < 1
    direction = "HORIZONTAL"
}

function Slider:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function Slider:render()
    if self.hide then return end
    -- rectangle container
    screen.level(self.fill)
    screen.rect(self.x, self.y, self.w, self.h)
    screen.fill()

    -- dash (scan pos)
    screen.level(self.dash_fill)
    if self.direction == "HORIZONTAL" then
        screen.rect(self.x + (self.val * (self.w - self.dash_size + 1)), self.y, self.dash_size, self.h)
    elseif self.direction == "VERTICAL" then
        screen.rect(self.x, (self.y + self.h - self.dash_size) - ((self.h - 1) * self.val), self.w, self.dash_size)
    end
    screen.fill()
    screen.update()
end

return Slider
