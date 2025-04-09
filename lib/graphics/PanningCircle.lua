PanningCircle = {
    -- PanningBars? HorizontalMetaPanner?
    x = 64,
    y = 11,
    w = 32,
    bar_w = 2,
    bar_h = 4,
    margin_h = 2,
    hide = false,
    twist = math.pi / 12, -- controls x position of each bar, in radians
}

function PanningCircle:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function PanningCircle:render()
    if self.hide then return end
    local margin = 2
    for i = 0, 5 do
        screen.level(2)
        screen.rect(32, self.y + (margin+self.bar_h) * i, 64, self.bar_h)
        screen.fill()

        screen.level(15)
        local anglex = (i / 6) * (math.pi * 2) + self.twist-- Divide full circle into 6 parts, offset with twist; in radians

        -- cos goes from -1 to 1, bidirectional and center-based hence the /2
        -- bar should be centered when math.cos(anglex) == 0; therefore -self.bar_w/2
        -- self.w is half the total width (as cos is +/-1), therefore half the width is subtracted from the total available motion range
        local x_float =  -self.bar_w/2 + ((self.w - self.bar_w/2) * math.cos(anglex))
        local x = math.floor(self.x + x_float + .5)
        local y = math.floor(self.y + (self.bar_h + self.margin_h) * i)
        screen.move(x,y)
        screen.rect(x, y, self.bar_w, self.bar_h)
        screen.fill()
    end
end

return PanningCircle
