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
    is_playing=true,
    current_step=nil,
    current_quarter=nil,
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

local faint_level = 3
local bright_level = 15

local x = 32
local y = 32
local bpm_x = 95
local seq_h = 3
local seq_y = y
local rep_x = x+10
local rep_y = y-15

function ControlGraphic:render()
    if self.hide then return end

    -- 1/4 report
    for i = 0,3 do
        local q = i + 1
        if q == self.current_quarter then
            screen.level(bright_level)
        else
            screen.level(faint_level)
        end
        screen.rect(rep_x, rep_y + i * 3, 2, 2)
        screen.fill()
    end

    -- sequence steps
    for i=0,15 do
        local step = i+1
        if step == self.current_step then
            screen.level(bright_level)
        else
            screen.level(faint_level)
        end
        screen.rect(x + i * 4, seq_y, 3, seq_h)
        screen.fill()
    end

    -- large bpm counter
    screen.level(bright_level)
    screen.move(bpm_x, y - 6)
    screen.font_size(self.bpm_font_size)
    screen.font_face(self.bpm_font_face) -- 7 is ok; 40 is nice @ size 12
    screen.text_right(self.bpm)

    -- play/pause
    screen.level(bright_level)
    screen.rect(x,y-14,3,8)
    screen.fill()
    screen.rect(x+5,y-14,3,8)
    screen.fill()
end

return ControlGraphic