local page_name = "FILTER"
local FilterGraphic = include("symbiosis/lib/graphics/FilterGraphic")
local filter_graphic

local function adjust_freq(d)
    misc_util.adjust_param(d, ID_LPF_FREQ, controlspec_filter_freq)
end

local function adjust_res(d)
    misc_util.adjust_param(d, ID_LPF_RES, controlspec_filter_res)
end

local function cycle_lfo()
    misc_util.cycle_param(ID_LPF_, FILTER_LFO_SHAPES)
end

local function adjust_lfo_rate(d)
    lfo_util.adjust_lfo_rate_quant(d, levels_lfo)
end

local function toggle_drywet()
    misc_util.cycle_param(ID_LPF_WET, DRY_WET_TYPES)
end

local page = Page:create({
    name = page_name,
    e2 = adjust_freq,
    e3 = adjust_res,
    k2_off = toggle_type,
    k3_off = toggle_drywet,
})

local function action_wet(v)
    if DRY_WET_TYPES[v] == "DRY" then
        engine.filter_dry(1)
    elseif DRY_WET_TYPES[v] == "50/50" then
        engine.filter_dry(.5)
    else
        engine.filter_dry(0)
    end
end

local function add_params()
    params:set_action(ID_LPF_FREQ, function(v) engine.filter_freq(v) end)
    params:set_action(ID_LPF_RES, function(v) engine.filter_res(v) end)
    params:set_action(ID_LPF_WET, action_wet)
end

function page:render()
    self.window:render()
    local freq = params:get(ID_LPF_FREQ)
    local res = params:get(ID_LPF_RES)
    local filter_type = 2 
    local drywet = params:get(ID_LPF_WET)
    filter_graphic.freq = freq
    filter_graphic.res = res
    filter_graphic.type = filter_type
    filter_graphic.mix = (params:get(ID_LPF_WET) - 1) / 2 -- 1/2/3 is 0/0.5/1
    filter_graphic:render()
    -- page.footer.button_text.k2.value = FILTER_TYPES[filter_type]
    page.footer.button_text.e2.name = "FREQ"
    page.footer.button_text.e3.name = "RES"
    page.footer.button_text.k3.name = "MIX"
    page.footer.button_text.k3.value = DRY_WET_TYPES[drywet]
    page.footer.button_text.e2.value = misc_util.trim(tostring(freq), 5)
    page.footer.button_text.e3.value = misc_util.trim(tostring(res), 5)
    page.footer:render()
end

function page:initialize()
    add_params()
    self.window = Window:new({ title = page_name, font_face = TITLE_FONT })
    -- graphics
    filter_graphic = FilterGraphic:new()

    page.footer = Footer:new({
        button_text = {
            k2 = { name = "LFO", value = "" },
            k3 = { name = "MIX", value = "" },
            e2 = { name = "FREQ", value = "" },
            e3 = { name = "RES", value = "" },
        },
        font_face = FOOTER_FONT,
    })
end

return page
