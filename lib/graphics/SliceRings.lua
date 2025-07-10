local Ring = include("bits/lib/graphics/Ring")

SliceRings = {
    x = 0,
    y = 28,
    enabled_section = {}, -- 2 values, both 0 to 1
    ring_luma = {},
    loop_sections={}, -- 6x2 values from 0 to 1
    rings = {},
    ring_radius = 5,
    playback_positions = {}, -- 0 to 1
    hide = false,
    x_offset = 16,
    y_offset = 11,
    ring_thickness = 3,
    ring_spacing = 6,
}

function SliceRings:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- initialize graphics
    local enabled_section_length = o.enabled_section[2] - o.enabled_section[1]
    local radius = 4
    for i = 1, 6, 1 do
        -- calculate x and round
        local x = self.x_offset + (i - 1) * (self.ring_radius * 2 + self.ring_spacing) + (self.ring_radius / 2) + (self.ring_thickness * 2) -- space evenly from x=24 to x=104
        x = math.floor(x + .5)
        -- calculate y and round
        local y = self.y + self.y_offset + (-2 * self.y_offset * (i % 2)) -- 3 rings above line, 3 below line
        y = math.floor(y + .5)
        o.rings[i] = Ring:new({
            x = x,
            y = y,
            thickness = self.ring_thickness,
            luma = o.ring_luma.circle.normal, -- 15 = max level
            layers = {
                {
                    -- background circle
                    a1 = 0,
                    a2 = math.pi * 2,
                    luma = o.ring_luma.circle.normal,
                    thickness = self.ring_thickness,
                    radius = radius,
                    rate = 0,
                },
                {
                    -- enabled section
                    a1 = ((o.loop_sections[i][1] - o.enabled_section[1]) / enabled_section_length) * math.pi * 2,
                    a2 = ((o.loop_sections[i][2] - o.enabled_section[2]) / enabled_section_length) * math.pi * 2,
                    luma = o.ring_luma.section_arc.normal,
                    thickness = self.ring_thickness,
                    radius = radius,
                    rate = 0,
                },
                -- {
                --     -- playback rate arc
                --     a1 = 0,
                --     a2 = math.pi * 2,
                --     luma = o.ring_luma.rate_arc.normal, -- brightness, 0-15
                --     thickness = self.ring_thickness,                    -- pixels
                --     radius = radius,                       -- pixels
                --     rate = 0                          -- playback_rates[i] / 10,
                -- },
            }
        })
    end


    -- return instance
    return o
end

function SliceRings:calc_a1(i)
    local enabled_section_length = self.enabled_section[2] - self.enabled_section[1]
    return  ((self.loop_sections[i][1] - self.enabled_section[1]) / enabled_section_length) * math.pi * 2
end

function SliceRings:calc_a2(i)
    local enabled_section_length = self.enabled_section[2] - self.enabled_section[1]
    return  ((self.loop_sections[i][2] - self.enabled_section[1]) / enabled_section_length) * math.pi * 2
end


function SliceRings:render()
    if self.hide then return end
    for i = 1, 6 do
        if self.playback_positions[i] ~= nil then
            -- convert phase to radians
            local pos_radians = self.playback_positions[i] * math.pi * 2
            
            -- draw enabled section
            self.rings[i].layers[2].a1 = self:calc_a1(i)
            self.rings[i].layers[2].a2 = self:calc_a2(i)

            -- draw playback cursor
            -- self.rings[i].layers[3].a1 = pos_radians - (math.pi / 16)
            -- self.rings[i].layers[3].a2 = pos_radians

            self.rings[i]:render()
        end
    end

end

function SliceRings:initialize()
    screen.update()
end

return SliceRings