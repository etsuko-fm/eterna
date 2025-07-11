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

local x = 32
local y = 32
local bpm_x = 95
local bpm_y = y + 2
local bar_h = 2
local seq_h = 3
local seq_y = y
local speed_y = y + 6

function ControlGraphic:render()
    if self.hide then return end

    -- BPM bar
    -- screen.level(self.default_level)
    -- screen.rect(x, bpm_y, 63, bar_h)
    -- screen.fill()

    -- sequence steps
    for i=0,15 do
        local step = i+1
        if step == self.current_step then
            screen.level(self.bright)
        else
            screen.level(self.default_level)
        end
        screen.rect(x + i * 4, seq_y, 3, seq_h)
        screen.fill()
    end

    -- sequence speed
    -- screen.level(self.default_level)
    -- local widths = {2,3,4,5,6,7,8,9,11}
    -- local accum = 0
    -- for i=1,9 do
    --     screen.rect(x+accum, speed_y, widths[i], bar_h)
    --     screen.fill()
    --     accum = accum + widths[i] + 1
    -- end

    -- selected speed
    -- screen.level(self.bright)
    -- screen.rect(32 + 4*7, y-4, 7, bar_h)
    -- screen.fill()

    -- large bpm counter
    screen.level(15)
    screen.move(bpm_x, y - 6)
    screen.font_size(self.bpm_font_size)
    screen.font_face(self.bpm_font_face) -- 7 is ok; 40 is nice @ size 12
    screen.text_right(self.bpm)

    -- play/pause
    screen.level(15)
    -- screen.move(x,)
    screen.rect(x,y-14,3,8)
    screen.fill()
    screen.rect(x+5,y-14,3,8)
    screen.fill()

    -- metronome
    -- local r = 3
    -- screen.move(x+14+r, y-10)
    -- screen.circle(x+14,y-10,r)
    -- screen.stroke()

end

return ControlGraphic