local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local PitchGraph = include("bits/lib/graphics/PitchGraph")
local page_name = "Playback"
local misc_util = include("bits/lib/util/misc")
local page

local PARAM_ID_DIRECTION = "pitch_direction"
local PARAM_ID_QUANTIZE = "pitch_quantize"
local PARAM_ID_CENTER = "pitch_center"
local PARAM_ID_SPREAD = "pitch_spread"

-- voice directions; also used for other pages, hence global
function get_voice_dir_param_id(i)
  return "pitch_v" .. i .. "_dir"
end

local CENTER_MIN = -2
local CENTER_MAX = 2
local CENTER_QUANTUM = 1 / 120
local CENTER_QUANTUM_QUANTIZED = 1.0

local SPREAD_MIN = -2
local SPREAD_MAX = 2
local SPREAD_MIN_QUANTIZED = -2
local SPREAD_MAX_QUANTIZED = 2
local SPREAD_QUNATUM = 0.01
local SPREAD_QUNATUM_QUANTIZED = 0.5

local FWD = "FWD"
local REV = "REV"
local FWD_REV = "FWD+REV"
local PLAYBACK_TABLE = { FWD, REV, FWD_REV }

local OFF = "OFF"
local OCTAVES = "OCTAV"
local QUANTIZE_TABLE = { OFF, OCTAVES }
local QUANTIZE_DEFAULT = 2 -- octave quantization by default

local controlspec_center = controlspec.def {
    min = CENTER_MIN,                   -- the minimum value
    max = CENTER_MAX,                   -- the maximum value
    warp = 'lin',                       -- a shaping option for the raw value
    step = 1 / 120,                     -- output value quantization
    default = 0.0,                      -- default value
    units = '',                         -- displayed on PARAMS UI
    quantum = CENTER_QUANTUM_QUANTIZED, -- each delta will change raw value by this much
    wrap = false                        -- wrap around on overflow (true) or clamp (false)
}

local controlspec_spread = controlspec.def {
    min = SPREAD_MIN_QUANTIZED,         -- the minimum value
    max = SPREAD_MAX_QUANTIZED,         -- the maximum value
    warp = 'lin',                       -- a shaping option for the raw value
    step = 0.01,                        -- output value quantization
    default = 0.0,                      -- default value
    units = '',                         -- displayed on PARAMS UI
    quantum = SPREAD_QUNATUM_QUANTIZED, -- each delta will change raw value by this much
    wrap = false                        -- wrap around on overflow (true) or clamp (false)
}

local function calculate_rates()
    local quantize = QUANTIZE_TABLE[params:get(PARAM_ID_QUANTIZE)]
    -- recalculate softcut playback rates, taking into account quantize, spread, center, direction
    for i = 0, 5 do
        -- map 6 values as equally spread angles on a (virtual) circle, by using radians (fraction * 2PI)
        local radians = i / 6 * math.pi * 2

        -- this extra factor increases the range; values beyond 2PI are effectively treated as `% 2PI` by sin(),
        -- because sin() is a periodic function with a period of 2PI
        -- this extension affects the way the playback rates are spread over the six voices
        local extend = 2 --2.67 -- manually tuned, 2.7 is also nice

        -- here pitch is still a linear value, representing steps on the slider
        local pitch = math.sin(radians * extend) * params:get(PARAM_ID_SPREAD)

        -- double to increase range, we'll use half the range for reverse playback (-4 < pitch < 0) and half for forward (0 < pitch < 4)
        pitch = pitch + params:get(PARAM_ID_CENTER)

        if quantize ~= OFF then
            -- quantize to integers between -2 and 2,because 2^[-2|-1|0|1|2] gives quantized rates from 0.25 to 4
            pitch = math.floor(pitch + 0.5)
        end

        -- these correspond to the octaves;
        -- 1 = normal, 1/2 = -12, -1/4 = -24, -1/8 = -36
        local rate = util.clamp(2 ^ pitch, .25, 4)

        local voice = i + 1
        if params:get(get_voice_dir_param_id(voice)) == 2 then -- todo: lookuptable 2>rev, 1>fwd
            rate = -rate
        end
        softcut.rate(voice, rate)
        -- graph is linear while rate is exponential 
        page.pitch_graph.voice_pos[i] = -math.log(math.abs(rate), 2)
    end
end

local function update_playback_dir(new_val)
    -- update graphics
    if PLAYBACK_TABLE[new_val] == FWD then
        -- all forward
        for voice = 1, 6 do
            page.pitch_graph.voice_dir[voice] = FWD
            params:set(get_voice_dir_param_id(voice), 1)
        end
    elseif PLAYBACK_TABLE[new_val] == REV then
        -- all reverse
        for voice = 1, 6 do
            page.pitch_graph.voice_dir[voice] = REV
            params:set(get_voice_dir_param_id(voice), 2)
        end
    else
        -- alternate forward/reverse
        for voice = 1, 5, 2 do
            page.pitch_graph.voice_dir[voice] = FWD
            params:set(get_voice_dir_param_id(voice), 1)
        end
        for voice = 2, 6, 2 do
            page.pitch_graph.voice_dir[voice] = REV
            params:set(get_voice_dir_param_id(voice), 2)
        end
    end
    -- update softcut
    calculate_rates()
end

local function add_params()
    params:add_separator("PLAYBACK_RATES", "PLAYBACK RATES")

    params:add_option(PARAM_ID_QUANTIZE, 'quantize', QUANTIZE_TABLE, QUANTIZE_DEFAULT)
    params:set_action(PARAM_ID_QUANTIZE, action_quantize)

    params:add_control(PARAM_ID_CENTER, "center", controlspec_center)
    params:set_action(PARAM_ID_CENTER, calculate_rates)

    params:add_control(PARAM_ID_SPREAD, "spread", controlspec_spread)
    params:set_action(PARAM_ID_SPREAD, calculate_rates)

    params:add_option(PARAM_ID_DIRECTION, "direction", PLAYBACK_TABLE, 1)
    params:set_action(PARAM_ID_DIRECTION, update_playback_dir)

    -- voice directions (fwd/rev/both)
    for voice = 1, 6 do
        local param_id = get_voice_dir_param_id(voice)
        params:add_option(param_id, param_id, PLAYBACK_TABLE, 1)
        params:hide(param_id)
    end

end

function action_quantize(v)
    if QUANTIZE_TABLE[v] == OCTAVES then
        params:set(PARAM_ID_CENTER, math.floor(params:get(PARAM_ID_CENTER) + .5))
        controlspec_center.quantum = CENTER_QUANTUM_QUANTIZED;
        controlspec_spread.quantum = SPREAD_QUNATUM_QUANTIZED
        controlspec_spread.minval = SPREAD_MIN_QUANTIZED
        controlspec_spread.maxval = SPREAD_MAX_QUANTIZED
        params:set(PARAM_ID_SPREAD, math.floor(params:get(PARAM_ID_SPREAD) + .5))
    else
        controlspec_center.quantum = CENTER_QUANTUM;
        controlspec_spread.quantum = SPREAD_QUNATUM;
        controlspec_spread.minval = SPREAD_MIN
        controlspec_spread.maxval = SPREAD_MAX
    end
    calculate_rates()
end

local function cycle_direction()
    local new = util.wrap(params:get(PARAM_ID_DIRECTION) + 1, 1, 3)
    params:set(PARAM_ID_DIRECTION, new)
end


local function toggle_quantize()
    local old = params:get(PARAM_ID_QUANTIZE)
    local new = util.wrap(old + 1, 1, #QUANTIZE_TABLE)
    params:set(PARAM_ID_QUANTIZE, new)
end

local function adjust_center(d)
    params:set(PARAM_ID_CENTER, params:get(PARAM_ID_CENTER) + d * controlspec_center.quantum, false)
    page.pitch_graph.center = params:get(PARAM_ID_CENTER) * -2 -- why *-2?
end

local function adjust_spread(d)
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

function page:render()
    page.window:render()
    page.footer.button_text.k2.value = PLAYBACK_TABLE[params:get(PARAM_ID_DIRECTION)]
    page.footer.button_text.k3.value = QUANTIZE_TABLE[params:get(PARAM_ID_QUANTIZE)]

    -- convert -3/+3 range to -36/+36 rounded to 1 decimal
    page.footer.button_text.e2.value = misc_util.trim(tostring(
        math.floor(params:get(PARAM_ID_CENTER) * 1200 + .5) / 100
    ), 5)

    -- Round value to 2 decimals
    page.footer.button_text.e3.value = misc_util.trim(tostring(
        math.floor(params:get(PARAM_ID_SPREAD) * 100 + .5) / 100
    ), 5)

    page.pitch_graph:render()
    page.footer:render()
end

function page:initialize()
    add_params()
    page.window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "PLAYBACK RATES",
        font_face = TITLE_FONT,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })

    page.pitch_graph = PitchGraph:new()
    update_playback_dir(1)
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
        font_face = FOOTER_FONT
    })
end

return page
