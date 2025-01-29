local Ring = include("bits/lib/graphics/Ring")

SixRings = {
    x = 0,
    y = 0,
    enabled_section = {},
    ring_luma = {},
    loop_sections={},
    rings = {},
    playback_positions = {},
    hide = false,
    y_offset = 12,
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
            x = i * 16 + 8,                                -- space evenly from x=24 to x=104
            y = 32 + o.y_offset + (-2 * o.y_offset * (i % 2)), -- 3 rings above line, 3 below line
            radius = 6,
            thickness = 3,
            luma = o.ring_luma.circle.normal, -- 15 = max level
            layers = {
                {
                    -- background circle
                    a1 = 0,
                    a2 = math.pi * 2,
                    luma = o.ring_luma.circle.normal,
                    thickness = 3,
                    radius = 6,
                    rate = 0,
                },
                {
                    -- enabled section
                    a1 = ((o.loop_sections[i][1] - o.enabled_section[1]) / enabled_section_length) * math.pi * 2,
                    a2 = ((o.loop_sections[i][2] - o.enabled_section[2]) / enabled_section_length) * math.pi * 2,
                    luma = o.ring_luma.section_arc.normal,
                    thickness = 3,
                    radius = 6,
                    rate = 0,
                },
                {
                    -- playback rate arc
                    a1 = 0,
                    a2 = math.pi * 2,
                    luma = o.ring_luma.rate_arc.normal, -- brightness, 0-15
                    thickness = 3,                    -- pixels
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
    local y_offset = 12

    local enabled_section_length = self.enabled_section[2] - self.enabled_section[1]
    for i = 1, 6 do
        if self.playback_positions[i] ~= nil then
            local pos_radians = self.playback_positions[i] * math.pi * 2 -- convert phase to radians
            self.rings[i].layers[3].a1 = pos_radians
            -- 1/32 of a circle as a nice slice length (full circle in radians = 2*PI)
            self.rings[i].layers[3].a2 = pos_radians + (math.pi / 16)
            self.rings[i].layers[2].a1 = self:calc_a1(i)
            self.rings[i].layers[2].a2 = self:calc_a2(i)

            self.rings[i]:render()
        end
    end

end

function SixRings:initialize()
    screen.update()
end

return SixRings
