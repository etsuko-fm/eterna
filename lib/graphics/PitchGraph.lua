
PitchGraph = {
    x = 38,
    y = 12,
    lines = 17,
    voices = 6,
    block_w = 5,
    block_h = 1,
    margin_w = 4,
    margin_h = 1,
    selected_idx = {}, -- set of indexes that should light up: e.g. [1] = true
    fill = 2,
    active_fill = 15,
    start_active = 1,
    end_active = 17,
    center = 0, -- current pitch center, corresponds to the number of vertical lines; 0 is middle line
    hide = false,
    voice_pos={}
}

function PitchGraph:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- for i=0,5 do
    --     self.voice_pos[i] = self.y + 32 * math.random()
    -- end

    -- return instance
    return o
end

function PitchGraph:set(idx, active)
    self.selected[idx] = active
end


function PitchGraph:render()
    if self.hide then return end
    local center_line = math.floor(self.lines/2)
    for line = 0, self.lines - 1 do
        for voice = 0, self.voices - 1 do
            -- if center == 0, filled line should be center_line
            if self.center + center_line == line then
                -- print("activate line", line, "self.center", self.center, "centerline", center_line)
                screen.level(self.active_fill)
            else
                screen.level(self.fill)
            end
            local x =  self.x + (self.block_w + self.margin_w) * voice
            local y =  self.y + (self.block_h + self.margin_h) * line
            if line ~= math.floor(self.lines/2 - 1) and line ~= math.floor(self.lines/2 + 1) then
                screen.rect(x, y, self.block_w, self.block_h)
                screen.fill()
            end 
            screen.level(self.active_fill)
            -- 16 = ?
            screen.rect(x, 27+self.voice_pos[voice]* 8, self.block_w, 3)
            screen.fill()

        end
    end

    -- screen.move(-2 + self.x, self.y+10)
    -- screen.line(1 + self.x + (self.block_w + self.margin_w) * 5 + self.block_w, self.y + 10)
    -- for voice = 0, self.voices - 1 do
    --     screen.level(self.fill)
    --     local x =  self.x + (self.block_w + self.margin_w) * voice

    --     -- local y =  self.y + (self.block_h + self.margin_h) * line
    --     screen.rect(x, self.y, self.block_w, 32)
    --     screen.stroke()
    -- end
end

return PitchGraph
