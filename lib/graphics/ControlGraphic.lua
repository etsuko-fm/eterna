local GraphicBase = require(from_root("lib/graphics/GraphicBase"))

ControlGraphic = {
    x = 0,
    y = 0,
    w = 128,
    h = 64,
    font_face = 1,
    bpm_font_face = 40,
    bpm_font_size = 12,
    bpm = nil,
    bright = 15,
    default_level = 3,
    is_playing = true,
    current_step = 1, -- 1-based
    cue = nil, -- has value when a step div change is cued
    loop_start = 1,
    loop_end = 16,
}

setmetatable(ControlGraphic, { __index = GraphicBase })

local faint_level = 3
local bright_level = 15
local x = 32
local y = 36
local bpm_x = 95
local seq_h = 3
local seq_y = y
local play_btn_w = 5
local play_btn_h = 8
local pause_button_rect_w = 2

local function draw_play_button(x, y)
    screen.level(bright_level)
    screen.move(x, y - 14)
    screen.line_rel(play_btn_w, play_btn_h / 2)
    screen.line_rel(-play_btn_w, play_btn_h / 2)
    screen.line_rel(0, -play_btn_h)
    screen.fill()
end

local function draw_pause_button(x, y)
    screen.level(bright_level)
    screen.rect(x, y - 14, pause_button_rect_w, 8)
    screen.fill()
    screen.rect(x + 4, y - 14, pause_button_rect_w, 8)
    screen.fill()
end

function ControlGraphic:render()
    if self.hide then return end
    local dim = 0

    -- draw sequence steps
    for step = 1, 16 do
        if step < self.loop_start or step > self.loop_end then
            -- dim brightness if step not enabled
            dim = -10
        else
            dim = 0
        end
        if step == self.current_step then
            graphic_util.screen_level(bright_level, dim, 2)
        else
            graphic_util.screen_level(faint_level, dim, 1)
        end
        local step_y = seq_y
        if (step - 1) % 4 == 0 then
            h = seq_h + 1
            step_y = seq_y - 1
        else
            h = seq_h
            step_y = seq_y
        end
        screen.rect(x + (step - 1) * 4, step_y, 3, h)
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
        screen.rect(x + 64, 37, 1, 1)
        screen.fill()
    end

    -- play/pause
    if self.is_playing then
        draw_pause_button(x, y)
    else
        draw_play_button(x, y)
    end
    self.rerender = false
end

return ControlGraphic
