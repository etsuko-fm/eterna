local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local SliceRings = include("bits/lib/graphics/SliceRings")
local Zigzag = include("bits/lib/graphics/Zigzag")

local page_name = "SLICE RINGS"
local window

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



local page = Page:create({
    name = page_name,
    e2 = nil,
    e3 = nil,
    k2_off = nil,
    k3_off = nil,
})

local function add_params()
    params:add_separator("SLICE_RINGS", page_name)
end

function page:render()
    window:render()
    six_rings.playback_positions = {0,0,0,0,0,0}
    six_rings:render()
    zigzag_line:render()
    page.footer:render()
end

function page:initialize()
    add_params()
    zigzag_line = Zigzag:new({ x = 0, y = 28, w = 128, h = 2, zigzag_width = 2 })

    -- rings
    six_rings = SliceRings:new({
        x = 0,
        y = 0,
        enabled_section = {0,1},
        ring_luma = ring_luma,
        loop_sections = {
            {0, 1/32},
            {2/32,3/32},
            {2/6,3/6},
            {3/6,4/6},
            {4/6,5/6},
            {24/32,25/32},
        },
        hide = false,
    })

    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = page_name,
        font_face = TITLE_FONT,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    -- graphics
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "a",
                value = "",
            },
            k3 = {
                name = "b",
                value = "",
            },
            e2 = {
                name = "c",
                value = "",
            },
            e3 = {
                name = "d",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })
end

return page
