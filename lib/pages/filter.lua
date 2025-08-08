local page_name = "FILTER"
local window
local FilterGraphic = include("bits/lib/graphics/FilterGraphic")
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

local function e2(d)
    adjust_freq(d)
end

local function toggle_type()
    local p = ID_FILTER_TYPE
    local curr = params:get(p)
    params:set(p, util.wrap(curr + 1, 1, #FILTER_TYPES))
end

local page = Page:create({
    name = page_name,
    e2 = e2,
    e3 = adjust_res,
    k2_off = toggle_type,
    k3_off = nil,
})

local function add_params()
    params:set_action(ID_FILTER_FREQ, function(v) engine.freq(v) end)
    params:set_action(ID_FILTER_TYPE, function(v) engine.set_filter_type(FILTER_TYPES[v]) end)
    params:set_action(ID_FILTER_RES, function(v) engine.res(v) end)
end

function page:render()
    window:render()
    local freq = params:get(ID_FILTER_FREQ)
    local res = params:get(ID_FILTER_RES)
    local filter_type = params:get(ID_FILTER_TYPE)
    filter_graphic.freq = freq
    filter_graphic.res = res
    filter_graphic.type = filter_type
    filter_graphic:render()
    page.footer.button_text.k2.value = FILTER_TYPES[filter_type]
    if FILTER_TYPES[filter_type] ~= "NONE" then
        page.footer.button_text.e2.name = "FREQ"
        page.footer.button_text.e3.name = "RES"
        page.footer.button_text.e2.value = misc_util.trim(tostring(freq), 5)
        page.footer.button_text.e3.value = misc_util.trim(tostring(res), 5)
    else
        page.footer.button_text.e2.name = ""
        page.footer.button_text.e3.name = ""
        page.footer.button_text.e2.value = ""
        page.footer.button_text.e3.value = ""
    end
    page.footer:render()
end

function page:initialize()
    add_params()
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "FILTER",
        font_face = TITLE_FONT,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    -- graphics
    filter_graphic = FilterGraphic:new()

    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "TYPE",
                value = "",
            },
            k3 = {
                name = "",
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
