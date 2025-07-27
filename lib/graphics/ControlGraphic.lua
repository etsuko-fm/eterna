ControlGraphic = {
    x = 0,
    y = 0,
    w = 128,
    h = 64,
    title = "WINDOW",
    font_face = 1,
    bpm_font_face = 40,
    bpm_font_size = 12,
    bpm = 120.0,
    bright = 15,
    default_level = 3,
    is_playing = true,
    current_step = nil,
    current_quarter = nil,
    cue = nil,
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
local y = 36
local bpm_x = 95
local seq_h = 3
local seq_y = y
local rep_x = x
local rep_y = y - 3
local play_btn_w = 5
local play_btn_h = 8
local pause_button_rect_w = 2

local function draw_play_button()
    screen.level(bright_level)
    screen.move(x, y - 14)
    screen.line_rel(play_btn_w, play_btn_h / 2)
    screen.line_rel(-play_btn_w, play_btn_h / 2)
    screen.line_rel(0, -play_btn_h)
    screen.fill()
end

local function draw_pause_button()
    screen.level(bright_level)
    screen.rect(x, y - 14, pause_button_rect_w, 8)
    screen.fill()
    screen.rect(x + 4, y - 14, pause_button_rect_w, 8)
    screen.fill()
end

function ControlGraphic:render()
    if self.hide then return end

    -- 1/4 report
    for i = 0, 3 do
        local q = i + 1
        if q == self.current_quarter then
            screen.level(bright_level)
        else
            screen.level(faint_level)
        end
        screen.rect(rep_x + i * 16, rep_y, 3, 1)
        screen.fill()
    end

    -- sequence steps
    for i = 0, 15 do
        local step = i + 1
        if step == self.current_step then
            screen.level(bright_level)
        else
            screen.level(faint_level)
        end
        local step_y = seq_y
        if i % 4 == 0 then
            h = seq_h + 1
            step_y = seq_y - 1
        else
            h = seq_h
            step_y = seq_y
        end
        screen.rect(x + i * 4, step_y, 3, h)
        screen.fill()
    end

    -- large bpm counter
    screen.level(bright_level)
    screen.move(bpm_x, y - 6)
    screen.font_size(self.bpm_font_size)
    screen.font_face(self.bpm_font_face) -- 7 is ok; 40 is nice @ size 12
    screen.text_right(self.bpm)


    -- cue
    if self.cue then
        screen.level(2)
        screen.rect(x+64,37,1,1)
        screen.fill()
    end

    -- play/pause
    if self.is_playing then
        draw_pause_button()
    else
        draw_play_button()
    end
end

return ControlGraphic
