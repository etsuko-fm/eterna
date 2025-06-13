local Page = include("bits/lib/Page")
local page_name = "ScanLfo"
local Window = include("bits/lib/graphics/Window")
local LevelsGraphic = include("bits/lib/graphics/LevelsGraphic")
local gaussian = include("bits/lib/util/gaussian")
local state_util = include("bits/lib/util/state")
local misc_util = include("bits/lib/util/misc")
local lfo_util = include("bits/lib/util/lfo")
local bars_graphic
local window

local graph_x = 36 -- (128 - graph_width) / 2
local graph_y = 40

local LFO_SHAPES = { "sine", "up", "down", "random" }

local PARAM_ID_LFO_ENABLED = "levels_lfo_enabled"
local PARAM_ID_LFO_SHAPE = "levels_lfo_shape"
local PARAM_ID_LFO_RATE = "levels_lfo_rate"
local PARAM_ID_POS = "levels_pos"
local PARAM_ID_SIGMA = "levels_sigma"

local POSITION_MIN = 0
local POSITION_MAX = 1

local SIGMA_MIN = 0.3
local SIGMA_MAX = 15

local controlspec_pos = controlspec.def {
    min = POSITION_MIN, -- the minimum value
    max = POSITION_MAX, -- the maximum value
    warp = 'lin',       -- a shaping option for the raw value
    step = 0.01,        -- output value quantization
    default = 1.0,      -- default value
    units = '',         -- displayed on PARAMS UI
    quantum = 0.01,     -- each delta will change raw value by this much
    wrap = true         -- wrap around on overflow (true) or clamp (false)
}

local controlspec_sigma = controlspec.def {
    min = SIGMA_MIN, -- the minimum value
    max = SIGMA_MAX, -- the maximum value
    warp = 'lin',    -- a shaping option for the raw value
    step = 0.01,     -- output value quantization
    default = 1.0,   -- default value
    units = '',      -- displayed on PARAMS UI
    quantum = 0.01,  -- each delta will change raw value by this much
    wrap = false     -- wrap around on overflow (true) or clamp (false)
}


local function map_sigma(state, v)
    return util.explin(SIGMA_MIN, SIGMA_MAX, 0, 1, v)
end

local function adjust_sigma(state, d)
    local k = (10 ^ math.log(state.pages.metamixer.sigma, 10)) / 25
    state_util.adjust_param(state.pages.metamixer, 'sigma', d, k, state.pages.metamixer.sigma_min,
        state.pages.metamixer.sigma_max, false)
    local levels = gaussian.calculate_gaussian_levels(params:get(PARAM_ID_POS),
        state.pages.metamixer.sigma)
    for i = 1, 6 do
        softcut.level(i, levels[i])
    end
end

local function toggle_shape(state)
    local index = params:get(PARAM_ID_LFO_SHAPE)
    local next_index = (index % #LFO_SHAPES) + 1
    params:set(PARAM_ID_LFO_SHAPE, next_index, false) -- todo: is there a way to scroll through the params values?
end

local function toggle_lfo(state)
    params:set(PARAM_ID_LFO_ENABLED, 1 - state.pages.metamixer.lfo:get("enabled"), false)
end

local function adjust_position(state, d)
    local incr = d * controlspec_pos.quantum
    local curr = params:get(PARAM_ID_POS)
    local new_val = curr + incr
    params:set(PARAM_ID_POS, new_val, false)
end

local function adjust_lfo_rate(state, d)
    lfo_util.adjust_lfo_rate_quant(d, state.pages.metamixer.lfo)
end


local function e2(state, d)
    if state.pages.metamixer.lfo:get("enabled") == 1 then
        adjust_lfo_rate(state, d)
    else
        adjust_position(state, d)
    end
end


local function e3(state, d)
    adjust_sigma(state, d)
end


local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = e2,
    e3 = e3,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = toggle_lfo,
    k3_on = nil,
    k3_off = toggle_shape,
})

function page:render(state)
    bars_graphic.levels = gaussian.calculate_gaussian_levels(params:get(PARAM_ID_POS),
        state.pages.metamixer.sigma)
    screen.clear()
    bars_graphic:render()

    window:render()
    if state.pages.metamixer.lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        page.footer.button_text.k2.value = "ON"
        page.footer.button_text.e2.name = "RATE"

        -- convert period to label representation
        local period = state.pages.metamixer.lfo:get('period')
        page.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]
    else
        -- When LFO is disabled, E2 controls scan position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "POS"
        page.footer.button_text.e2.value = misc_util.trim(tostring(params:get(PARAM_ID_POS)), 5)
    end
    page.footer.button_text.k3.value = string.upper(params:string(PARAM_ID_LFO_SHAPE))
    page.footer.button_text.e3.value = misc_util.trim(tostring(map_sigma(state, state.pages.metamixer.sigma)), 5)

    page.footer:render()
end

local function add_params(state)
    params:add_separator("BITS_LEVELS", "LEVELS")

    params:add_binary(PARAM_ID_LFO_ENABLED, "LFO enabled", "toggle", 0)
    params:set_action(PARAM_ID_LFO_ENABLED,
        function()
            if state.pages.metamixer.lfo:get("enabled") == 1 then
                state.pages.metamixer.lfo:stop()
            else
                state.pages.metamixer.lfo:start()
            end
            state.pages.metamixer.lfo:set('phase', params:get(PARAM_ID_POS))
        end
    )

    params:add_option(PARAM_ID_LFO_SHAPE, "LFO shape", LFO_SHAPES, 1)
    params:set_action(PARAM_ID_LFO_SHAPE,
        function() state.pages.metamixer.lfo:set('shape', params:string(PARAM_ID_LFO_SHAPE)) end)
    print(state.pages.metamixer.lfo_period)
    print(lfo_util.lfo_period_value_labels[state.pages.metamixer.lfo_period])
    local default_rate_index = 20
    local default_rate = lfo_util.lfo_period_values[default_rate_index]
    params:add_option(PARAM_ID_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, default_rate)
    params:set_action(PARAM_ID_LFO_RATE,
        function()
            state.pages.metamixer.lfo:set('period',
                lfo_util.lfo_period_label_values[params:string(PARAM_ID_LFO_RATE)])
        end)

    params:add_control(PARAM_ID_POS, "position", controlspec_pos)
    params:set_action(PARAM_ID_POS, function()
        local levels = gaussian.calculate_gaussian_levels(params:get(PARAM_ID_POS),
            state.pages.metamixer.sigma)
        for i = 1, 6 do
            softcut.level(i, levels[i])
        end
    end)

    params:add_control(PARAM_ID_SIGMA, "sigma", controlspec_sigma)
    params:set_action(PARAM_ID_SIGMA, function() end)
end

function page:initialize(state)
    add_params(state)
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "LEVELS",
        font_face = state.title_font,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })

    -- graphics
    bars_graphic = LevelsGraphic:new({
        x = graph_x,
        y = graph_y,
        bar_width = 6,
        max_bar_height = 24,
        num_bars_graphic = 6,
        brightness = 15,
    })

    -- initialize softcut levels according to mixer levels
    adjust_sigma(state, 0)
    local levels = gaussian.calculate_gaussian_levels(params:get(PARAM_ID_POS),
        state.pages.metamixer.sigma)

    bars_graphic.levels = gaussian.calculate_gaussian_levels(params:get(PARAM_ID_POS),
        state.pages.metamixer.sigma)

    for i = 1, 6 do
        softcut.level(i, levels[i])
        print(i, "initialized to ", levels[i])
    end

    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "LFO",
                value = "",
            },
            k3 = {
                name = "SHAPE",
                value = "Sine",
            },
            e2 = {
                name = "POS",
                value = "",
            },
            e3 = {
                name = "AMP",
                value = "",
            },
        },
        font_face = state.footer_font,
    })

    -- lfo
    state.pages.metamixer.lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'clocked',
        period = state.pages.metamixer.lfo_period,
        phase = 0,
        action = function(scaled, raw)
            bars_graphic.scan_val = scaled
            params:set(PARAM_ID_POS, controlspec_pos:map(scaled), false)
        end
    }
    state.pages.metamixer.lfo:set('reset_target', 'mid: rising')
end

return page
