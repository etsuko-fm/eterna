local Page = include("bits/lib/pages/Page")
local Ring = include("bits/lib/graphics/Ring")
local Zigzag = include("bits/lib/graphics/Zigzag")

local rings = {}
local zigzag_line = nil

local ring_luma = {
    -- todo: could these be properties of the ring?
    -- so add when initializing
    circle = {
        normal = 2,
    },
    rate_arc = {
        normal = 15,
    },
    section_arc = {
        normal = 5,
    },
}

local function create_rings(state)
    local y_offset = 18
    zigzag_line = Zigzag:new({ 0, 32, 128, 4, 4 })
    local enabled_section_length = state.enabled_section[2] - state.enabled_section[1]
    for i = 1, 6, 1 do
        rings[i] = Ring:new({
            x = i * 16 + 8,                                -- space evenly from x=24 to x=104
            y = 32 + y_offset + (-2 * y_offset * (i % 2)), -- 3 rings above line, 3 below line
            radius = 6,
            thickness = 3,
            luma = ring_luma.circle.normal, -- 15 = max level
            layers = {
                {
                    -- background circle
                    a1 = 0,
                    a2 = math.pi * 2,
                    luma = ring_luma.circle.normal,
                    thickness = 3,
                    radius = 6,
                    rate = 0,
                },
                {
                    -- enabled section
                    a1 = ((state.loop_sections[i][1] - state.enabled_section[1]) / enabled_section_length) * math.pi * 2,
                    a2 = ((state.loop_sections[i][2] - state.enabled_section[2]) / enabled_section_length) * math.pi * 2,
                    luma = ring_luma.section_arc.normal,
                    thickness = 3,
                    radius = 6,
                    rate = 0,
                },
                {
                    -- playback rate arc
                    a1 = 0,
                    a2 = math.pi * 2,
                    luma = ring_luma.rate_arc.normal, -- brightness, 0-15
                    thickness = 3,                    -- pixels
                    radius = 6,                       -- pixels
                    rate = 0                          -- playback_rates[i] / 10,
                },
            }
        })
    end
end

local page = Page:create({
    name = "Main",
    e1 = nil,
    e2 = nil,
    e3 = nil,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = nil,
    k3_on = nil,
    k3_off = nil,
})

function page:initialize(state)
    create_rings(state)
end

function page:render(state)
    screen.clear()
    local enabled_section_length = state.enabled_section[2] - state.enabled_section[1]

    for i = 1, 6 do
        if state.playback_positions[i] ~= nil then
            local pos_radians = state.playback_positions[i] * math.pi * 2 -- convert phase to radians
            rings[i].layers[3].a1 = pos_radians
            -- 1/32 of a circle as a nice slice length (full circle in radians = 2*PI)
            rings[i].layers[3].a2 = pos_radians + (math.pi / 16)
            rings[i].layers[2].a1 = ((state.loop_sections[i][1] - state.enabled_section[1]) / enabled_section_length) * math.pi * 2
            rings[i].layers[2].a2 = ((state.loop_sections[i][2] - state.enabled_section[2]) / enabled_section_length) * math.pi * 2

            rings[i]:render()
        end
    end

    if zigzag_line then
        zigzag_line:render()
    end
end

return page
