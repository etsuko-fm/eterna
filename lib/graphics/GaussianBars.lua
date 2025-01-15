GaussianBars = {
    x = 0,
    y = 0,
    w = 64,
    h = 24,
    bar_width=6,
    num_bars=6,
    levels={},
    hide = false,
    render_text=false,
}

function GaussianBars:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function GaussianBars:render()
    if self.hide then return end
    for i = 0, 5 do
        if self.render_text then
            screen.move(i * 20, 10)
            screen.text(string.format("%.2f", self.levels[i + 1]))
        end
        screen.rect(
            self.x + (i * (self.w - self.bar_width) / (self.num_bars - 1)),
            self.y,
            self.bar_width,
            -self.h * self.levels[i + 1]
        )
        screen.fill()
    end

    screen.update()
end

return GaussianBars
