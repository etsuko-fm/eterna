local Page = include("bits/lib/pages/Page")
local Ring = include("bits/lib/graphics/Ring")
local Zigzag = include("bits/lib/graphics/Zigzag")
local Window = include("bits/lib/graphics/Window")
local Footer = include("bits/lib/graphics/Footer")
local SixRings = include("bits/lib/graphics/SixRings")

local rings = {}
local zigzag_line
local window
local footer
local six_rings

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
    -- todo: should be a graphic
    zigzag_line = Zigzag:new({ x = 0, y = 32, w = 128, h = 4, zigzag_width = 4 })
    local y_offset = 12
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
    -- window
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "VOICES",
        font_face = state.title_font,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    -- footer
    footer = Footer:new({
        k2 = "RANDM",
        k3 = "MUTE",
        e2 = "SEEK",
        e3 = "LENGT",
        font_face = state.default_font
    })
    -- rings
    six_rings = SixRings:new({
        x = 0,
        y = 0,
        enabled_section = state.enabled_section,
        ring_luma = ring_luma,
        loop_sections = state.loop_sections,
        hide = false,
    })
    -- create_rings(state)
end

function page:render(state)
    screen.clear()
    window:render()
    footer:render()

    if zigzag_line then
        zigzag_line:render()
    end
end

return page
