MetaMixerGraphic = {
    x = 0,
    y = 0,
    w = 56, -- width minus bar_width should be dividable by 5
    h = 24,
    bar_width=6,
    num_bars=6,
    levels={},
    scan_val=0,
    brightness=15,
    bg_bar_brightness=1,
    hide = false,
}

function MetaMixerGraphic:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function MetaMixerGraphic:render()
    if self.hide then return end
    
    for i = 0, 5 do
        if self.render_text then
            screen.level(self.brightness)
            screen.move(i * self.bar_width + self.bar_spacing, 10)
            screen.text(string.format("%.2f", self.levels[i + 1]))
        end
        screen.level(self.bg_bar_brightness)
        screen.rect(
            self.x + (i * (self.w - self.bar_width) / (self.num_bars - 1)),
            self.y,
            self.bar_width,
            -self.h
        )
        screen.fill()
        screen.level(self.brightness)
        screen.rect(
            self.x + (i * (self.w - self.bar_width) / (self.num_bars - 1)),
            self.y,
            self.bar_width,
            -self.h * self.levels[i + 1]
        )
        screen.fill()
    end
end


return MetaMixerGraphic
