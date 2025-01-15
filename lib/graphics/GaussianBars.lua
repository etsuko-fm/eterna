GaussianBars = {
    x = 0,
    y = 0,
    w = 64,
    h = 24,
    bar_width=6,
    num_bars=6,
    levels={},
    scan_val=0,
    sigma=0.3,
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
    self:calculate_gaussian_levels()
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

function GaussianBars:calculate_gaussian_levels()
    -- convert state.scan_val to levels for each softcut voice
    for i = 1, self.num_bars do
        -- translate scan value to a virtual 'position' so that it matches the number of bars (1 <= pos <= num_bars)
        local pos = 1 + (self.scan_val * (self.num_bars))

        -- the 'distance' from the current voice to the scan position
        -- example [6 bars]: scan pos 1, bar 5: abs(1 - 5) = abs(-4) = 4
        --                   scan pos 5, bar 1: abs(5 - 1)) = abs(4) = 4
        local distance = math.min(
            math.abs(pos - i),
            self.num_bars - math.abs(pos - i)
        )

        -- Calculate the level for the current voice using a Gaussian formula:
        -- level = e^(-(distance^2) / (2 * sigma^2))
        -- where distance^2 makes farther voices quieter.
        -- where sigma controls how "wide" the Gaussian curve is (how quickly levels fade).
        local level = math.exp(-(distance ^ 2) / (2 * self.sigma ^ 2)) -- 0 <= level <= 1

        self.levels[i] = level
        -- print('distance['..i..'] = ' .. distance .. ', level['..i..'] = ' .. level)
    end
    return self.levels
end

return GaussianBars
