local Page = include("bits/lib/pages/Page")
local Window = include("bits/lib/graphics/Window")
local Footer = include("bits/lib/graphics/Footer")
local SixRings = include("bits/lib/graphics/SixRings")

local zigzag_line
local window
local six_rings


local ring_luma = {
    -- todo: could these be properties of the ring?
    -- so add when initializing
    circle = {
        normal = 1,
    },
    rate_arc = {
        normal = 15,
    },
    section_arc = {
        normal = 5,
    },
}

local function mute(state)
    if state.muted then audio.level_cut(1) else audio.level_cut(0) end
    state.muted = not state.muted
    print("mute: " .. tostring(state.muted))
end

local function update_softcut(state)
    state.events['event_update_softcut'] = true
end

local page = Page:create({
    name = "Main",
    e1 = nil,
    e2 = nil,
    e3 = nil,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = update_softcut,
    k3_on = nil,
    k3_off = mute,
})

function page:initialize(state)
    -- window
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "MICRO LOOPS",
        font_face = state.title_font,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    -- footer
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "RESET",
                value = "",
            },
            k3 = {
                name = "MUTE",
                value = "",
            },
            e2 = {
                name = "SIZE",
                value = "",
            },
            e3 = {
                name = "RANGE",
                value = "",
            },
        },
        font_face = state.footer_font
    })

    -- rings
    six_rings = SixRings:new({
        x = 0,
        y = 0,
        enabled_section = state.pages.slice.enabled_section,
        ring_luma = ring_luma,
        loop_sections = state.loop_sections,
        hide = false,
    })
end

function page:render(state)
    window:render()
    six_rings.playback_positions = state.pages.slice.playback_positions
    six_rings:render()
    if zigzag_line then
        zigzag_line:render()
    end
    page.footer:render()
end

return page
