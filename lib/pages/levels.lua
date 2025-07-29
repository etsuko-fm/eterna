local Page = include("bits/lib/Page")
local page_name = "ScanLfo"
local Window = include("bits/lib/graphics/Window")
local LevelsGraphic = include("bits/lib/graphics/LevelsGraphic")
local gaussian = include("bits/lib/util/gaussian")
local misc_util = include("bits/lib/util/misc")
local lfo_util = include("bits/lib/util/lfo")

local level_graphic
local graph_x = 36 -- (128 - graph_width) / 2
local graph_y = 40

local window
local levels_lfo

local function amp_to_sigma(v)
    return util.linexp(0, 1, LEVELS_SIGMA_MIN, LEVELS_SIGMA_MAX, v)
end

local function adjust_sigma(d)
    local incr = d * controlspec_amp.quantum
    local curr = params:get(ID_LEVELS_AMP)
    local new_val = curr + incr
    params:set(ID_LEVELS_AMP, new_val, false)
end

local function toggle_shape()
    local index = params:get(ID_LEVELS_LFO_SHAPE)
    local next_index = (index % #LEVELS_LFO_SHAPES) + 1
    params:set(ID_LEVELS_LFO_SHAPE, next_index, false)
end

local function toggle_lfo()
    params:set(ID_LEVELS_LFO_ENABLED, 1 - levels_lfo:get("enabled"), false)
end

local function adjust_position(d)
    local incr = d * controlspec_pos.quantum
    local curr = params:get(ID_LEVELS_POS)
    local new_val = curr + incr
    params:set(ID_LEVELS_POS, new_val, false)
end

local function adjust_lfo_rate(d)
    lfo_util.adjust_lfo_rate_quant(d, levels_lfo)
end

local function e2(d)
    if levels_lfo:get("enabled") == 1 then
        adjust_lfo_rate(d)
    else
        adjust_position(d)
    end
end

local function e3(d)
    adjust_sigma(d)
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

function page:render()
    local sigma = amp_to_sigma(params:get(ID_LEVELS_AMP))
    level_graphic.levels = gaussian.calculate_gaussian_levels(params:get(ID_LEVELS_POS), sigma)
    screen.clear()
    level_graphic:render()

    window:render()
    if levels_lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        page.footer.button_text.k2.value = "ON"
        page.footer.button_text.e2.name = "RATE"

        -- convert period to label representation
        local period = levels_lfo:get('period')
        page.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]
    else
        -- When LFO is disabled, E2 controls scan position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "POS"
        page.footer.button_text.e2.value = misc_util.trim(tostring(params:get(ID_LEVELS_POS)), 5)
    end
    page.footer.button_text.k3.value = string.upper(params:string(ID_LEVELS_LFO_SHAPE))
    page.footer.button_text.e3.value = misc_util.trim(tostring(params:get(ID_LEVELS_AMP)), 5)
    page.footer:render()
end

local function recalculate_levels()
    local sigma = amp_to_sigma(params:get(ID_LEVELS_AMP))
    local levels = gaussian.calculate_gaussian_levels(params:get(ID_LEVELS_POS), sigma)
    for i = 0, 5 do
        engine.level(i, levels[i])
    end
end

local function action_enable_lfo(v)
    if v == 1 then
        levels_lfo:start()
    else
        levels_lfo:stop()
    end
    levels_lfo:set('phase', params:get(ID_LEVELS_POS))
end

local function action_lfo_shape(v)
    levels_lfo:set('shape', params:string(ID_LEVELS_LFO_SHAPE))
end

local function action_lfo_rate(v)
    levels_lfo:set('period', lfo_util.lfo_period_label_values[params:string(ID_LEVELS_LFO_RATE)])
end

local function add_params()
    params:set_action(ID_LEVELS_LFO_ENABLED, action_enable_lfo)
    params:set_action(ID_LEVELS_LFO_SHAPE, action_lfo_shape)
    params:set_action(ID_LEVELS_LFO_RATE, action_lfo_rate)
    params:set_action(ID_LEVELS_POS, recalculate_levels)
    params:set_action(ID_LEVELS_AMP, recalculate_levels)
end

function page:initialize()
    add_params()
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "LEVELS",
        font_face = TITLE_FONT,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })

    -- graphics
    level_graphic = LevelsGraphic:new({
        x = graph_x,
        y = graph_y,
        bar_width = 6,
        max_bar_height = 24,
        num_level_graphic = 6,
        brightness = 15,
    })

    -- initialize softcut levels according to mixer levels
    adjust_sigma(0)

    local sigma = amp_to_sigma(params:get(ID_LEVELS_AMP))
    local levels = gaussian.calculate_gaussian_levels(params:get(ID_LEVELS_POS), sigma)
    level_graphic.levels = levels

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
        font_face = FOOTER_FONT,
    })

    -- lfo
    levels_lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'clocked',
        period = 8,
        phase = 0,
        action = function(scaled, raw)
            level_graphic.scan_val = scaled
            params:set(ID_LEVELS_POS, controlspec_pos:map(scaled), false)
        end
    }
    levels_lfo:set('reset_target', 'mid: rising')
end

return page
