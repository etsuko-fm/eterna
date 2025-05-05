local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local PitchGraph = include("bits/lib/graphics/PitchGraph")
local page_name = "Playback"
local debug = include("bits/lib/util/debug")
local state_util = include("bits/lib/util/state")
local misc_util = include("bits/lib/util/misc")
local page

local function add_params(state)
    -- params:add_group('playback_rates', 'playback rates', 5)

    params:add_separator("PLAYBACK_RATES", "PLAYBACK RATES")
    params:add_binary('quantize', 'Quantize', "toggle", state.pages.pitch.quantize and 1 or 0)
    params:add_number("rate_center", "center", -3, 3, state.pages.pitch.rate_center)
    params:add_number("rate_spread", "spread", -3, 3, state.pages.pitch.rate_spread)
    local p = {"FWD", "REV", "FWD_REV"}
    params:add_option("direction", "direction", p, 1)

    -- direction = PLAYBACK_DIRECTION["FWD_REV"],
end

local function calculate_rates(state)
    for i = 0, 5 do
        local radians = i / 6 * math.pi * 2 * 2.67 -- manually tuned, 2.7 is also nice

        -- here pitch is not a meaningful value yet; it's _some_ ratio of the normal playback pitch, with 0 = original pitch
        local pitch = math.sin(radians) * state.pages.pitch.rate_spread

        -- double to increase range, we'll use half the range for reverse playback (-4 < pitch < 0) and half for forward (0 < pitch < 4)
        pitch = pitch * 2
        pitch = pitch + state.pages.pitch.rate_center

        if state.pages.pitch.quantize then
            -- quantize to integers between -2 and 2,because 2^[-2|-1|0|1|2] gives quantized rates from 0.25 to 4
            pitch = math.floor(pitch + 0.5)
        end

        local rate = util.clamp(2 ^ pitch, 1 / 8, 8)


        if page.pitch_graph.voice_dir[i] == PLAYBACK_DIRECTION["REV"] then
            -- reverse playback
            rate = -rate
        end
        state.softcut.rates[i + 1] = rate
        -- graph is linear while rate is exponential 
        page.pitch_graph.voice_pos[i] = -math.log(math.abs(rate), 2)
    end
    for i = 1, 6 do
        softcut.rate(i, state.softcut.rates[i])
    end
end

local function update_playback_dir(state)
    if state.pages.pitch.direction == PLAYBACK_DIRECTION["FWD"] then
        for i = 1, 6 do
            page.pitch_graph.voice_dir[i] = PLAYBACK_DIRECTION["FWD"]
        end
    elseif state.pages.pitch.direction == PLAYBACK_DIRECTION["REV"] then
        for i = 1, 6 do
            page.pitch_graph.voice_dir[i] = PLAYBACK_DIRECTION["REV"]
        end
    else
        for i = 1, 5, 2 do
            page.pitch_graph.voice_dir[i] = PLAYBACK_DIRECTION["FWD"]
        end
        for i = 2, 6, 2 do
            page.pitch_graph.voice_dir[i] = PLAYBACK_DIRECTION["REV"]
        end
    end
    calculate_rates(state)
end

local function cycle_direction(state)
    local current = state.pages.pitch.direction
    local next
    if current == PLAYBACK_DIRECTION["FWD"] then
        next = "REV"
    elseif current == PLAYBACK_DIRECTION["REV"] then
        next = "FWD_REV"
    else
        next = "FWD"
    end

    state.pages.pitch.direction = PLAYBACK_DIRECTION[next]
    update_playback_dir(state)
end


local function toggle_quantize(state)
    state.pages.pitch.quantize = not state.pages.pitch.quantize
    state.pages.pitch.rate_center = math.floor(state.pages.pitch.rate_center + 0.5)
    calculate_rates(state)
end


local function adjust_center(state, d)
    -- todo: map to semitones
    local step = state.pages.pitch.quantize and 1 or 1 / 120
    state_util.adjust_param(state.pages.pitch, 'rate_center', d, step, -3, 3, false)
    calculate_rates(state)
    page.pitch_graph.center = state.pages.pitch.rate_center * -2 -- why *-2?
end

local function adjust_spread(state, d)
    state_util.adjust_param(state.pages.pitch, 'rate_spread', d, 0.1, 0, 2, false)
    calculate_rates(state)
end


page = Page:create({
    name = page_name,
    e2 = adjust_center,
    e3 = adjust_spread,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = cycle_direction,
    k3_on = nil,
    k3_off = toggle_quantize,
})

function page:render(state)
    page.window:render()
    page.footer.button_text.k2.value = state.pages.pitch.direction
    page.footer.button_text.k3.value = state.pages.pitch.quantize and "ON" or "OFF"
    page.footer.button_text.e2.value = misc_util.trim(tostring(
        math.floor(state.pages.pitch.rate_center * 1200 + .5) / 100
    ), 5)
    page.footer.button_text.e3.value = misc_util.trim(tostring(
        math.floor(state.pages.pitch.rate_spread * 1000 + .5) / 1000
    ), 5)

    page.pitch_graph:render()
    page.footer:render()
end

function page:initialize(state)
    add_params(state)
    page.window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "PLAYBACK RATES",
        font_face = state.title_font,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })

    page.pitch_graph = PitchGraph:new()
    update_playback_dir(state)
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "DIR",
                value = "BI",
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
