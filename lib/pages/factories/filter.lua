-- filter_page.lua
local FilterGraphic = include(from_root("lib/graphics/FilterGraphic"))

local function create_filter_page(cfg)
    -- cfg contains all filter-specific parameters

    local page_name    = cfg.page_name
    local spec_freq_mod    = cfg.spec_freq_mod

    local ENGINE_FREQ  = cfg.engine_freq
    local ENGINE_RES   = cfg.engine_res
    local ENGINE_DRY   = cfg.engine_dry
    local ID_WET       = cfg.id_wet
    local ID_BASE_FREQ = cfg.id_base_freq
    local FILTER_TYPE  = cfg.filter_graphic_type
    local ID_LFO       = cfg.id_lfo
    local ID_LFO_RANGE     = cfg.id_lfo_range

    local function adjust_freq(d)
        misc_util.adjust_param(
            d, ID_BASE_FREQ,
            controlspec_filter_freq.quantum
        )
    end

    local function adjust_res(d)
        misc_util.adjust_param(
            d, ENGINE_RES,
            engine_lib.params.specs[cfg.res_param_name].quantum
        )
    end

    local function toggle_mix()
        misc_util.cycle_param(ID_WET, DRY_WET_TYPES)
    end

    local page = Page:create({
        name = page_name,
        e2 = adjust_freq,
        e3 = adjust_res,
        k2_off = toggle_mix,
        k3_off = nil,
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

    local function get_modulated(base, mod)
        return base * 2 ^ mod
    end

    local function get_lfo_range()
        return params:get(ID_BASE_FREQ), get_modulated(params:get(ID_BASE_FREQ), params:get(ID_LFO_RANGE))
    end

    local function action_base_freq(v)
        if params:get(ID_LFO) == 0 then
            params:set(ENGINE_FREQ, v)
        end
        local min, max = get_lfo_range()
        spec_freq_mod.minval = min
        spec_freq_mod.maxval = max
    end

    local function add_params()
        params:set_action(ID_WET, action_wet)
        params:set_action(ID_BASE_FREQ, action_base_freq)
    end

    function page:render()
        self.window:render()
        self.graphic:set_size(64, 30)
        self:render_graphic()
        self:render_footer()
    end

    function page:render_graphic(draw_lfo_range)
        local freq        = params:get(ENGINE_FREQ)
        local res         = params:get(ENGINE_RES)
        local drywet      = params:get(ID_WET)

        -- render non-modulated frequency
        self.graphic.freq = params:get(ID_BASE_FREQ)
        self.graphic.res  = res
        self.graphic.type = FILTER_TYPE
        self.graphic.mix  = (drywet - 1) / 2
        self.graphic:render(draw_lfo_range)
    end

    function page:render_footer()
        local base_freq                  = params:get(ID_BASE_FREQ)
        local live_freq                  = params:get(ENGINE_FREQ)
        local drywet                     = params:get(ID_WET)
        local res                        = params:get(ENGINE_RES)

        self.footer.button_text.e2.name  = "FREQ"
        self.footer.button_text.e2.value = misc_util.trim(tostring(base_freq), 5)
        self.footer.button_text.k2.value = DRY_WET_TYPES[drywet]
        self.footer.button_text.e3.value = misc_util.trim(tostring(res), 5)
        self.footer:render()
    end

    function page:initialize()
        add_params()

        self.window = Window:new({ title = page_name, font_face = TITLE_FONT })
        self.graphic = FilterGraphic:new()

        self.footer = Footer:new({
            button_text = {
                k2 = { name = "MIX", value = "" },
                k3 = { name = "", value = "" },
                e2 = { name = "FREQ", value = "" },
                e3 = { name = "RES", value = "" },
            },
            font_face = FOOTER_FONT,
        })
    end

    return page
end

return create_filter_page
