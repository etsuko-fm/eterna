LevelsGraphic = {
    x = 0,
    y = 0,
    w = 56, -- width minus bar_width should be dividable by 5
    h = 24,
    bar_width = 6,
    num_bars = 6,
    levels = {},
    scan_val = 0,
    brightness = 15,
    bg_bar_brightness = 5,
    hide = false,
    voice_amp = {},
}

function LevelsGraphic:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

local function draw_slider(x, y, w, h, fraction)
    -- draw background stripes
    screen.level(1)
    for i = 0, w, 2 do
        screen.rect(x + i, y, 1, h)
        screen.fill()
    end

    -- draw indicator of active position
    screen.level(15)
    local indicator_x = math.floor((x + w * fraction) / 2) * 2
    screen.rect(indicator_x, y, 1, h)
    screen.fill()
end

local scan_bar_w = 2
local scan_bar_h = 2
local scan_bar_v_margin = 3

function LevelsGraphic:render()
    if self.hide then return end

    for i = 0, 5 do
        local voice = i + 1
        -- screen.rect(
        --     self.x + (i * (self.w - self.bar_width) / (self.num_bars - 1)),
        --     self.y,
        --     self.bar_width,
        --     -self.h
        -- )
        -- screen.fill()
        screen.level(self.bg_bar_brightness)
        local x = self.x + (i * (self.w - self.bar_width) / (self.num_bars - 1))
        local h = util.round(-self.h * self.levels[voice])
        screen.rect(
            x,
            self.y,
            self.bar_width,
            h
        )
        screen.fill()

        if self.voice_amp[voice] ~= nil then
            screen.level(15)
            -- if the signal clips, just show it as the maximum value
            local amp = math.min(self.voice_amp[voice], 1)
            screen.rect(x, self.y, self.bar_width, h * amp)
            screen.fill()
        else
            print(voice .. "is nil")
        end
    end

    -- scan position slider
    local slider_y = self.y + scan_bar_v_margin
    draw_slider(self.x, slider_y, self.w, scan_bar_h, self.scan_val)
end

return LevelsGraphic
