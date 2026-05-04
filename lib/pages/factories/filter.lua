-- filter_page.lua
local FilterGraphic = include(from_root("lib/graphics/FilterGraphic"))

local function create_filter_page(config)
    -- config contains all filter-specific parameters
    local lfo
    local page_name      = config.page_name
    local spec_lfo_range = config.spec_lfo_range

    local ENGINE_FREQ    = config.engine_freq
    local ENGINE_RES     = config.engine_res
    local ENGINE_DRY     = config.engine_dry
    local ID_WET         = config.id_wet
    local ID_BASE_FREQ   = config.id_base_freq
    local FILTER_TYPE    = config.filter_graphic_type
    local ID_LFO_ENABLED = config.id_lfo_enabled
    local ID_LFO_RANGE   = config.id_lfo_range
    local ID_LFO_RATE    = config.id_lfo_rate
    local ID_FREQ_MOD    = config.id_freq_mod
    local ID_LFO_SHAPE   = config.id_lfo_shape
    local ID_CTRL_MODE   = config.id_ctrl_mode
    local spec_freq_mod  = config.spec_freq_mod
    local LFO_SHAPES     = config.lfo_shapes

    local function adjust_freq(d)
        misc_util.adjust_param(
            d, ID_BASE_FREQ,
            controlspec_filter_freq.quantum
        )
    end

    local function adjust_range(d)
        misc_util.adjust_param(
            d, ID_LFO_RANGE,
            spec_lfo_range.quantum
        )
    end

    local function adjust_res(d)
        misc_util.adjust_param(
            d, ENGINE_RES,
            engine_lib.params.specs[config.res_param_name].quantum
        )
    end

    local function adjust_lfo_rate(d)
        misc_util.cycle_param(ID_LFO_RATE, lfo_util.lfo_period_values, d, false)
    end

    local function cycle_lfo()
        misc_util.cycle_param(ID_LFO_SHAPE, LFO_SHAPES)
    end

    local function cycle_mode()
        local delta = 1
        local wrap = true
        local available_modes = FILTER_CTRL_MODES
        if params:get(ID_WET) == 1 then
            -- can't control LFO if filter is off
            available_modes = {CTRL_MODE_FILTER}
        end
        misc_util.cycle_param(ID_CTRL_MODE, available_modes, delta, wrap)
    end

    local function cycle_mix()
        misc_util.cycle_param(ID_WET, DRY_WET_TYPES)
    end

    local function k3(v)
        if params:string(ID_CTRL_MODE) == CTRL_MODE_FILTER then
            cycle_mix()
        else
            cycle_lfo()
        end
    end

    local function e2(d)
        local control_mode = params:string(ID_CTRL_MODE)
        if control_mode == CTRL_MODE_FILTER then
            adjust_freq(d)
        else
            adjust_lfo_rate(d)
        end
    end

    local function e3(d)
        local control_mode = params:string(ID_CTRL_MODE)
        if control_mode == CTRL_MODE_FILTER then
            adjust_res(d)
        else
            adjust_range(d)
        end
    end

    local page = Page:create({
        name = page_name,
        e2 = e2,
        e3 = e3,
        k2_off = cycle_mode,
        k3_off = k3,
    })

    local function action_mix(v)
        if DRY_WET_TYPES[v] == MIX_DRY then
            params:set(ENGINE_DRY, 1)
            page.e2 = nil
            page.e3 = nil
        elseif DRY_WET_TYPES[v] == MIX_PARALLEL then
            page.e2 = e2
            page.e3 = e3
            params:set(ENGINE_DRY, 0.5)
        else
            page.e2 = e2
            page.e3 = e3
            params:set(ENGINE_DRY, 0)
        end
    end

    local function calc_max_range_val()
        -- computes the maximum range for modulation to not exceed 20khz
        -- TODO: could optimize, only changes when ID_BASE_FREQ changes
        local base = params:get(ID_BASE_FREQ)
        return math.log(20000 / base) / math.log(2)
    end

    local function action_range(v)
        -- updating range changes the maximum value of the modulation spec;
        -- this is e.g. 0 - 16, which is used as a power of 2 to produce
        -- equal travel time per octave -> see fn get_modulated_freq(base, range)
        spec_freq_mod.maxval = math.min(v, calc_max_range_val())
        local lfo_enabled = lfo:get("enabled") == 1
        if v ~= 0 and not lfo_enabled then
            -- enable LFO if it was disabled and the range is non-zero
            lfo:start()
        elseif v == 0 and lfo_enabled then
            -- disable LFO if it was enabled and the range is zero
            lfo:stop()
        end
    end

    local function action_base_freq(v)
        if params:get(ID_LFO_RANGE) == 0 then
            params:set(ENGINE_FREQ, v)
        end
        -- with a new base freq, the allowed range may change
        action_range(params:get(ID_LFO_RANGE))
    end

    local function action_lfo_toggle(v)
        lfo_util.action_lfo_toggle(v, lfo, params:get(ENGINE_FREQ))
        -- store last frequency when toggling LFO on, so it can be set back to that value
        if v == 0 then
            params:set(ID_FREQ_MOD, 0)
        end
    end

    local function action_lfo_shape(v)
        lfo_util.action_lfo_shape(v, lfo, LFO_SHAPES, params:get(ENGINE_FREQ))
    end

    local function action_lfo_rate(v)
        lfo:set('period', lfo_util.lfo_period_label_values[params:string(ID_LFO_RATE)])
    end

    local function get_modulated_freq(base, range)
        -- for base = 1000, mod = 0|1|2 :
        --  1000 * 2 ^ 0 = 1000
        --  1000 * 2 ^ 1 = 2000
        --  1000 * 2 ^ 2 = 4000
        return util.clamp(base * 2 ^ range, 20, 20000)
    end

    local function action_freq_mod(range)
        local modulated_freq = get_modulated_freq(params:get(ID_BASE_FREQ), range)
        params:set(ENGINE_FREQ, modulated_freq)
    end

    local function get_lfo_range()
        local base_freq = params:get(ID_BASE_FREQ)
        return base_freq, get_modulated_freq(base_freq, params:get(ID_LFO_RANGE))
    end

    local function add_params()
        params:set_action(ID_WET, action_mix)
        params:set_action(ID_BASE_FREQ, action_base_freq)
        params:set_action(ID_FREQ_MOD, action_freq_mod)
        params:set_action(ID_LFO_RANGE, action_range)
        params:set_action(ID_LFO_ENABLED, action_lfo_toggle)
        params:set_action(ID_LFO_SHAPE, action_lfo_shape)
        params:set_action(ID_LFO_RATE, action_lfo_rate)
    end

    function page:update_graphics_state()
        local control_mode = params:string(ID_CTRL_MODE)
        local freq         = params:get(ENGINE_FREQ)
        local res          = params:get(ENGINE_RES)
        local mix          = params:get(ID_WET)
        local base_freq    = params:get(ID_BASE_FREQ)
        local lfo_shape    = params:get(ID_LFO_SHAPE)
        local low, high    = get_lfo_range()
        local period       = lfo:get('period')
        local range        = params:get(ID_LFO_RANGE)

        -- render non-modulated frequency
        self.graphic:set("freq", base_freq)
        self.graphic:set("lfo_freq", freq)
        self.graphic:set("res", res)
        self.graphic:set("type", FILTER_TYPE)

        -- mix can be 1 (0%), 2 (50%) or 3 (100%)
        self.graphic:set("mix", (mix - 1) / 2)
        local route_txt = ""

        if DRY_WET_TYPES[mix] == MIX_DRY then
            route_txt = "OFF"
        elseif DRY_WET_TYPES[mix] == MIX_WET then
            route_txt = "ON"
        else
            route_txt = DRY_WET_TYPES[mix]
        end

        if control_mode == CTRL_MODE_FILTER then
            self.footer:set_value("k2", control_mode)
            self.footer:set_name("k3", "MIX")
            self.footer:set_value("k3", route_txt)
            if mix > 1 then
                self.footer:set_name("e2", "FREQ")
                self.footer:set_name("e3", "RES")
                self.footer:set_value("e2", misc_util.trim(tostring(base_freq), 5))
                self.footer:set_value("e3", misc_util.trim(tostring(res), 5))
            else
                self.footer:set_name("e2", "")
                self.footer:set_value("e2", "")
                self.footer:set_name("e3", "")
                self.footer:set_value("e3", "")
            end
        elseif control_mode == CTRL_MODE_LFO and mix > 1 then
            self.footer:set_value("k2", control_mode)
            self.footer:set_name("k3", "WAVE")
            self.footer:set_value("k3", string.upper(LFO_SHAPES[lfo_shape]))

            self.footer:set_name("e2", "RATE")
            self.footer:set_value("e2", lfo_util.lfo_period_value_labels[period])

            self.footer:set_name("e3", "RANGE")
            self.footer:set_value("e3", range)
        end

        -- render non-modulated frequency
        self.graphic:set("freq", freq)
        self.graphic:set_lfo_range(low, high)
        self.graphic:set("res", res)
        self.graphic:set("type", FILTER_TYPE)
        self.graphic:set("mix", (mix - 1) / 2)
        self.graphic:set("rate_fraction", params:get(ID_LFO_RATE) / #lfo_util.lfo_period_labels)
        self.graphic:set("draw_lfo_range", mix > 1 and range > 0)
    end

    function page:initialize()
        last_freq = params:get(ENGINE_FREQ)
        add_params()

        self.graphic = FilterGraphic:new()
        self.graphic:set_size(62, 27)
        self.graphic:set("draw_lfo_range", false)
        self.graphic:set("lfo_freq", params:get(ID_BASE_FREQ))
        self.graphic = self.graphic

        self.footer = Footer:new({
            button_text = {
                k2 = { name = "CTRL", value = "" },
                k3 = { name = "MIX", value = "" },
                e2 = { name = "FREQ", value = "" },
                e3 = { name = "RES", value = "" },
            },
            font_face = FOOTER_FONT,
        })

        lfo = _lfos:add({
            shape = 'sine',
            min = 0,
            max = 1,
            depth = 1,
            mode = 'clocked',
            period = 8,
            phase = 0,
            ppqn = 24,
            action = function(scaled, raw)
                -- map the lfo value to the range of the controlspec
                params:set(ID_FREQ_MOD, spec_freq_mod:map(scaled), false)
            end
        })
        lfo:set('reset_target', 'mid: rising')
    end

    function page:enter()
        header.title = page_name
    end

    return page
end

return create_filter_page