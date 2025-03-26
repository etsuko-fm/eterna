local Page = include("bits/lib/pages/Page")
local Window = include("bits/lib/graphics/Window")
local state_util = include("bits/lib/util/state")

local page_name = "Slice"
local footer
local window


local page = Page:create({
    name = page_name,
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

function page:render(state)
    screen.clear()
    window:render()
    footer:render()
end

local function adjust_loop_pos(state, d)
    -- print(state.enabled_section[1] .. ',' .. state.enabled_section[2])
    state_util.adjust_param(state.enabled_section, 1, d, 1, 0, state.sample_length - state.max_sample_length)
    state_util.adjust_param(state.enabled_section, 2, d, 1, state.max_sample_length, state.sample_length)
    max_length_dirty = true
    state.events['event_randomize_softcut'] = true
end

local function adjust_loop_len(state, d)
    -- print(state.enabled_section[1] .. ',' .. state.enabled_section[2])
    state_util.adjust_param(state, 'max_sample_length', d, 0.1, 0.01, 10)
    state.enabled_section[2] = state.enabled_section[1] + state.max_sample_length
    max_length_dirty = true
    state.events['event_randomize_softcut'] = true
end


function page:initialize(state)
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "SLICE",
        font_face = state.title_font,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    -- graphics
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
                name = "SEEK",
                value = "",
            },
            e3 = {
                name = "WIDTH",
                value = "",
            },
        },
        font_face = state.footer_font,
    })
end

return page
