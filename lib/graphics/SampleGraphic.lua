SampleGraphic = {
    slice_len = 1,
    num_slices = 1,
    -- 1-based indexes of each active slice; always successive, e.g. {29,30,31,32,1,2}
    active_slices = {},
    hide = false,
    width = 64,
    x = 32,
    waveform_graphics = {},
    num_channels = 1,
    voice_env = { 0, 0, 0, 0, 0, 0, }, -- realtime envelope level of each voice
    voice_mapping = {}, -- which voice is mapped to which channel
}

function SampleGraphic:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    for n = 1, 6 do
        -- upto 6 waveforms, 1 for each buffer
        self.waveform_graphics[n] = Waveform:new({
            x = self.x,
            y = 20,
            waveform_width = self.width - 1,
            vertical_scale = 9,
            half = false
        })
    end

    return o
end

local w = 64
local y = 44

local level_faint = 2
local level_bright = 4
local level_trigger = 15


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

function SampleGraphic:render()
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
            self.waveform_graphics[i].y = min_y + rect_midpoint_y(box_height, scale * 2, self.num_channels, i)
            self.waveform_graphics[i].vertical_scale = scale
        else
            self.waveform_graphics[i].hide = true
        end
    end

    for i = 1, 6 do
        -- render all waveforms; if they're not active, 
        -- their .hide property will prevent resource usage
        self.waveform_graphics[i]:render()
    end

    -- map envelope index to slice index;
    -- e.g., active slices may be {3,4,5,6,7,8}
    -- this mapping returns 3 for slice_to_env[1].
    local slice_to_env = {}
    for env_i = 1, 6 do
        local slice_index = self.active_slices[env_i]
        slice_to_env[slice_index] = env_i
    end

    for n = 0, self.num_slices - 1 do
        local index = n + 1
        local env_i = slice_to_env[index]
        if env_i then
            local mod = self.voice_env[env_i] or 0
            graphic_util.screen_level(level_bright, mod * (level_trigger-level_bright))
        else
            screen.level(level_faint)
        end

        -- draw a line under the waveform for each available slice
        local startx = self.x + (w * self.slice_len * n)
        local rect_w = w * self.slice_len - 1
        screen.rect(startx, y, rect_w, 1)
        screen.fill()

        -- indicate starting slice with a little dot, if user selected between 2 and 6 slices
        if self.num_slices <= 6 and self.num_slices > 1 and index == self.active_slices[1] then
            screen.level(5)
            screen.rect(startx, y, 1, 1)
        end
        screen.fill()
    end
end

return SampleGraphic
