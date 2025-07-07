local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local state_util = include("bits/lib/util/state")
local GridGraphic = include("bits/lib/graphics/Grid")
local Footer = include("bits/lib/graphics/Footer")
local misc_util = include("bits/lib/util/misc")
local perlin = include("bits/lib/ext/perlin")
local page_name = "SLICE"
local window
local grid_graphic
local DEFAULT_PERIOD = 6
local ROWS = 6
local COLUMNS = 16
local MAX_SLICES = COLUMNS

local PARAM_ID_LFO_ENABLED = "slice_lfo_enabled"

local POSITION_MIN = 0
local POSITION_MAX = 1 -- represents a scan position that in turn sets all 6 playheads

local controlspec_pos = controlspec.def {
    min = POSITION_MIN, -- the minimum value
    max = POSITION_MAX, -- the maximum value
    warp = 'lin',       -- a shaping option for the raw value
    step = .01,        -- output value quantization
    default = 0,      -- default value
    units = '',         -- displayed on PARAMS UI
    quantum = .01,     -- each delta will change raw value by this much
    wrap = false         -- wrap around on overflow (true) or clamp (false)
}


local function action_perlin_x(v)
end

local function action_perlin_y(v)
end

local function action_nav_x(v)
end

local function action_nav_y(v)
end

local function action_toggle(v)
end


local function e2(state, d)
end

local function e3(state, d)
end

local function toggle_step(state)
end

local function toggle_perlin(state)
end


local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = e2,
    e3 = e3,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = toggle_step,
    k3_on = nil,
    k3_off = toggle_perlin,
})

function page:render(state)
    window:render()
    grid_graphic:render()

    if state.pages.slice.lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        page.footer.button_text.k2.value = "ON"
        page.footer.button_text.e2.name = "RATE"
        page.footer.button_text.e2.value = misc_util.trim(tostring(state.pages.slice.lfo:get('period')), 5)
    else
        -- When LFO is disabled, E2 controls position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "POS"
        page.footer.button_text.e2.value = misc_util.trim(tostring(params:get(PARAM_ID_POS)), 5)
    end

    page.footer.button_text.k3.value = string.upper(state.pages.slice.lfo:get("shape"))
    page.footer.button_text.e3.value = params:get(PARAM_ID_LENGTH)

    page.footer:render()
end

local function add_params(state)
    params:add_separator("SLICE", page_name)
end

function page:initialize(state)
    add_params(state)
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "SEQUENCER",
        font_face = state.title_font,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    grid_graphic = GridGraphic:new({
        rows = ROWS,
        columns = COLUMNS,
    })
    -- graphics
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "TOGGLE",
                value = "",
            },
            k3 = {
                name = "PERLIN",
                value = "",
            },
            e2 = {
                name = "X",
                value = state.pages.slice.seek.start,
            },
            e3 = {
                name = "Y",
                value = state.pages.slice.seek.width,
            },
        },
        font_face = state.footer_font,
    })
    state.pages.slice.lfo:set('reset_target', 'mid: rising')
end

return page
