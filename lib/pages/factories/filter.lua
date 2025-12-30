-- filter_page.lua
local FilterGraphic = include(from_root("lib/graphics/FilterGraphic"))

local function create_filter_page(cfg)
    -- cfg contains all filter-specific parameters

    local page_name      = cfg.page_name

    local ENGINE_FREQ    = cfg.engine_freq
    local ENGINE_RES     = cfg.engine_res
    local ENGINE_DRY     = cfg.engine_dry
    local ID_WET         = cfg.id_wet
    local ID_BASE_FREQ   = cfg.id_base_freq
    local FILTER_TYPE    = cfg.filter_graphic_type
    local ID_LFO_ENABLED = cfg.id_lfo_enabled

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

    local function toggle_lfo()
        misc_util.toggle_param(ID_LFO_ENABLED)
    end

    local function cycle_mix()
        misc_util.cycle_param(ID_WET, DRY_WET_TYPES)
    end

    local page = Page:create({
        name = page_name,
        e2 = adjust_freq,
        e3 = adjust_res,
        k2_off = toggle_lfo,
        k3_off = cycle_mix,
    })

    local function action_wet(v)
        if DRY_WET_TYPES[v] == MIX_DRY then
            params:set(ENGINE_DRY, 1)
        elseif DRY_WET_TYPES[v] == MIX_PARALLEL then
            params:set(ENGINE_DRY, 0.5)
        else
            params:set(ENGINE_DRY, 0)
        end
    end

    local function action_base_freq(v)
        if params:get(ID_LFO_ENABLED) == 0 then
            params:set(ENGINE_FREQ, v)
        end
    end

    local function add_params()
        params:set_action(ID_WET, action_wet)
        params:set_action(ID_BASE_FREQ, action_base_freq)
    end

    function page:update_graphics_state()
        local freq            = params:get(ENGINE_FREQ)
        local res             = params:get(ENGINE_RES)
        local drywet          = params:get(ID_WET)
        local base_freq       = params:get(ID_BASE_FREQ)
        local lfo_enabled     = params:get(ID_LFO_ENABLED)

        -- render non-modulated frequency
        self.graphic:set("freq", params:get(ID_BASE_FREQ))
        self.graphic:set("lfo_freq", freq)
        self.graphic:set("res", res)
        self.graphic:set("type", FILTER_TYPE)
        self.graphic:set("mix", (drywet - 1) / 2)

        self.footer:set_name("e2", "FREQ")
        self.footer:set_value("e2", misc_util.trim(tostring(base_freq), 5))
        self.footer:set_value("k2", lfo_enabled == 1 and "ON" or "OFF")
        self.footer:set_value("k3", DRY_WET_TYPES[drywet])
        self.footer:set_value("e3", misc_util.trim(tostring(res), 5))
    end

    function page:initialize()
        add_params()
        self.graphic = FilterGraphic:new()
        self.graphic:set_size(62, 27)
        self.graphic:set("draw_lfo_range", false)
        local w = 62
        local h = 27
        local screen_width = 128
        self.graphic:set_size(w, h)
        self.graphic:set("x", screen_width / 2 - w / 2)

        self.graphic:set("lfo_freq", params:get(ID_BASE_FREQ))

        self.footer = Footer:new({
            button_text = {
                k2 = { name = "LFO", value = "" },
                k3 = { name = "MIX", value = "" },
                e2 = { name = "FREQ", value = "" },
                e3 = { name = "RES", value = "" },
            },
            font_face = FOOTER_FONT,
        })
    end

    function page:enter()
        window.title = page_name
    end

    return page
end

return create_filter_page
