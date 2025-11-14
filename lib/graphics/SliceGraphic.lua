SliceGraphic = {
    slice_len = 1,
    num_slices=1,
    active_slices = {}, -- 1-based indexes of each active slice
    hide = false,
    width=64,
    x = 32,
    waveform_graphics = {},
    num_channels = 1,
}

function SliceGraphic:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    for n = 1,6 do
        -- upto 6 waveforms, 1 for each buffer
        self.waveform_graphics[n] = Waveform:new({
            x = self.x,
            y = 20,
            waveform_width = self.width-1,
            vertical_scale = 9,
            half=false
        })
    end

    -- return instance
    return o
end

local w = 64
local y = 44

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

local function rect_midpoint_y(box_height, rect_h, num_rects, idx)
    local spacing = (box_height - num_rects * rect_h) / (num_rects + 1)
    local top_y = spacing * idx + rect_h * (idx - 1)
    local midpoint = top_y + rect_h / 2
    return midpoint
end

function SliceGraphic:render()
    if self.hide then return end

    local box_height = 33
    local min_y = 10
    local spacing = 1

    local total_spacing = (self.num_channels - 1) * spacing

    -- each waveform has a scale property, which relates to its height by scale*2
    -- calculate the maximum scale based on the size of the bounding box and the 
    -- number of channels that should fit
    local max_scale = math.floor((box_height - total_spacing) / self.num_channels / 2)
    local scale = util.clamp(max_scale, 2, 8)

    for i = 1, 6 do
        if i <= self.num_channels then
            self.waveform_graphics[i].hide = false
            self.waveform_graphics[i].y = min_y + rect_midpoint_y(box_height, scale*2, self.num_channels, i)
            self.waveform_graphics[i].vertical_scale = scale
        else
            self.waveform_graphics[i].hide = true
        end
    end 

    for i=1,6 do
        self.waveform_graphics[i]:render()
    end

    -- print(self.active_slices[1])
    for n=0, self.num_slices - 1 do
        local index = n + 1
        if contains(self.active_slices, index) then
            screen.level(level_bright)
        else
            screen.level(level_faint)
        end
        -- draw a line under the waveform for each available slice
        local startx = self.x + (w * self.slice_len * n)
        local rect_w = w * self.slice_len - 1
        screen.rect(startx, y,  rect_w, 1)
        screen.fill()

        -- indicate starting slice if between 2 and 6 slices
        if self.num_slices <= 6 and self.num_slices > 1 and index == self.active_slices[1] then
            screen.level(5)
            screen.rect(startx, y,  1, 1)
        end
        screen.fill()

    end
end

return SliceGraphic
