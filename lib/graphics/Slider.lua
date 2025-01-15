Slider = {
    x = 0,
    y = 0,
    w = 64,
    h = 4,
    dash_width = 2,
    hide = false,
    scan_val = 0, -- 0 < scan_val < 1
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
    screen.level(15)
    screen.line_width(1)
    screen.rect(self.x, self.y, self.w, self.h)
    screen.stroke()     -- stroke might give it a pixel extra compared to fill

    -- dash (scan pos)
    screen.level(10)
    screen.rect(self.x + (self.scan_val * (self.w - self.dash_width)), self.y, self.dash_width, self.h)

    screen.update()
end

return Slider
