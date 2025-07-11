SliceGraphic = {
    num_slices=6, -- number of slices sample is divided into
    slice_start=1, -- first active slice (1-32)
    slice_end=6, -- last active slice (1-32)
    slice_len=1, -- slice length as fraction of 1, where 1 represents entire sample
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

function SliceGraphic:render()
    if self.hide then return end

    local slice_len = 1/self.num_slices

    screen.level(2)
    for n=0, self.num_slices - 1 do
        if n + 1 >= self.slice_start and n + 1 < self.slice_start + 6 then
            screen.level(level_bright)
        else
            screen.level(level_faint)
        end
        -- draw a line under the waveform for each available slice
        local startx = x + (w * slice_len * n)
        local rect_w = w * slice_len - 1
        screen.rect(startx, y,  rect_w, 3)
        screen.fill()
    end

end

return SliceGraphic
