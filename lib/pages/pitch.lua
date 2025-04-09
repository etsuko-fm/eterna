local Page = include("bits/lib/pages/Page")
local Window = include("bits/lib/graphics/Window")
local PitchGraph = include("bits/lib/graphics/PitchGraph")
local page_name = "Pitch"
local debug = include("bits/lib/util/debug")
local state_util = include("bits/lib/util/state")
local misc_util = include("bits/lib/util/misc")
local page

local PITCH_RANGE_PIXELS = 32

local function calculate_rates(state)
    for i = 0, 5 do
        local radians = i/ 6 * math.pi * 2 * 2.67
        local exp = math.sin(radians) * state.pages.pitch.rate_spread-- extend range by mult x 2
        if state.pages.pitch.quantize then
            -- quantize to integers between -2 and 2,because 2^[-2|-1|0|1|2] gives quantized rates from 0.25 to 4
            exp = math.floor(exp + 0.5)
        end
        rate = 2 ^ exp -- playback rate-to-pitch relation is exponential
        state.rates[i + 1] = state.pages.pitch.rate_center + rate
        page.pitch_graph.voice_pos[i] = util.linlin(-2,2,1,-1,state.pages.pitch.rate_center) + exp
    end
    for i = 1, 6 do
        softcut.rate(i, state.rates[i])
    end
end

local function cycle_range(state)
    local ranges = {0.1, 1, 48, 96}
    local current = state.pages.pitch.range

    -- Find index of current value
    local next_index = 1
    for i, v in ipairs(ranges) do
        if v == current then
            next_index = i + 1
            break
        end
    end

    -- Wrap around if we're past the last index
    if next_index > #ranges then
        next_index = 1
    end

    state.pages.pitch.range = ranges[next_index]
end

local function toggle_quantize(state)
    state.pages.pitch.quantize = not state.pages.pitch.quantize
    calculate_rates(state)
end


local function adjust_center(state, d)
    state_util.adjust_param(state.pages.pitch, 'rate_center', d, 1, -2, 2, false)
    calculate_rates(state)
    page.pitch_graph.center = state.pages.pitch.rate_center * -2 -- 8 - (state.pages.pitch.rate_center + 2) * 2 -- can do math here
end

local function adjust_spread(state, d)
    state_util.adjust_param(state.pages.pitch, 'rate_spread', d / 60, 1, 0, 1, false)
    calculate_rates(state)
end


page = Page:create({
    name = page_name,
    e2 = adjust_center,
    e3 = adjust_spread,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = cycle_range,
    k3_on = nil,
    k3_off = toggle_quantize,
})

function page:render(state)
    page.window:render()
    page.footer.button_text.k2.value = state.pages.pitch.range
    page.footer.button_text.k3.value = state.pages.pitch.quantize and "ON" or "OFF"
    page.footer.button_text.e2.value = misc_util.trim(tostring(state.pages.pitch.rate_center), 5)
    page.footer.button_text.e3.value = misc_util.trim(tostring(state.pages.pitch.rate_spread), 5)

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
    calculate_rates(state)
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
                name = "CNTR",
                value = "0 OCT",
            },
            e3 = {
                name = "SPRD",
                value = "",
            },
        },
        font_face = state.footer_font
    })
end

return page
