local page_name = "Levels"
local LevelsGraphic = include("symbiosis/lib/graphics/LevelsGraphic")
local gaussian = include("symbiosis/lib/util/gaussian")
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

local function cycle_lfo()
    local p = ID_LEVELS_LFO
    local new_val = util.wrap(params:get(p) + 1, 1, #LEVELS_LFO_SHAPES)
    params:set(p, new_val)
end

local function adjust_position(d)
    local incr = d * controlspec_pos.quantum
    local curr = params:get(ID_LEVELS_POS)
    local new_val = curr + incr
    params:set(ID_LEVELS_POS, new_val)
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

local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = e2,
    e3 = adjust_sigma,
    k2_off = cycle_lfo,
    k3_off = nil,
})

function page:render()
    local sigma = amp_to_sigma(params:get(ID_LEVELS_AMP))
    amp1poll:update()
    amp2poll:update()
    amp3poll:update()
    amp4poll:update()
    amp5poll:update()
    amp6poll:update()

    local pos = params:get(ID_LEVELS_POS)
    level_graphic.levels = gaussian.calculate_gaussian_levels(pos, sigma)
    level_graphic.scan_val = pos
    local lfo_state = params:get(ID_LEVELS_LFO)

    screen.clear()
    level_graphic:render()

    page.footer.button_text.k2.value = string.upper(LEVELS_LFO_SHAPES[lfo_state])

    window:render()
    if levels_lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        -- Switch POS to RATE
        page.footer.button_text.e2.name = "RATE"

        -- convert period to label representation
        local period = levels_lfo:get('period')
        page.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]
    else
        -- When LFO is disabled, E2 controls scan position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "POS"
        -- multiply by 6 because of 6 voices; indicates which voice is fully audible    
        page.footer.button_text.e2.value = misc_util.trim(tostring(pos*6), 4)
    end

    page.footer.button_text.e3.value = misc_util.trim(tostring(params:get(ID_LEVELS_AMP)), 5)
    page.footer:render()
end

local function recalculate_levels()
    local sigma = amp_to_sigma(params:get(ID_LEVELS_AMP))
    local levels = gaussian.calculate_gaussian_levels(params:get(ID_LEVELS_POS), sigma)
    for i = 0, 5 do
        engine.level(i, levels[i + 1])
    end
    -- print(levels[1])
end

local function action_lfo(v)
    lfo_util.action_lfo(v, levels_lfo, LEVELS_LFO_SHAPES, params:get(ID_LEVELS_POS))
end

local function action_lfo_rate(v)
    levels_lfo:set('period', lfo_util.lfo_period_label_values[params:string(ID_LEVELS_LFO_RATE)])
end

local function add_params()
    params:set_action(ID_LEVELS_LFO, action_lfo)
    params:set_action(ID_LEVELS_LFO_RATE, action_lfo_rate)
    params:set_action(ID_LEVELS_POS, recalculate_levels)
    params:set_action(ID_LEVELS_AMP, recalculate_levels)
end

local function amp_callback(voice, val)
    level_graphic.voice_amp[voice] = amp_to_log(val)
end


function page:initialize()
    add_params()
    amp1poll.callback = function(v) amp_callback(1, v) end
    amp2poll.callback = function(v) amp_callback(2, v) end
    amp3poll.callback = function(v) amp_callback(3, v) end
    amp4poll.callback = function(v) amp_callback(4, v) end
    amp5poll.callback = function(v) amp_callback(5, v) end
    amp6poll.callback = function(v) amp_callback(6, v) end

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
                name = "",
                value = "",
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
