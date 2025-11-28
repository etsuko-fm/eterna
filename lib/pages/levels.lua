local page_name = "Levels"
local LevelsGraphic = include(from_root("lib/graphics/LevelsGraphic"))
local gaussian = include(from_root("lib/util/gaussian"))
local level_graphic
local graph_x = 36 -- (128 - graph_width) / 2
local graph_y = 40
local lfo

local function adjust_amp(d)
    misc_util.adjust_param(d, ID_LEVELS_AMP, controlspec_amp.quantum)
end

local function adjust_position(d)
    misc_util.adjust_param(d, ID_LEVELS_POS, controlspec_pos.quantum)
end

local function cycle_lfo_shape()
    misc_util.cycle_param(ID_LEVELS_LFO_SHAPE, LEVELS_LFO_SHAPES)
end

local function toggle_lfo()
    misc_util.toggle_param(ID_LEVELS_LFO_ENABLED)
end


local function adjust_lfo_rate(d)
    lfo_util.adjust_lfo_rate_quant(d, lfo)
end

local function amp_to_sigma(v)
    return util.linexp(0, 1, LEVELS_SIGMA_MIN, LEVELS_SIGMA_MAX, v)
end

local function e2(d)
    if lfo:get("enabled") == 1 then
        adjust_lfo_rate(d)
    else
        adjust_position(d)
    end
end

local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = e2,
    e3 = adjust_amp,
    k2_off = toggle_lfo,
    k3_off = cycle_lfo_shape,
})

function page:render()
    local sigma = amp_to_sigma(params:get(ID_LEVELS_AMP))

    for i = 1, 6 do amp_polls[i]:update() end

    local pos = params:get(ID_LEVELS_POS)
    level_graphic.levels = gaussian.calculate_gaussian_levels(pos, sigma)
    level_graphic.scan_val = pos
    local lfo_shape = params:get(ID_LEVELS_LFO_SHAPE)

    screen.clear()
    level_graphic:render()
    local lfo_enabled = params:get(ID_LEVELS_LFO_ENABLED)

    self.footer.button_text.k2.value = lfo_enabled == 1 and "ON" or "OFF"
    page.footer.button_text.k3.value = string.upper(LEVELS_LFO_SHAPES[lfo_shape])

    self.window:render()
    if lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        -- Switch POS to RATE
        page.footer.button_text.e2.name = "RATE"

        -- convert period to label representation
        local period = lfo:get('period')
        page.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]
    else
        -- When LFO is disabled, E2 controls scan position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "POS"
        -- multiply by 6 because of 6 voices; indicates which voice is fully audible
        page.footer.button_text.e2.value = misc_util.trim(tostring(pos * 6), 4)
    end

    page.footer.button_text.e3.value = misc_util.trim(tostring(params:get(ID_LEVELS_AMP)), 5)
    page.footer:render()
end

local function recalculate_levels()
    local sigma = amp_to_sigma(params:get(ID_LEVELS_AMP))
    local levels = gaussian.calculate_gaussian_levels(params:get(ID_LEVELS_POS), sigma)
    for i = 1, 6 do
        local voice_level = engine_lib.get_id("voice_level", i)
        params:set(voice_level, levels[i])
    end
end

local function action_lfo_toggle(v)
    lfo_util.action_lfo_toggle(v, lfo, params:get(ID_LEVELS_POS))
end

local function action_lfo_shape(v)
    lfo_util.action_lfo_shape(v, lfo, LEVELS_LFO_SHAPES, params:get(ID_LEVELS_POS))
end

local function action_lfo_rate(v)
    lfo:set('period', lfo_util.lfo_period_label_values[params:string(ID_LEVELS_LFO_RATE)])
end

local function add_params()
    params:set_action(ID_LEVELS_LFO_ENABLED, action_lfo_toggle)
    params:set_action(ID_LEVELS_LFO_SHAPE, action_lfo_shape)
    params:set_action(ID_LEVELS_LFO_RATE, action_lfo_rate)
    params:set_action(ID_LEVELS_POS, recalculate_levels)
    params:set_action(ID_LEVELS_AMP, recalculate_levels)
end

function page:initialize()
    add_params()

    self.window = Window:new({ title = "LEVELS", font_face = TITLE_FONT })

    -- graphics
    level_graphic = LevelsGraphic:new({
        x = graph_x,
        y = graph_y,
        bar_width = 6,
        max_bar_height = 24,
        num_level_graphic = 6,
        brightness = 15,
    })

    adjust_amp(0)

    local sigma = amp_to_sigma(params:get(ID_LEVELS_AMP))
    local levels = gaussian.calculate_gaussian_levels(params:get(ID_LEVELS_POS), sigma)
    level_graphic.levels = levels


    page.footer = Footer:new({
        button_text = {
            k2 = { name = "LFO", value = "" },
            k3 = { name = "LFO WV", value = "" },
            e2 = { name = "POS", value = "" },
            e3 = { name = "AMP", value = "" },
        },
        font_face = FOOTER_FONT,
    })

    -- lfo
    lfo = _lfos:add {
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
    lfo:set('reset_target', 'mid: rising')
end

function page:enter()
    for i = 1, 6 do
        amp_polls[i].callback = function(v) level_graphic.voice_amp[i] = amp_to_log(v) end
    end
end

function page:exit()
    for i = 1, 6 do
        amp_polls[i].callback = nil
    end
end

return page
