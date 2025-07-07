Grid = {
    x = 32,
    y = 13,
    rows = 10,
    columns = 21,
    block_w = 3,
    block_h = 3,
    margin_w = 1,
    margin_h = 1,
    fill = 2,
    active_fill = 15,
    voices = {
        -- active slice for each of 6 voices
        {
            start_active = 1,
            end_active = 2,
        },
        {
            start_active = 1,
            end_active = 2,
        },
        {
            start_active = 1,
            end_active = 2,
        },
        {
            start_active = 1,
            end_active = 2,
        },
            {
            start_active = 1,
            end_active = 2,
        },
        {
            start_active = 1,
            end_active = 2,
        },
    },
    
    hide = false,
}

function Grid:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- initialize; todo: prevent this overwrites anything
    -- for i = 1,6 do
    --     o.voices[i] = {
    --         start_active = 1,
    --         end_active = 2,
    --     }
    -- end

    -- return instance
    return o
end

function Grid:render()
    if self.hide then return end
    for row = 0, self.rows - 1 do
        for column = 0, self.columns - 1 do
            local idx = column + 1
            local x =  self.x + (self.block_w + self.margin_w) * column
            local y =  self.y + (self.block_h + self.margin_h) * row

            if idx >= self.voices[row + 1]['start_active'] and idx < self.voices[row+1]['end_active'] then
                -- brighten active slice 
                screen.level(self.active_fill)
            else
                screen.level(self.fill)
            end
            screen.rect(x, y, self.block_w, self.block_h)
            screen.fill()
        end
    end
end

return Grid
