-- filter_page.lua
local FilterGraphic = include(from_root("lib/graphics/FilterGraphic"))

local function create_filter_page(cfg)
    -- cfg contains all filter-specific parameters

    local page_name = cfg.page_name
    local filter_graphic

    local ENGINE_FREQ = cfg.engine_freq
    local ENGINE_RES  = cfg.engine_res
    local ENGINE_DRY  = cfg.engine_dry
    local ID_WET      = cfg.id_wet
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

    local function toggle_drywet()
        misc_util.cycle_param(ID_WET, DRY_WET_TYPES)
    end

    local page = Page:create({
        name = page_name,
        e2 = adjust_freq,
        e3 = adjust_res,
        k2_off = nil,
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

    local function add_params()
        params:set_action(ID_WET, action_wet)
    end

    function page:render()
        self.window:render()
        self:render_graphic()
        self:render_footer()
    end

    function page:render_graphic(draw_lfo_range)
        local freq = params:get(ENGINE_FREQ)
        local res  = params:get(ENGINE_RES)
        local drywet = params:get(ID_WET)

        filter_graphic.freq = freq
        filter_graphic.res  = res
        filter_graphic.type = FILTER_TYPE
        filter_graphic.mix  = (drywet - 1) / 2
        filter_graphic:render(draw_lfo_range)
    end

    function page:render_footer()
        local freq = params:get(ENGINE_FREQ)
        local drywet = params:get(ID_WET)
        local res  = params:get(ENGINE_RES)

        self.footer.button_text.e2.name = "FREQ"
        self.footer.button_text.e2.value = misc_util.trim(tostring(freq), 5)
        self.footer.button_text.k3.value = DRY_WET_TYPES[drywet]
        self.footer.button_text.e3.value = misc_util.trim(tostring(res), 5)
        self.footer:render()
    end

    function page:initialize()
        add_params()

        self.window = Window:new({ title = page_name, font_face = TITLE_FONT })
        filter_graphic = FilterGraphic:new()

        self.footer = Footer:new({
            button_text = {
                k2 = { name = "LFO", value = "" },
                k3 = { name = "MIX", value = "" },
                e2 = { name = "FREQ", value = "" },
                e3 = { name = "RES",  value = "" },
            },
            font_face = FOOTER_FONT,
        })
    end

    return page
end

return create_filter_page
