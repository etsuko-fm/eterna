Slider = {
    x = 0,
    y = 0,
    w = 64,
    h = 4,
    dash_size = 2,
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
    screen.level(15)
    screen.line_width(1)
    screen.rect(self.x, self.y, self.w, self.h)
    screen.stroke() -- stroke might give it a pixel extra compared to fill

    -- dash (scan pos)
    screen.level(10)
    if self.direction == "HORIZONTAL" then
        screen.rect(self.x + (self.val * (self.w - self.dash_size)), self.y, self.dash_size, self.h)
    elseif self.direction == "VERTICAL" then
        screen.rect(self.x, self.y + (self.val * (self.h - self.dash_size)), self.w, self.dash_size)
    end


    screen.update()
end

return Slider
