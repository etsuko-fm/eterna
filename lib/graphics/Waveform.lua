Waveform = {
    x = 0,
    y = 0,
    w = 128,
    hide = false,
    sample_length = 0, -- seconds
    highlight = true,
    enabled_section = {
        nil,  -- start, in seconds
        nil,  -- end
    },
    samples = {},
    vertical_scale = 1,
    fill_selected = 15,
    fill_default = 5,
}

function Waveform:new(o)
    o = o or {} -- create state if not provided
    setmetatable(o, self) -- define prototype
    self.__index = self
    return o -- return instance
end

function Waveform:render()
    if self.hide then return end

    local x_pos = self.x

    -- sample_length refers to the total length in seconds of the sample. 
    -- the enabled_section table contains 2 values (start and end pos, in seconds) of the slice  of the total sample,
    -- that can be used by the 6 softcut voices - those will play a slice of that slice. 
    -- to highlight that section in the waveform, the seconds need to be converted to a sample index.

    local enabled_sample_idx_start
    local enabled_sample_idx_end

    if self.highlight then
        enabled_sample_idx_start = math.floor(util.linlin(0, self.sample_length, 0, self.w, self.enabled_section[1]))
        enabled_sample_idx_end = math.floor(util.linlin(0, self.sample_length, 0, self.w, self.enabled_section[2]))
    end

    for i, s in ipairs(self.samples) do
        local height = util.round(math.abs(s) * self.vertical_scale)
        screen.move(x_pos, self.y - height)


        if self.highlight and i >= enabled_sample_idx_start and i <= enabled_sample_idx_end then
            -- brighten the selected part of the waveform 
            -- todo: this should be based on the number of seconds, not pixels
            screen.level(self.fill_selected)
        else
            screen.level(self.fill_default)
        end
        screen.line_rel(0, 2 * height)
        screen.stroke()
        x_pos = x_pos + 1
    end

    -- screen.update()
end

return Waveform
