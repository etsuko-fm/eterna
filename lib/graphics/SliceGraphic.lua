SliceGraphic = {
    slice_len = 1,
    num_slices=1,
    active_slices = {}, -- 1-based indexes of each active slice
    hide = false,
}

function SliceGraphic:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

local w = 64
local x = 32
local y = 40

local level_faint = 2
local level_bright = 15

local function contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

function SliceGraphic:render()
    if self.hide then return end
    -- print(self.active_slices[1])
    for n=0, self.num_slices - 1 do
        local index = n + 1
        if contains(self.active_slices, index) then
            screen.level(level_bright)
        else
            screen.level(level_faint)
        end
        -- draw a line under the waveform for each available slice
        local startx = x + (w * self.slice_len * n)
        local rect_w = w * self.slice_len - 1
        screen.rect(startx, y,  rect_w, 1)
        screen.fill()
        if self.num_slices <= 6 and self.num_slices > 1 and index == self.active_slices[1] then
            screen.level(5)
            screen.rect(startx + rect_w/2, y,  1, 1)
        end
        screen.fill()

    end
end

return SliceGraphic
