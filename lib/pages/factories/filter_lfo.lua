local function create_filter_lfo_page(cfg)
    -- cfg contains all filter-specific parameters

    local page_name    = cfg.page_name
    local parent_page = cfg.parent_page
    local lfo
    local last_freq

    local ENGINE_FREQ  = cfg.engine_freq
    local ENGINE_MOD_RANGE = cfg.engine_mod_range
    local ID_LFO       = cfg.id_lfo
    local ID_LFO_SHAPE = cfg.id_lfo_shape
    local ID_FREQ_MOD  = cfg.id_freq_mod
    local ID_LFO_RATE  = cfg.id_lfo_rate
    local LFO_SHAPES   = cfg.lfo_shapes
    

    local function adjust_range(d)
        misc_util.adjust_param(
            d, ENGINE_MOD_RANGE,
            engine_lib.params.specs[cfg.res_param_name].quantum
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

    local function action_freq_mod(v)
        params:set(ENGINE_FREQ, v * last_freq)
    end

    local function add_params()
        params:set_action(ID_FREQ_MOD, action_freq_mod)
        params:set_action(ID_LFO, action_lfo_toggle)
        params:set_action(ID_LFO_SHAPE, action_lfo_shape)
        params:set_action(ID_LFO_RATE, action_lfo_rate)
    end

    function page:render()
        self.window:render()
        parent_page:render_graphic(true)
        page.footer:render()
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

    return page
end

return create_filter_lfo_page

