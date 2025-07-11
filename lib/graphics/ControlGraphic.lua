ControlGraphic = {
    x = 0,
    y = 0,
    w = 128,
    h = 64,
    title = "WINDOW",
    font_face = 1,
    bpm_font_face=40,
    bpm_font_size=12,
    bpm=120.0,
    bright=15,
    default_level=3,
}

function ControlGraphic:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

local y = 30
local bpm_x = 95
local bpm_y = y + 2
local bar_h = 4

function ControlGraphic:render()
    if self.hide then return end

    screen.level(self.default_level)
    screen.rect(32, bpm_y, 63, bar_h)
    screen.fill()

    for i=0,15 do
        if i == 4 then
            screen.level(self.bright)
        else
            screen.level(self.default_level)
        end
        screen.rect(32 + i * 4, y+8, 3, bar_h)
        screen.fill()
    end
    screen.level(self.default_level)
    for i=0,3 do
        screen.rect(32+i*7, y-4, 6, bar_h)
        screen.fill()
    end
    for i=5,8 do
        screen.rect(33+i*7, y-4, 6, bar_h)
        screen.fill()
    end
    screen.level(self.bright)
    screen.rect(32 + 4*7, y-4, 7, bar_h)
    screen.fill()

    screen.level(15)
    screen.move(bpm_x, y - 6)
    screen.font_size(self.bpm_font_size)
    screen.font_face(self.bpm_font_face) -- 7 is ok; 40 is nice @ size 12
    screen.text_right(self.bpm)
end

return ControlGraphic