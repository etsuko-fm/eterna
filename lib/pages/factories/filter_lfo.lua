local function create_filter_lfo_page(cfg)
    -- cfg contains all filter-specific parameters

    local page_name      = cfg.page_name
    local lfo
    local lfo_shapes     = cfg.lfo_shapes
    local spec_freq_mod  = cfg.spec_freq_mod
    local spec_lfo_range = cfg.spec_lfo_range
    local ENGINE_FREQ    = cfg.engine_freq
    local ENGINE_RES     = cfg.engine_res
    local ID_LFO_ENABLED = cfg.id_lfo_enabled
    local ID_LFO_SHAPE   = cfg.id_lfo_shape
    local ID_LFO_RANGE   = cfg.id_lfo_range
    local ID_FREQ_MOD    = cfg.id_freq_mod
    local ID_WET         = cfg.id_wet
    local ID_LFO_RATE    = cfg.id_lfo_rate
    local LFO_SHAPES     = cfg.lfo_shapes
    local ID_BASE_FREQ   = cfg.id_base_freq
    local FILTER_TYPE    = cfg.filter_graphic_type


    local function adjust_range(d)
        misc_util.adjust_param(
            d, ID_LFO_RANGE,
            spec_lfo_range.quantum
        )
    end

    local function cycle_lfo()
        misc_util.cycle_param(ID_LFO_SHAPE, LFO_SHAPES)
    end

    local function toggle_lfo()
        misc_util.toggle_param(ID_LFO_ENABLED)
    end

    local function adjust_lfo_rate(d)
        misc_util.cycle_param(ID_LFO_RATE, lfo_util.lfo_period_values, d, false)
    end

    local page = Page:create({
        name = page_name,
        e2 = adjust_lfo_rate,
        e3 = adjust_range,
        k2_off = toggle_lfo,
        k3_off = cycle_lfo,
    })

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

    local function get_modulated(base, mod)
        return util.clamp(base * 2 ^ mod, 20, 20000)
    end

    local function get_lfo_range()
        local base_freq = params:get(ID_BASE_FREQ)
        return base_freq, get_modulated(base_freq, params:get(ID_LFO_RANGE))
    end

    local function action_range(v)
        -- updating range changes the maximum value of the modulation spec;
        -- this is e.g. 0 - 16, which is used as a power of 2 to produce
        -- equal travel time per octave -> see fn get_modulated(base, mod)
        spec_freq_mod.maxval = v
    end

    local function action_freq_mod(mod_amount)
        local modulated_freq = get_modulated(params:get(ID_BASE_FREQ), mod_amount)
        params:set(ENGINE_FREQ, modulated_freq)
    end

    local function add_params()
        params:set_action(ID_FREQ_MOD, action_freq_mod)
        params:set_action(ID_LFO_RANGE, action_range)
        params:set_action(ID_LFO_ENABLED, action_lfo_toggle)
        params:set_action(ID_LFO_SHAPE, action_lfo_shape)
        params:set_action(ID_LFO_RATE, action_lfo_rate)
    end

    function page:update_graphics_state()
        local freq      = params:get(ENGINE_FREQ)
        local res       = params:get(ENGINE_RES)
        local drywet    = params:get(ID_WET)
        local low, high = get_lfo_range()
        local lfo_enabled = params:get(ID_LFO_ENABLED)
        local shape = string.upper(params:string(ID_LFO_SHAPE))
        local period = lfo:get('period')
        local range = params:get(ID_LFO_RANGE)

        self.footer:set_name("e2", "RATE")
        self.footer:set_value("e2", lfo_util.lfo_period_value_labels[period])
        self.footer:set_value("k2", lfo_enabled == 1 and "ON" or "OFF")
        self.footer:set_value("k3", shape)
        self.footer:set_value("e3", range)

        -- render non-modulated frequency
        self.graphic:set("freq", freq)
        self.graphic:set_lfo_range(low, high)
        self.graphic:set("res", res)
        self.graphic:set("type", FILTER_TYPE)
        self.graphic:set("mix", (drywet - 1) / 2)
        self.graphic:set("rate_fraction", params:get(ID_LFO_RATE) / #lfo_util.lfo_period_labels)
    end

    function page:initialize()
        last_freq = params:get(ENGINE_FREQ)
        add_params()

        self.graphic = FilterGraphic:new()
        local w = 56
        local h = 26
        local screen_width = 128

        self.graphic:set_size(w, h)
        self.graphic:set("x", screen_width / 2 - w / 2 + 3)
        self.graphic:set("draw_lfo_range", true)

        page.footer = Footer:new({
            button_text = {
                k2 = { name = "LFO", value = "" },
                k3 = { name = "WAVE", value = "" },
                e2 = { name = "RATE", value = "" },
                e3 = { name = "RANGE", value = "" },
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
            action = function(scaled)
                -- map the lfo value to the range of the controlspec
                params:set(ID_FREQ_MOD, spec_freq_mod:map(scaled), false)
            end
        })
        lfo:set('reset_target', 'mid: rising')
    end

    function page:enter()
        header.title = page_name
    end

    function page:exit()
        --
    end

    return page
end

return create_filter_lfo_page
