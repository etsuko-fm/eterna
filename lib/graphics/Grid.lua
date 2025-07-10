Grid = {
    x = 32,
    y = 16,
    rows = 10,
    columns = 21,
    block_w = 3,
    block_h = 3,
    margin_w = 1,
    margin_h = 1,
    fill = 2,
    active_fill = 15,
    sequences = {
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
    },
    hide = false,
}

function Grid:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function Grid:render()
    if self.hide then return end
    local voice
    for row = 0, self.rows - 1 do
        voice = row + 1
        for column = 0, self.columns - 1 do
            local idx = column + 1
            local x =  self.x + (self.block_w + self.margin_w) * column
            local y =  self.y + (self.block_h + self.margin_h) * row
            local step_active = self.sequences[voice][idx] == 1
            if step_active then
                -- brighten if active 
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
