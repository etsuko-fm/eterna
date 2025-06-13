local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local PanningGraphic = include("bits/lib/graphics/PanningGraphic")
local state_util = include("bits/lib/util/state")
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

local controlspec_twist = controlspec.def {
    min = TWIST_MIN,     -- the minimum value
    max = TWIST_MAX,     -- the maximum value
    warp = 'lin',        -- a shaping option for the raw value
    step = 0.005,        -- output value quantization
    default = 0,         -- default value
    units = '',          -- displayed on PARAMS UI
    quantum = 0.005,     -- each delta will change raw value by this much
    wrap = true          -- wrap around on overflow (true) or clamp (false)
}

local controlspec_spread = controlspec.def {
    min = SPREAD_MIN, -- the minimum value
    max = SPREAD_MAX, -- the maximum value
    warp = 'lin',     -- a shaping option for the raw value
    step = 0.01,      -- output value quantization
    default = 1.0,      -- default value
    units = '',       -- displayed on PARAMS UI
    quantum = 0.01,   -- each delta will change raw value by this much
    wrap = false      -- wrap around on overflow (true) or clamp (false)
}

local LFO_SHAPES = { "sine", "up", "down", "random" }

local function calculate_pan_positions(state)
    local twist = params:get(PARAM_ID_TWIST)
    local spread = params:get(PARAM_ID_SPREAD)
    for i = 0, 5 do
        local angle = (i / 6) * (math.pi * 2) + twist -- Divide the range of radians into 6 equal parts, add offset

        -- could remove panning range here
        state.pages.panning.pan_positions[i + 1] = spread * math.cos(angle)
    end
    for i = 1, 6 do
        softcut.pan(i, state.pages.panning.pan_positions[i])
    end
end

local function adjust_spread(state, d)
    local incr = d * controlspec_spread.quantum
    local curr = params:get(PARAM_ID_SPREAD)
    local new_val = curr + incr
    params:set(PARAM_ID_SPREAD, new_val, false)
end

local function adjust_twist(state, d)
    local incr = d * controlspec_twist.quantum
    local curr = params:get(PARAM_ID_TWIST)
    local new_val = curr + incr
    params:set(PARAM_ID_TWIST, new_val, false)
end

local function toggle_lfo(state)
    params:set(PARAM_ID_LFO_ENABLED, 1 - state.pages.panning.lfo:get("enabled"), false)
end

local function toggle_shape(state)
    local index = params:get(PARAM_ID_LFO_SHAPE)
    local next_index = (index % #LFO_SHAPES) + 1
    params:set(PARAM_ID_LFO_SHAPE, next_index, false)
end

local function e2(state, d)
    if state.pages.panning.lfo:get("enabled") == 1 then
        lfo_util.adjust_lfo_rate_quant(d, state.pages.panning.lfo)
    else
        adjust_twist(state, d)
    end
end

local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = e2,
    e3 = adjust_spread,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = toggle_lfo,
    k3_on = nil,
    k3_off = toggle_shape,
})

function page:render(state)
    window:render()
    local twist = params:get(PARAM_ID_TWIST)
    local spread = params:get(PARAM_ID_SPREAD)
    panning_graphic:render()
    if state.pages.panning.lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        page.footer.button_text.k2.value = "ON"
        page.footer.button_text.e2.name = "RATE"
        -- convert period to label representation
        local period = state.pages.panning.lfo:get('period')
        page.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]
    else
        -- When LFO is disabled, E2 controls pan position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "TWIST"
        page.footer.button_text.e2.value = misc_util.trim(tostring(twist), 5)
    end
    page.footer.button_text.e3.value = misc_util.trim(tostring(spread), 5)
    page.footer.button_text.k3.value = string.upper(state.pages.panning.lfo:get("shape"))
    page.footer:render()
end

local function add_params(state)
    params:add_separator("PANNING", page_name)
    params:add_binary(PARAM_ID_LFO_ENABLED, "LFO enabled", "toggle", 0)
    params:set_action(PARAM_ID_LFO_ENABLED,
        function()
            if state.pages.panning.lfo:get("enabled") == 1 then
                state.pages.panning.lfo:stop()
            else
                state.pages.panning.lfo:start()
            end
            state.pages.panning.lfo:set('phase', params:get(PARAM_ID_TWIST))
        end
    )

    params:add_option(PARAM_ID_LFO_SHAPE, "LFO shape", LFO_SHAPES, 1)
    params:set_action(PARAM_ID_LFO_SHAPE,
        function() state.pages.panning.lfo:set('shape', params:string(PARAM_ID_LFO_SHAPE)) end)

    params:add_option(PARAM_ID_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels)
    params:set_action(PARAM_ID_LFO_RATE,
        function() state.pages.panning.lfo:set('period', lfo_util.lfo_period_label_values[params:string(PARAM_ID_LFO_RATE)]) end)


    params:add_control(PARAM_ID_TWIST, "twist", controlspec_twist)
    params:set_action(PARAM_ID_TWIST,
        function()
            calculate_pan_positions(state)
            -- convert 0-1 to radians
            panning_graphic.twist = params:get(PARAM_ID_TWIST) * math.pi * 2
        end
    )

    params:add_control(PARAM_ID_SPREAD, "spread", controlspec_spread)
    params:set_action(PARAM_ID_SPREAD,
        function()
            calculate_pan_positions(state)
            panning_graphic.spread = params:get(PARAM_ID_SPREAD)
        end
    )
end

function page:initialize(state)
    add_params(state)
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
    panning_graphic = PanningGraphic:new({
        twist = params:get(PARAM_ID_TWIST) * math.pi * 2,
        spread = params:get(PARAM_ID_SPREAD),
    })
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
        font_face = state.footer_font,
    })
    -- lfo
    state.pages.panning.lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'clocked',
        period = state.pages.panning.default_lfo_period,
        phase = 0,
        action = function(scaled, raw)
            params:set(PARAM_ID_TWIST, controlspec_twist:map(scaled), false)
        end
    }
    state.pages.panning.lfo:set('reset_target', 'mid: rising')
end

return page
