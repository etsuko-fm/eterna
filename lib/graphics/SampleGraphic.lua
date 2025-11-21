local Waveform = include(from_root("lib/graphics/Waveform"))

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
    voice_to_buffer = {},                -- maps voice (key) to buffer (value)
    is_playing = nil,
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

local level_faint = 0
local level_bright = 1
local level_trigger = 4


local function rect_midpoint_y(box_height, rect_h, num_rects, idx)
    local spacing = (box_height - num_rects * rect_h) / (num_rects + 1)
    local top_y = math.floor(spacing) * idx + rect_h * (idx - 1)
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
    local waveform_midpoints = {}

    for i = 1, 6 do
        local slice = self.active_slices[i]
        if i <= self.num_channels then
            self.waveform_graphics[i].hide = false
            waveform_midpoints[i] = min_y + rect_midpoint_y(box_height, scale * 2, self.num_channels, i)
            self.waveform_graphics[i].y = waveform_midpoints[i]
            self.waveform_graphics[i].vertical_scale = scale
        else
            self.waveform_graphics[i].hide = true
        end

        -- draw which waveform slice is playing
        local mod = self.voice_env[i] or 0
        graphic_util.screen_level(level_bright, mod * (level_trigger - level_bright), 0)
        local buffer_idx = self.voice_to_buffer[i]
        if buffer_idx and waveform_midpoints[buffer_idx] then
            local startx = self.x + (w * self.slice_len * (slice-1))
            local rect_w = w * self.slice_len - 1
            screen.blend_mode(13)
            screen.rect(startx, waveform_midpoints[buffer_idx] + scale - 1, rect_w, -scale * 2 + 1)
            screen.fill()
            screen.blend_mode(0)
        end
    end

    for i = 1, 6 do
        -- render all waveforms; if they're not active,
        -- their .hide property will prevent resource usage
        self.waveform_graphics[i]:render()
    end

    for slice = 1, self.num_slices do
        local zero_index = slice - 1

        -- draw a line under the waveform for each available slice
        local startx = self.x + (w * self.slice_len * zero_index)
        local rect_w = w * self.slice_len - 1

        screen.rect(startx, y, rect_w, 1)
        screen.fill()
        -- indicate starting slice with a little dot, if user selected between 2 and 6 slices
        -- if self.num_slices <= 6 and self.num_slices > 1 and slice == self.active_slices[1] then
        --     screen.level(5)
        --     screen.rect(startx, y, 1, 1)
        --     screen.fill()
        -- end
    end
end

return SampleGraphic
