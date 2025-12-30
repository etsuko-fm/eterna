local GraphicBase = require(from_root("lib/graphics/GraphicBase"))

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
    parent = {},
}

setmetatable(Waveform, { __index = GraphicBase })

function Waveform:set(key, value)
  if self[key] ~= value then
    self[key] = value
    self.parent.changed = true
  end
end

function Waveform:clear()
    self:set('samples', {})
end

function Waveform:render()
    if self.hide or #self.samples == 0 then return end

    local x_pos = self.x + 1 -- stroke() draws a pixel early

    -- define step size, for when if num samples > required waveform width
    local step = math.floor(#self.samples / self.waveform_width)

    local sample = 0
    screen.level(self.brightness)

    for i = 1, #self.samples, step do
        if sample < self.waveform_width then
            if i % 2 == 0 then
                local height = math.max(1, util.round(math.abs(self.samples[i]) * self.vertical_scale))
                screen.move(x_pos, self.y - height)
                screen.line_rel(0, -1 + 2 * height)
                screen.stroke()
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
