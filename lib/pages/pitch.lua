local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local PitchGraph = include("bits/lib/graphics/PitchGraph")
local page_name = "Playback"
local debug = include("bits/lib/util/debug")
local state_util = include("bits/lib/util/state")
local misc_util = include("bits/lib/util/misc")
local page

local PARAM_ID_DIRECTION = "pitch_direction"
local PARAM_ID_QUANTIZE = "pitch_quantize"
local PARAM_ID_CENTER = "pitch_center"
local PARAM_ID_SPREAD = "pitch_spread"

local QUANTIZE_DEFAULT = 1

local CENTER_MIN = -3
local CENTER_MAX = 3

local SPREAD_MIN = -3
local SPREAD_MAX = 3

local controlspec_center = controlspec.def {
    min = CENTER_MIN, -- the minimum value
    max = CENTER_MAX, -- the maximum value
    warp = 'lin',       -- a shaping option for the raw value
    step = 0.01,        -- output value quantization
    default = 0.0,      -- default value
    units = '',         -- displayed on PARAMS UI
    quantum = 0.01,     -- each delta will change raw value by this much
    wrap = false         -- wrap around on overflow (true) or clamp (false)
}

local controlspec_spread = controlspec.def {
    min = SPREAD_MIN, -- the minimum value
    max = SPREAD_MAX, -- the maximum value
    warp = 'lin',       -- a shaping option for the raw value
    step = 0.01,        -- output value quantization
    default = 0.0,      -- default value
    units = '',         -- displayed on PARAMS UI
    quantum = 0.01,     -- each delta will change raw value by this much
    wrap = false         -- wrap around on overflow (true) or clamp (false)
}

local function calculate_rates(state)
    -- recalculate softcut playback rates, taking into account quantize, spread, center, direction
    for i = 0, 5 do
        -- map 6 values as equally spread angles on a (virtual) circle, by using radians (fraction * 2PI)
        local radians = i / 6 * math.pi * 2

        -- this extra factor increases the range; values beyond 2PI are effectively treated as `% 2PI` by sin(), 
        -- because sin() is a periodic function with a period of 2PI
        -- this extension affects the way the playback rates are spread over the six voices
        local extend = 2.67  -- manually tuned, 2.7 is also nice

        -- here pitch is not a meaningful value yet; it's _some_ ratio of the normal playback pitch, with 0 = original pitch
        local pitch = math.sin(radians * extend) * params:get(PARAM_ID_SPREAD)

        -- double to increase range, we'll use half the range for reverse playback (-4 < pitch < 0) and half for forward (0 < pitch < 4)
        pitch = pitch * 2
        pitch = pitch + params:get(PARAM_ID_CENTER)

        if params:get(PARAM_ID_QUANTIZE) == 1 then
            -- quantize to integers between -2 and 2,because 2^[-2|-1|0|1|2] gives quantized rates from 0.25 to 4
            pitch = math.floor(pitch + 0.5)
        end

        local rate = util.clamp(2 ^ pitch, 1 / 8, 8)

        if page.pitch_graph.voice_dir[i] == PLAYBACK_DIRECTION["REV"] then
            -- reverse playback [TODO: wait, why?]
            rate = -rate
        end
        -- state.softcut.rates[i + 1] = rate
        softcut.rate(i+1, rate)
        -- graph is linear while rate is exponential 
        page.pitch_graph.voice_pos[i] = -math.log(math.abs(rate), 2)
    end
end

local function update_playback_dir(new_val)
    -- update graphics
    if new_val == PLAYBACK_DIRECTION["FWD"] then
        -- all forward 
        for i = 1, 6 do
            page.pitch_graph.voice_dir[i] = PLAYBACK_DIRECTION["FWD"]
        end
    elseif new_val == PLAYBACK_DIRECTION["REV"] then
        -- all reverse
        for i = 1, 6 do
            page.pitch_graph.voice_dir[i] = PLAYBACK_DIRECTION["REV"]
        end
    else
        -- alternate forward/reverse
        for i = 1, 5, 2 do
            page.pitch_graph.voice_dir[i] = PLAYBACK_DIRECTION["FWD"]
        end
        for i = 2, 6, 2 do
            page.pitch_graph.voice_dir[i] = PLAYBACK_DIRECTION["REV"]
        end
    end
    -- update softcut
    calculate_rates()
end

local function add_params(state)
    params:add_separator("PLAYBACK_RATES", "PLAYBACK RATES")

    params:add_binary(PARAM_ID_QUANTIZE, 'quantize', "toggle", QUANTIZE_DEFAULT)
    params:set_action(PARAM_ID_QUANTIZE, action_quantize)

    params:add_control(PARAM_ID_CENTER, "center", controlspec_center)
    params:set_action(PARAM_ID_CENTER, action_center)

    params:add_control(PARAM_ID_SPREAD, "spread", controlspec_spread)
    params:set_action(PARAM_ID_SPREAD, action_spread)

    local p = {"FWD", "REV", "FWD_REV"}
    params:add_option(PARAM_ID_DIRECTION, "direction", p, 1)
    params:set_action(PARAM_ID_DIRECTION, action_direction)
end

function action_direction(v)
    update_playback_dir(v)
end

function action_quantize(v)
    if v == 1 then
        params:set(PARAM_ID_CENTER, math.floor(params:get(PARAM_ID_CENTER) + .5))
        controlspec_center.quantum = 1.0;

        -- think need to cycle through predetermined values:
        -- 0  0  0   0   0   0
        -- 0  0  0   0   1  -1
        -- 0  0  1  -1   1  -1
        -- 0  0  1  -1   2  -2
        -- 0 -1  1  -2   2  -3
        -- 0 -1  2  -2   3  -3
        controlspec_spread.quantum = .5
        controlspec_spread.minval = -2.5
        controlspec_spread.maxval = 2.5

        params:set(PARAM_ID_SPREAD, math.floor(params:get(PARAM_ID_SPREAD) + .5))
    else
        controlspec_center.quantum = 0.01;
        controlspec_spread.quantum = 0.01;
        controlspec_spread.minval = SPREAD_MIN
        controlspec_spread.maxval = SPREAD_MAX
    end
    calculate_rates()
end

function action_center(v)
    calculate_rates()
end

function action_spread(v)
    calculate_rates()
end


local function cycle_direction()
    local current = params:get(PARAM_ID_DIRECTION)
    local next
    if current == PLAYBACK_DIRECTION["FWD"] then
        next = "REV"
    elseif current == PLAYBACK_DIRECTION["REV"] then
        next = "FWD_REV"
    else
        next = "FWD"
    end

    params:set(PARAM_ID_DIRECTION, PLAYBACK_DIRECTION[next])
    update_playback_dir()
end


local function toggle_quantize(state)
    params:set(PARAM_ID_QUANTIZE, 1 - params:get(PARAM_ID_QUANTIZE))
end

local function adjust_center(state, d)
    params:set(PARAM_ID_CENTER, params:get(PARAM_ID_CENTER) + d * controlspec_center.quantum, false)
    page.pitch_graph.center = params:get(PARAM_ID_CENTER) * -2 -- why *-2?
end

local function adjust_spread(state, d)
    params:set(PARAM_ID_SPREAD, params:get(PARAM_ID_SPREAD) + d * controlspec_spread.quantum)
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
    page.footer.button_text.k2.value = params:get(PARAM_ID_DIRECTION)
    page.footer.button_text.k3.value = params:get(PARAM_ID_QUANTIZE) == 1 and "ON" or "OFF"
    page.footer.button_text.e2.value = misc_util.trim(tostring(
        math.floor(params:get(PARAM_ID_CENTER) * 1200 + .5) / 100
    ), 5)
    page.footer.button_text.e3.value = misc_util.trim(tostring(
        math.floor(params:get(PARAM_ID_SPREAD) * 1000 + .5) / 1000
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
    update_playback_dir()
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
