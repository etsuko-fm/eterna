local page_name = "FILTER"
local window
local FilterGraphic = include("symbiosis/lib/graphics/FilterGraphic")
local filter_graphic
local function adjust_freq(d)
    local p = ID_FILTER_FREQ
    local new_val = params:get_raw(p) + d * controlspec_filter_freq.quantum
    params:set_raw(p, new_val)
end

local function adjust_res(d)
    local new_val = params:get(ID_FILTER_RES) + d * controlspec_filter_res.quantum
    params:set(ID_FILTER_RES, new_val, false)
end

local function toggle_type()
    local p = ID_FILTER_TYPE
    local curr = params:get(p)
    params:set(p, util.wrap(curr + 1, 1, #FILTER_TYPES))
end
local function toggle_drywet()
    local p = ID_FILTER_WET
    local curr = params:get(p)
    params:set(p, util.wrap(curr + 1, 1, #DRY_WET_TYPES))
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
    params:set_action(ID_FILTER_FREQ, function(v) engine.filter_freq(v) end)
    params:set_action(ID_FILTER_TYPE, function(v) engine.filter_type(FILTER_TYPES[v]) end)
    params:set_action(ID_FILTER_RES, function(v) engine.filter_res(v) end)
    params:set_action(ID_FILTER_WET, action_wet)
end

function page:render()
    self.window:render()
    local freq = params:get(ID_FILTER_FREQ)
    local res = params:get(ID_FILTER_RES)
    local filter_type = params:get(ID_FILTER_TYPE)
    local drywet = params:get(ID_FILTER_WET)
    filter_graphic.freq = freq
    filter_graphic.res = res
    filter_graphic.type = filter_type
    filter_graphic.mix = (params:get(ID_FILTER_WET) - 1) / 2 -- 1/2/3 is 0/0.5/1
    filter_graphic:render()
    page.footer.button_text.k2.value = FILTER_TYPES[filter_type]
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
            k2 = {
                name = "TYPE",
                value = "",
            },
            k3 = {
                name = "MIX",
                value = "",
            },
            e2 = {
                name = "FREQ",
                value = "",
            },
            e3 = {
                name = "RES",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })
end

return page
