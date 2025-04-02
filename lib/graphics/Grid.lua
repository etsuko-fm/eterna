local misc_util = include("bits/lib/util/misc")


Grid = {
    x = 32,
    y = 13,
    rows = 8,
    columns = 16,
    block_w = 3,
    block_h = 3,
    margin_w = 1,
    margin_h = 1,
    selected_idx = {}, -- set of indexes that should light up: e.g. [1] = true
    fill = 2,
    active_fill = 15,
    start_active = 1,
    end_active = 17,
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

function Grid:set(idx, active)
    self.selected[idx] = active
end

function Grid:render()
    if self.hide then return end
    for row = 0, self.rows - 1 do
        for column = 0, self.columns - 1 do
            local idx = (row * self.columns) + (column + 1)
            -- print(idx)
            local x =  self.x + (self.block_w + self.margin_w) * column
            local y =  self.y + (self.block_h + self.margin_h) * row
            if idx >= self.start_active and idx <= self.end_active then
                screen.level(self.active_fill)
            else
                screen.level(self.fill)
            end
            screen.rect(x, y, self.block_w, self.block_h)
            screen.fill()
        end    
    end
    screen.update()
end

return Grid
