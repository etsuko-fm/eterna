Waveform = {
    x = 0,
    y = 0,
    hide = false,
    samples = {},
    vertical_scale = 18,
    fill_selected = 15,
    fill_default = 5,
    waveform_width = 64,
    brightness = 12,
}

function Waveform:new(o)
    o = o or {}           -- create state if not provided
    setmetatable(o, self) -- define prototype
    self.__index = self
    return o              -- return instance
end

function Waveform:render()
    if self.hide then return end
    if #self.samples == 0 then return end
    local x_pos = self.x + 1 -- stroke() draws a pixel early

    -- draw waveform
    local total_samples = #self.samples
    local iter_size = math.floor(total_samples / self.waveform_width)
    -- if it needs to go to 1, you might need to interpolate the table so # samples fits..
    local sample = 0
    for i = 1, #self.samples, iter_size do
        if sample < self.waveform_width then
            if i % 2 == 0 then
                local height = math.max(1, util.round(math.abs(self.samples[i]) * self.vertical_scale))
                -- local brightness = math.max(1, util.round(math.abs(self.samples[i]) * self.vertical_scale)) * 2
                screen.level(self.brightness)
                screen.move(x_pos, self.y - height)
                screen.line_rel(0, -1 + 2 * height)
                screen.stroke()
            else
                -- screen.move(x_pos, self.y)
                -- screen.line_rel(0, -1)

            end

            
            x_pos = x_pos + 1
            sample = sample + 1
        end
    end
    -- bounding box for debugging
    -- screen.rect(x_pos, self.y-self.vertical_scale, self.waveform_width, 2*self.vertical_scale)
    screen.stroke()
end

return Waveform
