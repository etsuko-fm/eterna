PitchGraph = {
    x = 38,
    y = 12,
    lines = 13,
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
    voice_pos = {}, -- value per voice, where each integer step represents one octave up or down; 0 = center (original pitch)
    voice_dir = {},
}

-- only awareness of playback direction is "forward" or "non-forward" (i.e. reverse)
local FWD = "FWD"

local pixels_per_octave = 4

function PitchGraph:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function PitchGraph:set(idx, active)
    self.selected[idx] = active
end

function PitchGraph:render()
    if self.hide then return end
    local center_line = math.floor(self.lines / 2)

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


    for n = 0, self.voices - 1 do
        screen.level(self.active_fill)
        local x = self.x + (self.block_w + self.margin_w) * n

        -- center line acts as middle of graph; voice_pos adds/subtracts value * pixels/octave
        screen.rect(x, self.y -1 + math.floor(self.lines/2)*(self.block_h + self.margin_h) + self.voice_pos[n] * pixels_per_octave, self.block_w, 3)
        screen.fill()

        -- 3 is some random extra margin
        if self.voice_dir[n+1] == FWD then
            -- forward arrow
            screen.move(x + 1, self.y + (self.block_h + self.margin_h) * self.lines + 3)
            screen.line_rel(3,2)
            screen.line_rel(-3,2)
        else
            -- backwards arrow
            screen.move(x + 4, self.y + (self.block_h + self.margin_h) * self.lines + 3)
            screen.line_rel(-3,2)
            screen.line_rel(3,2)
        end
        screen.stroke()
    end
end

return PitchGraph
