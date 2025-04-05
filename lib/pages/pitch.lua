local Page = include("bits/lib/pages/Page")
local Window = include("bits/lib/graphics/Window")
local PitchGraph = include("bits/lib/graphics/PitchGraph")
local page_name = "Pitch"
local page_disabled = false
local debug = include("bits/lib/util/debug")
local state_util = include("bits/lib/util/state")



local page = Page:create({
    name = page_name,
    e2 = nil,
    e3 = nil,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = nil,
    k3_on = nil,
    k3_off = nil,
})

function page:render(state)
    screen.clear()
    page.window:render()
    page.pitch_graph:render()
    page.footer:render()
end

function page:initialize(state)
    page.window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "PITCH",
        font_face = state.title_font,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })

    page.pitch_graph = PitchGraph:new()

    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "RANGE",
                value = "6 oct",
            },
            k3 = {
                name = "QUANT",
                value = "12", -- [N] SEMITONES, OCTAVES, FREE
            },
            e2 = {
                name = "BASE",
                value = "0 OCT",
            },
            e3 = {
                name = "SPRD",
                value = "",
            },
        },
        font_face=state.footer_font
    })
end

return page
