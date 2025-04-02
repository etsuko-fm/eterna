local Page = include("bits/lib/pages/Page")
local Window = include("bits/lib/graphics/Window")
local state_util = include("bits/lib/util/state")
local GridGraphic = include("bits/lib/graphics/Grid")
local Footer = include("bits/lib/graphics/Footer")

local page_name = "Slice"
local window
local grid_graphic

local function update_grid(state)
    grid_graphic.start_active = state.pages.slice.seek.start
    grid_graphic.end_active = state.pages.slice.seek.start + state.pages.slice.seek.width
end

local function seek(state, d)
    state_util.adjust_param(state.pages.slice.seek, 'start', 1, d, 1, 128)
    update_grid(state)
end

local function adjust_width(state, d)
    state_util.adjust_param(state.pages.slice.seek, 'width', 1, d, 1, 128)
    update_grid(state)
end

local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = seek,
    e3 = adjust_width,
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
    grid_graphic:render()
    page.footer.button_text.e2.value = state.pages.slice.seek.start
    page.footer.button_text.e3.value = state.pages.slice.seek.width

    page.footer:render()
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
    grid_graphic = GridGraphic:new()
    -- graphics
    page.footer = Footer:new({
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
                value = state.pages.slice.seek.start,
            },
            e3 = {
                name = "WIDTH",
                value = state.pages.slice.seek.width,
            },
        },
        font_face = state.footer_font,
    })
end

return page
