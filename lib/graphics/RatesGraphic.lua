RatesGraphic = {
    x = 38,
    y = 12,
    lines = 13, -- number of horizontal background lines per pitch slider
    voices = 6,
    block_w = 5,
    block_h = 1,
    margin_w = 4,
    margin_h = 1,
    selected_idx = {}, -- set of indexes that should light up: e.g. [1] = true
    fill = 1,
    active_fill = 15,
    start_active = 1,
    end_active = 17,
    center = 0,  -- current pitch center, corresponds to the number of vertical lines; 0 is middle line
    hide = false,
    voice_pos = {}, -- value    per voice, where each integer step represents one octave up or down; 0 = center (original pitch)
    voice_dir = {},
    voice_env = {},
}

-- only awareness of playback direction is "forward" or "non-forward" (i.e. reverse)
local FWD = "FWD"

local pixels_per_octave = 6

function RatesGraphic:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RatesGraphic:set(idx, active)
    self.selected[idx] = active
end

function RatesGraphic:render()
    if self.hide then return end

    -- draw reference lines
    for line = 0, self.lines - 1 do
        for voice = 0, self.voices - 1 do
            screen.level(self.fill)

            local x = self.x + (self.block_w + self.margin_w) * voice
            local y = self.y + (self.block_h + self.margin_h) * line
            if line ~= math.floor(self.lines / 2 - 1) and line ~= math.floor(self.lines / 2 + 1) then
                screen.rect(x, y, self.block_w, self.block_h)
                screen.fill()
            end
        end
    end

    local center_y = self.y - 1 + math.floor(self.lines/2) * (self.block_h + self.margin_h)
    for n = 0, self.voices - 1 do
        screen.level(self.active_fill)
        local x = self.x + (self.block_w + self.margin_w) * n

        local relative_y = self.voice_pos[n] * pixels_per_octave
        local y = center_y + relative_y

        screen.rect(x, y, self.block_w, 3)

        screen.fill()

        -- 1 is some random extra margin
        local arrow_x = x + 2
        local arrow_y = self.y + (self.block_h + self.margin_h) * self.lines + 2

        if self.voice_env[n+1] ~= nil then
            graphic_util.screen_level(self.active_fill - 13, self.voice_env[n+1] * 13)
        else
            screen.level(self.active_fill)
        end

        -- arrrows indicating fwd/rev playback
        if self.voice_dir[n+1] == FWD then
            -- forward arrow
            screen.move(arrow_x, arrow_y)
            screen.line_rel(0,5)
            screen.move_rel(1,-4)
            screen.line_rel(0,3)
            screen.move_rel(1,-2)
            screen.line_rel(0,1)
        else
            -- backwards arrow
            screen.move(x + 2, arrow_y + 2)
            screen.line_rel(0,1)
            screen.move_rel(1,-2)
            screen.line_rel(0,3)
            screen.move_rel(1,-4)
            screen.line_rel(0,5)
            screen.move_rel(1,0)
        end
        screen.stroke()
    end
end

return RatesGraphic
