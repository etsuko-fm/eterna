local page_name = "LEVELS"
local LevelsGraphic = include(from_root("lib/graphics/LevelsGraphic"))
local gaussian = include(from_root("lib/util/gaussian"))
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
    lfo_util.adjust_lfo_rate(d, lfo)
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

function page:update_graphics_state()
    local sigma = amp_to_sigma(params:get(ID_LEVELS_AMP))

    for i = 1, 6 do amp_polls[i]:update() end

    local pos = params:get(ID_LEVELS_POS)
    local amp = params:get(ID_LEVELS_AMP)
    local lfo_shape = params:get(ID_LEVELS_LFO_SHAPE)
    local lfo_enabled = params:get(ID_LEVELS_LFO_ENABLED)

    -- TODO: this should use the set_table method
    local levels = gaussian.calculate_gaussian_levels(pos, sigma)
    for key, val in ipairs(levels) do
        self.graphic:set_table("levels", key, val)
    end
    self.graphic:set("scan_val", pos)

    self.footer:set_value('k2', lfo_enabled == 1 and "ON" or "OFF")
    self.footer:set_value('k3', string.upper(LEVELS_LFO_SHAPES[lfo_shape]))
    self.footer:set_value('e3', misc_util.trim(tostring(amp), 5))

    if lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        local period = lfo:get('period')
        local rate_value = lfo_util.lfo_period_value_labels[period]
        self.footer:set_name('e2', "RATE")
        self.footer:set_value('e2', rate_value)
    else
        self.footer:set_value('e3', misc_util.trim(tostring(amp), 5))
        -- When LFO is disabled, E2 controls scan position
        self.footer:set_name('e2', "POS")
        -- map 0:1 to 0:5 because of 6 voices; indicates which voice has amp 1.0 (when pos is a whole number)
        self.footer:set_value('e2', misc_util.trim(tostring(pos * 6), 4))
    end
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

    window.title = "LEVELS"

    -- graphics
    self.graphic = LevelsGraphic:new({
        x = 36,
        y = 40,
        bar_width = 6,
        max_bar_height = 24,
        num_level_graphic = 6,
        brightness = 15,
    })

    adjust_amp(0)

    local sigma = amp_to_sigma(params:get(ID_LEVELS_AMP))
    local levels = gaussian.calculate_gaussian_levels(params:get(ID_LEVELS_POS), sigma)
    self.graphic:set("levels", levels)

    page.footer = Footer:new({
        button_text = {
            k2 = { name = "LFO", value = "" },
            k3 = { name = "WAVE", value = "" },
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
        ppqn = 24,
        action = function(scaled, raw)
            self.graphic:set("scan_val", scaled)
            params:set(ID_LEVELS_POS, controlspec_pos:map(scaled), false)
        end
    }
    lfo:set('reset_target', 'mid: rising')
end

function page:enter()
    window.title = page_name
    for i = 1, 6 do
        amp_polls[i].callback = function(v) self.graphic:set_table("voice_amp", i, amp_to_log(v)) end
    end
end

function page:exit()
    for i = 1, 6 do
        amp_polls[i].callback = nil
    end
end

return page
