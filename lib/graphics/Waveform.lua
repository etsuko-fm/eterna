Waveform = {
    x = 0,
    y = 0,
    hide = false,
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

    -- draw lines
    -- local offset = 8
    -- local line_width = self.render_samples

    -- screen.rect(x_pos - 2, self.y - offset + 1, line_width + 3, offset * 2 - 1)
    -- screen.stroke()
    -- draw waveform
    local total_samples = #self.samples
    local iter_size = math.floor(total_samples / self.render_samples)
    -- if it needs to go to 1, you might need to interpolate the table so # samples fits.. 
    local c = 0
    for i = 1, #self.samples, iter_size do
        if c < self.render_samples then
            -- sometimes iter step is .8 because not enough samples..?
            local height = math.max(1, util.round(math.abs(self.samples[i]) * self.vertical_scale))
            local brightness = math.max(1, util.round(math.abs(self.samples[i]) * self.vertical_scale))
            screen.move(x_pos, self.y - height)
            -- screen.level(self.fill_default)
            screen.level(brightness)
            -- screen.line_rel(0, 2 * height)
            screen.line_rel(0,4)
            screen.stroke()
            x_pos = x_pos + 1
            c = c + 1
        end
    end
end

return Waveform
