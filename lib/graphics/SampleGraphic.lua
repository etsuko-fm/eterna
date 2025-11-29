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
    voice_to_buffer = {},              -- maps voice (key) to buffer (value)
    is_playing = nil,
    waveform_midpoints = {},
    sample_duration = nil,
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

function SampleGraphic:render_slice_stripes(ypos)
    for slice = 1, self.num_slices do
        local zero_index = slice - 1

        -- draw a line under the waveform for each available slice
        local startx = self.x + (w * self.slice_len * zero_index)
        local rect_w = w * self.slice_len - 1

        screen.rect(startx, ypos, rect_w, 1)
        screen.fill()
        -- indicate starting slice with a little dot, if user selected between 2 and 6 slices
        if self.num_slices <= 6 and self.num_slices > 1 and slice == self.active_slices[1] then
            screen.level(5)
            screen.rect(startx, ypos, 1, 1)
            screen.fill()
        end
    end
end

function SampleGraphic:render_trigger_flash(index, flash_x, flash_y, flash_w, flash_h)
    -- flash which waveform slice is playing
    -- get buffer id based on current voice index
    local buffer_idx = self.voice_to_buffer[index]
    if buffer_idx and self.waveform_midpoints[buffer_idx] then
        -- brightness of flash based on position of envelope
        local mod = self.voice_env[index] or 0
        graphic_util.screen_level(level_bright, mod * (level_trigger - level_bright), 0)
        screen.blend_mode(13)
        screen.rect(flash_x, flash_y, flash_w, flash_h)
        screen.fill()
        screen.blend_mode(0)
    end
end

function SampleGraphic:render(render_slices)
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
    self.waveform_midpoints = {}

    for i = 1, 6 do
        if i <= self.num_channels then
            self.waveform_graphics[i].hide = false
            self.waveform_midpoints[i] = min_y + rect_midpoint_y(box_height, scale * 2, self.num_channels, i)
            self.waveform_graphics[i].y = self.waveform_midpoints[i]
            self.waveform_graphics[i].vertical_scale = scale
        else
            self.waveform_graphics[i].hide = true
        end
        if render_slices and self.slice_len then
            local slice = self.active_slices[i]
            local buffer_idx = self.voice_to_buffer[i]
            local flash_x = self.x + (w * self.slice_len * (slice - 1))
            local flash_y = self.waveform_midpoints[buffer_idx] + scale - 1
            local flash_w = w * self.slice_len - 1
            local flash_h = -scale * 2 + 1
            self:render_trigger_flash(i, flash_x, flash_y, flash_w, flash_h)
        end
    end

    for i = 1, 6 do
        -- render all waveforms; if they're not active,
        -- their .hide property will prevent resource usage
        self.waveform_graphics[i]:render()
    end

    if render_slices then
        local margin = 2
        local ypos = self.waveform_midpoints[self.num_channels] + scale + margin
        -- alternative: just use the y var local to this module
        self:render_slice_stripes(ypos)
    end
end

return SampleGraphic
