local function create_filter_lfo_page(cfg)
    -- cfg contains all filter-specific parameters

    local page_name        = cfg.page_name
    local parent_page      = cfg.parent_page
    local lfo
    local last_freq
    local lfo_shapes       = cfg.lfo_shapes
    local spec_freq_mod    = cfg.spec_freq_mod
    local spec_lfo_range   = cfg.spec_lfo_range
    local ENGINE_FREQ      = cfg.engine_freq
    local ENGINE_MOD_RANGE = cfg.engine_mod_range
    local ID_LFO           = cfg.id_lfo
    local ID_LFO_SHAPE     = cfg.id_lfo_shape
    local ID_LFO_RANGE     = cfg.id_lfo_range
    local ID_FREQ_MOD      = cfg.id_freq_mod
    local ID_LFO_RATE      = cfg.id_lfo_rate
    local LFO_SHAPES       = cfg.lfo_shapes


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
        misc_util.toggle_param(ID_LFO)
    end

    local function adjust_lfo_rate(d)
        lfo_util.adjust_lfo_rate_quant(d, lfo)
    end

    local page = Page:create({
        name = page_name,
        e2 = adjust_lfo_rate,
        e3 = adjust_range,
        k2_off = toggle_lfo,
        k3_off = cycle_lfo,
    })

    local function action_lfo_toggle(v)
        print(v)
        lfo_util.action_lfo_toggle(v, lfo, params:get(ENGINE_FREQ))
        -- store last frequency when toggling LFO on, so it can be set back to that value
        if v == 1 then
            last_freq = params:get(ENGINE_FREQ)
        else
            params:set(ID_FREQ_MOD, 1)
            if last_freq then params:set(ENGINE_FREQ, last_freq) end
        end
    end

    local function action_lfo_shape(v)
        lfo_util.action_lfo_shape(v, lfo, LFO_SHAPES, params:get(ENGINE_FREQ))
    end

    local function action_lfo_rate(v)
        lfo:set('period', lfo_util.lfo_period_label_values[params:string(ID_LFO_RATE)])
    end

    local function action_range(v)
        spec_freq_mod.minval = 1 / v
        spec_freq_mod.maxval = v
    end
    local function action_freq_mod(v)
        params:set(ENGINE_FREQ, v * last_freq)
    end

    local function add_params()
        params:set_action(ID_FREQ_MOD, action_freq_mod)
        params:set_action(ID_LFO_RANGE, action_range)

        params:set_action(ID_LFO, action_lfo_toggle)
        params:set_action(ID_LFO_SHAPE, action_lfo_shape)
        params:set_action(ID_LFO_RATE, action_lfo_rate)
    end

    function page:render()
        self.window:render()
        parent_page.graphic:set_size(56, 26)
        parent_page:render_graphic(true)
        page:render_footer()
    end

    function page:render_footer()
        local lfo_enabled = params:get(ID_LFO)
        local shape = string.upper(lfo_shapes[params:get(ID_LFO_SHAPE)])
        local period = lfo:get('period')
        local range = params:get(ID_LFO_RANGE)
        self.footer.button_text.e2.name = "RATE"
        self.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]

        self.footer.button_text.k2.value = lfo_enabled == 1 and "ON" or "OFF"
        self.footer.button_text.k3.value = shape
        self.footer.button_text.e3.value = range

        self.footer:render()
    end

    function page:initialize()
        last_freq = params:get(ENGINE_FREQ)
        add_params()

        self.window = Window:new({ title = page_name, font_face = TITLE_FONT })

        page.footer = Footer:new({
            button_text = {
                k2 = { name = "LFO", value = "" },
                k3 = { name = "SHAPE", value = "" },
                e2 = { name = "RATE", value = "" },
                e3 = { name = "RANGE", value = "" },
            },
            font_face = FOOTER_FONT,
        })

        lfo = _lfos:add(cfg.lfo_defaults(last_freq))
        lfo:set('reset_target', 'mid: rising')
    end

    function page:enter()
        --
    end

    function page:exit()
        --
    end

    return page
end

return create_filter_lfo_page
