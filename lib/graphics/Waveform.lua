Waveform = {
    x = 0,
    y = 0,
    hide = false,
    sample_length = 0, -- seconds
    highlight = true,
    samples = {},
    vertical_scale = 1,
    fill_selected = 15,
    fill_default = 5,
    render_samples = 16,
}

function Waveform:new(o)
    o = o or {} -- create state if not provided
    setmetatable(o, self) -- define prototype
    self.__index = self
    return o -- return instance
end

function Waveform:render()
    if self.hide then return end
    if #self.samples == 0 then return end
    local x_pos = self.x

    -- sample_length refers to the total length in seconds of the sample. 

    -- draw lines
    local offset = 14
    local line_width = 59

    screen.rect(x_pos - 2, self.y - offset + 1, line_width + 3, offset * 2)
    screen.stroke()
    -- draw waveform
    local total_samples = #self.samples
    local iter_size = math.floor(total_samples / self.render_samples)

    for i = 1, #self.samples, iter_size do  -- step size of 2
        local height = util.round(math.abs(self.samples[i]) * self.vertical_scale)
        screen.move(x_pos, self.y - height)
        screen.level(self.fill_default)
        screen.line_rel(0, 2 * height)
        screen.stroke()
        x_pos = x_pos + 1
    end
end

return Waveform
