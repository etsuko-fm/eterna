-- filter_page.lua
local FilterGraphic = include(from_root("lib/graphics/FilterGraphic"))

local function create_filter_page(cfg)
    -- cfg contains all filter-specific parameters

    local page_name = cfg.page_name
    local filter_graphic
    local lfo
    local last_freq

    local ENGINE_FREQ = cfg.engine_freq
    local ENGINE_RES  = cfg.engine_res
    local ENGINE_DRY  = cfg.engine_dry
    local ID_LFO      = cfg.id_lfo
    local ID_WET      = cfg.id_wet
    local ID_FREQ_MOD = cfg.id_freq_mod
    local ID_LFO_RATE = cfg.id_lfo_rate
    local LFO_SHAPES  = cfg.lfo_shapes
    local FILTER_TYPE = cfg.filter_graphic_type

    local function adjust_freq(d)
        misc_util.adjust_param(
            d, ENGINE_FREQ,
            engine_lib.params.specs[cfg.freq_param_name].quantum
        )
    end

    local function adjust_res(d)
        misc_util.adjust_param(
            d, ENGINE_RES,
            engine_lib.params.specs[cfg.res_param_name].quantum
        )
    end

    local function cycle_lfo()
        misc_util.cycle_param(ID_LFO, LFO_SHAPES)
    end

    local function adjust_lfo_rate(d)
        lfo_util.adjust_lfo_rate_quant(d, lfo)
    end

    local function toggle_drywet()
        misc_util.cycle_param(ID_WET, DRY_WET_TYPES)
    end

    local function e2(d)
        if lfo:get("enabled") == 1 then
            adjust_lfo_rate(d)
        else
            adjust_freq(d)
        end
    end

    local page = Page:create({
        name = page_name,
        e2 = e2,
        e3 = adjust_res,
        k2_off = cycle_lfo,
        k3_off = toggle_drywet,
    })

    local function action_wet(v)
        if DRY_WET_TYPES[v] == "DRY" then
            params:set(ENGINE_DRY, 1)
        elseif DRY_WET_TYPES[v] == "50/50" then
            params:set(ENGINE_DRY, 0.5)
        else
            params:set(ENGINE_DRY, 0)
        end
    end

    local function action_lfo(v)
        lfo_util.action_lfo(v, lfo, LFO_SHAPES, params:get(ENGINE_FREQ))
        if LFO_SHAPES[v] ~= "off" then
            last_freq = params:get(ENGINE_FREQ)
        else
            params:set(ID_FREQ_MOD, 1)
            if last_freq then params:set(ENGINE_FREQ, last_freq) end
        end
    end

    local function action_lfo_rate(v)
        lfo:set('period', lfo_util.lfo_period_label_values[params:string(ID_LFO_RATE)])
    end

    local function action_freq_mod(v)
        params:set(ENGINE_FREQ, v * last_freq)
    end

    local function add_params()
        params:set_action(ID_FREQ_MOD, action_freq_mod)
        params:set_action(ID_WET, action_wet)
        params:set_action(ID_LFO, action_lfo)
        params:set_action(ID_LFO_RATE, action_lfo_rate)
    end

    function page:render()
        self.window:render()

        local freq = params:get(ENGINE_FREQ)
        local res  = params:get(ENGINE_RES)
        local drywet = params:get(ID_WET)

        filter_graphic.freq = freq
        filter_graphic.res  = res
        filter_graphic.type = FILTER_TYPE
        filter_graphic.mix  = (drywet - 1) / 2
        filter_graphic:render()

        local lfo_state = params:get(ID_LFO)
        page.footer.button_text.k2.value = string.upper(LFO_SHAPES[lfo_state])

        if lfo:get("enabled") == 1 then
            page.footer.button_text.e2.name = "RATE"
            local period = lfo:get('period')
            page.footer.button_text.e2.value =
                lfo_util.lfo_period_value_labels[period]
        else
            page.footer.button_text.k2.value = "OFF"
            page.footer.button_text.e2.name = "FREQ"
            page.footer.button_text.e2.value = misc_util.trim(tostring(freq), 5)
        end

        page.footer.button_text.k3.value = DRY_WET_TYPES[drywet]
        page.footer.button_text.e3.value = misc_util.trim(tostring(res), 5)
        page.footer:render()
    end

    function page:initialize()
        last_freq = params:get(ENGINE_FREQ)
        add_params()

        self.window = Window:new({ title = page_name, font_face = TITLE_FONT })
        filter_graphic = FilterGraphic:new()

        page.footer = Footer:new({
            button_text = {
                k2 = { name = "LFO", value = "" },
                k3 = { name = "MIX", value = "" },
                e2 = { name = "FREQ", value = "" },
                e3 = { name = "RES",  value = "" },
            },
            font_face = FOOTER_FONT,
        })

        lfo = _lfos:add(cfg.lfo_defaults(last_freq))
        lfo:set('reset_target', 'mid: rising')
    end

    return page
end

return create_filter_page
