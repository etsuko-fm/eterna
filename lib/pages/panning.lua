local Page = include("bits/lib/pages/Page")
local Window = include("bits/lib/graphics/Window")
local PanningCircle = include("bits/lib/graphics/PanningCircle")
local state_util = include("bits/lib/util/state")

local page_name = "Panning"
local footer
local window

local panning_graphic


local function calculate_pan_positions(state)
    for i = 0, 5 do
        local angle = (i / 6) * math.pi * 2 + state.panning_twist-- Divide full circle into 6 parts
        state.pan_positions[i+1] = state.panning_spread / 8 * math.cos(angle)
    end
    for i = 1, 6 do
        softcut.pan(i, state.pan_positions[i])
    end
end

local function adjust_spread(state, d)
    state_util.adjust_param(state, 'panning_spread', d, 1, 0, 8, false)
    calculate_pan_positions(state)

end

function adjust_twist(state, d)
    state_util.adjust_param(state, 'panning_twist', d/5, 1, 0, math.pi*2, true)
    calculate_pan_positions(state)
end



local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = adjust_spread,
    e3 = adjust_twist,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = nil,
    k3_on = nil,
    k3_off = nil,
})

function page:render(state)
    screen.clear()
    window:render()
    panning_graphic.w = state.panning_spread
    panning_graphic.twist = state.panning_twist

    panning_graphic:render()
    footer:render()
end

function page:initialize(state)
    print("panning initialized")
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "STEREO FIELD",
        font_face = state.title_font,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    -- graphics
    panning_graphic = PanningCircle:new({
        w=state.panning_spread,
    })
    footer = Footer:new({
        button_text = {
            k2 = {
                name = "LFO",
                value = "",
            },
            k3 = {
                name = "SHAPE",
                value = "",
            },
            e2 = {
                name = "WIDTH",
                value = "",
            },
            e3 = {
                name = "TWIST",
                value = "",
            },
        },
        font_face = state.footer_font,
    })
end

return page