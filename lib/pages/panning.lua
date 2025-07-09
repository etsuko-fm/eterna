local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local PanningGraphic = include("bits/lib/graphics/PanningGraphic")
local misc_util = include("bits/lib/util/misc")
local lfo_util = include("bits/lib/util/lfo")

local page_name = "PANNING"
local window

local panning_graphic

local PARAM_ID_LFO_ENABLED = "panning_lfo_enabled"
local PARAM_ID_LFO_SHAPE = "panning_lfo_shape"
local PARAM_ID_LFO_RATE = "panning_lfo_rate"
local PARAM_ID_TWIST = "panning_twist"
local PARAM_ID_SPREAD = "panning_spread"

local TWIST_MIN = 0
local TWIST_MAX = 1

local SPREAD_MIN = 0
local SPREAD_MAX = 1

local panning_lfo

local controlspec_twist = controlspec.def {
    min = TWIST_MIN,     -- the minimum value
    max = TWIST_MAX,     -- the maximum value
    warp = 'lin',        -- a shaping option for the raw value
    step = 0.005,        -- output value quantization
    default = 0.0,         -- default value
    units = '',          -- displayed on PARAMS UI
    quantum = 0.005,     -- each delta will change raw value by this much
    wrap = true          -- wrap around on overflow (true) or clamp (false)
}

local controlspec_spread = controlspec.def {
    min = SPREAD_MIN, -- the minimum value
    max = SPREAD_MAX, -- the maximum value
    warp = 'lin',     -- a shaping option for the raw value
    step = 0.01,      -- output value quantization
    default = 0.0,      -- default value
    units = '',       -- displayed on PARAMS UI
    quantum = 0.01,   -- each delta will change raw value by this much
    wrap = false      -- wrap around on overflow (true) or clamp (false)
}

-- todo: at tri?
local LFO_SHAPES = { "sine", "up", "down", "random" }

local function calculate_pan_positions()
    local twist = params:get(PARAM_ID_TWIST)
    local spread = params:get(PARAM_ID_SPREAD)
    for i = 0, 5 do
        local voice = i + 1
        local angle = (twist + i / 6) * (math.pi * 2) -- Divide the range of radians into 6 equal parts, add offset
        local pan =  spread * math.cos(angle)
        softcut.pan(voice, pan)
        panning_graphic.pans[voice] = pan
    end
end

local function adjust_spread(d)
    local new_val = params:get(PARAM_ID_SPREAD) + d * controlspec_spread.quantum
    params:set(PARAM_ID_SPREAD, new_val, false)
end

local function adjust_twist(d)
    local new_val = params:get(PARAM_ID_TWIST) + d * controlspec_twist.quantum
    params:set(PARAM_ID_TWIST, new_val, false)
end

local function toggle_lfo()
    params:set(PARAM_ID_LFO_ENABLED, 1 - panning_lfo:get("enabled"), false)
end

local function toggle_shape()
    local index = params:get(PARAM_ID_LFO_SHAPE)
    local next_index = (index % #LFO_SHAPES) + 1
    params:set(PARAM_ID_LFO_SHAPE, next_index, false)
end

local function e2(d)
    if panning_lfo:get("enabled") == 1 then
        lfo_util.adjust_lfo_rate_quant(d, panning_lfo)
    else
        adjust_twist(d)
    end
end

local page = Page:create({
    name = page_name,
    e2 = e2,
    e3 = adjust_spread,
    k2_off = toggle_lfo,
    k3_off = toggle_shape,
})

local function add_actions()
    params:set_action(PARAM_ID_LFO_ENABLED,
        function()
            if panning_lfo:get("enabled") == 1 then
                panning_lfo:stop()
            else
                panning_lfo:start()
            end
            panning_lfo:set('phase', params:get(PARAM_ID_TWIST))
        end
    )
    params:set_action(PARAM_ID_LFO_SHAPE,
        function() panning_lfo:set('shape', params:string(PARAM_ID_LFO_SHAPE)) end
    )
    params:set_action(PARAM_ID_TWIST, calculate_pan_positions)
    params:set_action(PARAM_ID_SPREAD, calculate_pan_positions)
    params:set_action(PARAM_ID_LFO_RATE,
        function() panning_lfo:set('period', lfo_util.lfo_period_label_values[params:string(PARAM_ID_LFO_RATE)]) end)

end

local function add_params()
    params:add_separator("PANNING", page_name)
    params:add_binary(PARAM_ID_LFO_ENABLED, "LFO enabled", "toggle", 0)
    params:add_option(PARAM_ID_LFO_SHAPE, "LFO shape", LFO_SHAPES, 1)
    params:add_option(PARAM_ID_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels)
    params:add_control(PARAM_ID_TWIST, "twist", controlspec_twist)
    params:add_control(PARAM_ID_SPREAD, "spread", controlspec_spread)
    add_actions()
end

function page:render()
    window:render()
    local twist = params:get(PARAM_ID_TWIST)
    local spread = params:get(PARAM_ID_SPREAD)
    panning_graphic:render()
    if panning_lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        page.footer.button_text.k2.value = "ON"
        page.footer.button_text.e2.name = "RATE"
        -- convert period to label representation
        local period = panning_lfo:get('period')
        page.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]
    else
        -- When LFO is disabled, E2 controls pan position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "TWIST"
        page.footer.button_text.e2.value = misc_util.trim(tostring(twist), 5)
    end
    page.footer.button_text.e3.value = misc_util.trim(tostring(spread), 5)
    page.footer.button_text.k3.value = string.upper(panning_lfo:get("shape"))
    page.footer:render()
end

function page:initialize()
    add_params()
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "PANNING",
        font_face = TITLE_FONT,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    -- graphics
    panning_graphic = PanningGraphic:new()
    calculate_pan_positions()
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
                name = "TWIST",
                value = "",
            },
            e3 = {
                name = "WIDTH",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })
    -- lfo
    panning_lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'clocked',
        period = 8,
        phase = 0,
        action = function(scaled, raw)
            params:set(PARAM_ID_TWIST, controlspec_twist:map(scaled), false)
        end
    }
    panning_lfo:set('reset_target', 'mid: rising')
end

return page
