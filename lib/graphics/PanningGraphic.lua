PanningGraphic = {
    -- PanningBars? HorizontalMetaPanner?
    x = 32,
    y = 11,
    pans = {0,0,0,0,0,0,},
    pixel_width=32,
    bar_w = 2,
    bar_h = 4,
    margin_h = 2,
    hide = false,
}

function PanningGraphic:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function PanningGraphic:render()
    if self.hide then return end
    local margin = 2
    local half_bar = self.bar_w/2

    -- indicator should not exceed graph
    local max_indicator_x = self.pixel_width - half_bar

    for i = 0, 5 do
        local voice = i+1
        -- draw background rectangle
        screen.level(2)
        screen.rect(self.x, self.y + (margin+self.bar_h) * i, 64, self.bar_h)
        screen.fill()

        -- pan is -1 to 1
        local indicator_x = self.pans[voice] * max_indicator_x

        local x = math.floor(self.x + (self.pixel_width - half_bar) + indicator_x + .5)
        local y = math.floor(self.y + (self.bar_h + self.margin_h) * i)

        -- draw indicator
        screen.move(x,y)
        screen.level(15)
        screen.rect(x, y, self.bar_w, self.bar_h)
        screen.fill()
    end
end

return PanningGraphic
