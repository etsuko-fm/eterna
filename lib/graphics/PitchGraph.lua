
PitchGraph = {
    x = 38,
    y = 13,
    lines = 15, -- effectively num of pitches; 4,3,2,1,0,1,2,3,4 = 9; but for finetune more is nice
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
    hide = false,
}

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
    for line = 0, self.lines - 1 do
        for voice = 0, self.voices - 1 do
            screen.level(self.fill)
            local x =  self.x + (self.block_w + self.margin_w) * voice
            local y =  self.y + (self.block_h + self.margin_h) * line
            screen.rect(x, y, self.block_w, self.block_h)
            screen.fill()
        end    
    end
    screen.update()
end

return PitchGraph
