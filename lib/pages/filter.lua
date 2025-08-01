local page_name = "FILTER"
local window
local filter_lfo

local function toggle_lfo()
    params:set(ID_FILTER_LFO_ENABLED, 1 - filter_lfo:get("enabled"), false)
end

local function toggle_shape()
    local index = params:get(ID_FILTER_LFO_SHAPE)
    local next_index = (index % #FILTER_LFO_SHAPES) + 1
    params:set(ID_FILTER_LFO_SHAPE, next_index, false)
end

local function adjust_freq(d)
    local new_val = params:get_raw(ID_FILTER_FREQ) + d * controlspec_filter_freq.quantum
    params:set_raw(ID_FILTER_FREQ, new_val, false)
end

local function adjust_res(d)
    local new_val = params:get(ID_FILTER_RES) + d * controlspec_filter_res.quantum
    params:set(ID_FILTER_RES, new_val, false)
end

local function e2(d)
    if filter_lfo:get("enabled") == 1 then
        lfo_util.adjust_lfo_rate_quant(d, filter_lfo)
    else
        adjust_freq(d)
    end
end

local page = Page:create({
    name = page_name,
    e2 = e2,
    e3 = adjust_res,
    k2_off = toggle_lfo,
    k3_off = toggle_shape,
})

local function action_enable_lfo(v)
    if v == 1 then
        filter_lfo:start()
    else
        filter_lfo:stop()
    end
    filter_lfo:set('phase', params:get(ID_FILTER_FREQ))
end

local function action_lfo_shape(v)
    filter_lfo:set('shape', params:string(ID_FILTER_LFO_SHAPE))
end

local function action_lfo_rate(v)
    filter_lfo:set('period', lfo_util.lfo_period_label_values[params:string(ID_FILTER_LFO_RATE)])
end

local function add_params()
    params:set_action(ID_FILTER_LFO_ENABLED, action_enable_lfo)
    params:set_action(ID_FILTER_LFO_SHAPE, action_lfo_shape)
    params:set_action(ID_FILTER_LFO_RATE, action_lfo_rate)
    params:set_action(ID_FILTER_WET, function(v) engine.wet(v) end)
    params:set_action(ID_FILTER_FREQ, function(v) engine.freq(v) end)
    params:set_action(ID_FILTER_DRIVE, function(v) engine.gain(v) end)
    params:set_action(ID_FILTER_RES, function(v) engine.res(v) end)
end

function page:render()
    window:render()
    screen.move(64,32)
    screen.text_center("filter")
    local freq = params:get(ID_FILTER_FREQ)
    local res = params:get(ID_FILTER_RES)
    if filter_lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        page.footer.button_text.k2.value = "ON"
        page.footer.button_text.e2.name = "RATE"
        -- convert period to label representation
        local period = filter_lfo:get('period')
        page.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]
    else
        -- When LFO is disabled, E2 controls pan position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "FREQ"
        page.footer.button_text.e2.value = misc_util.trim(tostring(freq), 5)
    end
    page.footer.button_text.e3.value = misc_util.trim(tostring(res), 5)
    page.footer.button_text.k3.value = string.upper(filter_lfo:get("shape"))
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
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "LFO",
                value = "",
            },
            k3 = {
                name = "SHAPE",
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
    -- lfo
    filter_lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'clocked',
        period = 8,
        phase = 0,
        action = function(scaled, raw)
            params:set(ID_FILTER_FREQ, controlspec_filter_freq:map(scaled), false)
        end
    }
    filter_lfo:set('reset_target', 'mid: rising')
end

return page
