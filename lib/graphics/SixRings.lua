local Ring = include("bits/lib/graphics/Ring")

SixRings = {
    x = 0,
    y = 28,
    enabled_section = {},
    ring_luma = {},
    loop_sections={},
    rings = {},
    ring_radius = 6,
    playback_positions = {},
    hide = false,
    x_offset = 16,
    y_offset = 8,
    ring_thickness = 3,
    ring_spacing = 5,

}

function SixRings:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- initialize graphics
    local enabled_section_length = o.enabled_section[2] - o.enabled_section[1]
    for i = 1, 6, 1 do
        o.rings[i] = Ring:new({
            x = self.x_offset + (i - 1) * (self.ring_radius * 2 + self.ring_spacing) + (self.ring_radius / 2) + (self.ring_thickness * 2), -- space evenly from x=24 to x=104
            y = self.y + self.y_offset + (-2 * self.y_offset * (i % 2)), -- 3 rings above line, 3 below line
            thickness = self.ring_thickness,
            luma = o.ring_luma.circle.normal, -- 15 = max level
            layers = {
                {
                    -- background circle
                    a1 = 0,
                    a2 = math.pi * 2,
                    luma = o.ring_luma.circle.normal,
                    thickness = self.ring_thickness,
                    radius = 6,
                    rate = 0,
                },
                {
                    -- enabled section
                    a1 = ((o.loop_sections[i][1] - o.enabled_section[1]) / enabled_section_length) * math.pi * 2,
                    a2 = ((o.loop_sections[i][2] - o.enabled_section[2]) / enabled_section_length) * math.pi * 2,
                    luma = o.ring_luma.section_arc.normal,
                    thickness = self.ring_thickness,
                    radius = 6,
                    rate = 0,
                },
                {
                    -- playback rate arc
                    a1 = 0,
                    a2 = math.pi * 2,
                    luma = o.ring_luma.rate_arc.normal, -- brightness, 0-15
                    thickness = self.ring_thickness,                    -- pixels
                    radius = 6,                       -- pixels
                    rate = 0                          -- playback_rates[i] / 10,
                },
            }
        })
    end


    -- return instance
    return o
end

function SixRings:calc_a1(i)
    local enabled_section_length = self.enabled_section[2] - self.enabled_section[1]
    return  ((self.loop_sections[i][1] - self.enabled_section[1]) / enabled_section_length) * math.pi * 2
end

function SixRings:calc_a2(i)
    local enabled_section_length = self.enabled_section[2] - self.enabled_section[1]
    return  ((self.loop_sections[i][2] - self.enabled_section[1]) / enabled_section_length) * math.pi * 2
end


function SixRings:render()
    if self.hide then return end
    for i = 1, 6 do
        if self.playback_positions[i] ~= nil then
            -- convert phase to radians
            local pos_radians = self.playback_positions[i] * math.pi * 2
            
            -- draw enabled section
            self.rings[i].layers[2].a1 = self:calc_a1(i)
            self.rings[i].layers[2].a2 = self:calc_a2(i)

            -- draw playback cursor
            self.rings[i].layers[3].a1 = pos_radians - (math.pi / 16)
            self.rings[i].layers[3].a2 = pos_radians

            self.rings[i]:render()
            -- screen.move(0, 12*i)
            -- screen.text(self.playback_positions[i])
        end
    end

end

function SixRings:initialize()
    screen.update()
end

return SixRings
