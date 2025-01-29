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
    six_rings:render()
    six_rings.playback_positions = state.playback_positions
    if zigzag_line then
        zigzag_line:render()
    end
end

return page
