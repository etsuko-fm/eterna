local page_name = "LOWPASS"
local FilterGraphic = include("computer/lib/graphics/FilterGraphic")
local filter_graphic
local lpf_lfo
local ENGINE_LPF_FREQ = mist_engine.get_id("lpf_freq")
local ENGINE_LPF_RES = mist_engine.get_id("lpf_res")
local ENGINE_LPF_DRY = mist_engine.get_id("lpf_dry")
local last_freq

local function adjust_freq(d)
    misc_util.adjust_param(d, ENGINE_LPF_FREQ, mist_engine.params.specs["lpf_freq"].quantum)
end

local function adjust_res(d)
    misc_util.adjust_param(d, ENGINE_LPF_RES, mist_engine.params.specs["lpf_res"].quantum)
end

local function cycle_lfo()
    misc_util.cycle_param(ID_LPF_LFO, LPF_LFO_SHAPES)
end

local function adjust_lfo_rate(d)
    lfo_util.adjust_lfo_rate_quant(d, lpf_lfo)
end

local function toggle_drywet()
    misc_util.cycle_param(ID_LPF_WET, DRY_WET_TYPES)
end

local function e2(d)
    if lpf_lfo:get("enabled") == 1 then
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
        params:set(ENGINE_LPF_DRY, 1)
    elseif DRY_WET_TYPES[v] == "50/50" then
        params:set(ENGINE_LPF_DRY, 0.5)
    else
        params:set(ENGINE_LPF_DRY, 0)
    end
end

local function action_lfo(v)
    lfo_util.action_lfo(v, lpf_lfo, LPF_LFO_SHAPES, params:get(ENGINE_LPF_FREQ))
    if LPF_LFO_SHAPES[v] ~= "off" then
        last_freq = params:get(ENGINE_LPF_FREQ)
    else
        -- action turned off LFO; reset frequency
        params:set(ID_LPF_FREQ_MOD, 1)
        if last_freq then 
            params:set(ENGINE_LPF_FREQ, last_freq)
        end
    end
end

local function action_lfo_rate(v)
    lpf_lfo:set('period', lfo_util.lfo_period_label_values[params:string(ID_LEVELS_LFO_RATE)])
end

local function action_freq_mod(v)
    -- triggers while LFO is active, or when LFO is switched off
    params:set(ENGINE_LPF_FREQ, v * last_freq)
end

local function add_params()
    params:set_action(ID_LPF_FREQ_MOD, action_freq_mod)
    params:set_action(ID_LPF_WET, action_wet)
    params:set_action(ID_LPF_LFO, action_lfo)
    params:set_action(ID_LPF_LFO_RATE, action_lfo_rate)
end

function page:render()
    self.window:render()
    local freq = params:get(ENGINE_LPF_FREQ)
    local res = params:get(ENGINE_LPF_RES)
    local filter_type = 2
    local drywet = params:get(ID_LPF_WET)
    filter_graphic.freq = freq
    filter_graphic.res = res
    filter_graphic.type = filter_type
    filter_graphic.mix = (params:get(ID_LPF_WET) - 1) / 2 -- 1/2/3 is 0/0.5/1
    filter_graphic:render()

    local lfo_state = params:get(ID_LPF_LFO)
    page.footer.button_text.k2.value = string.upper(LPF_LFO_SHAPES[lfo_state])

    if lpf_lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        page.footer.button_text.e2.name = "RATE"

        -- convert period to label representation
        local period = lpf_lfo:get('period')
        page.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]
    else
        -- When LFO is disabled, E2 controls filter freq
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "FREQ"
        -- multiply by 6 because of 6 voices; indicates which voice is fully audible    
        page.footer.button_text.e2.value = misc_util.trim(tostring(freq), 5)
    end

    page.footer.button_text.k3.value = DRY_WET_TYPES[drywet]
    page.footer.button_text.e3.value = misc_util.trim(tostring(res), 5)
    page.footer:render()
end

function page:initialize()
    last_freq = params:get(ENGINE_LPF_FREQ)
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

    lpf_lfo = _lfos:add {
        shape = 'sine',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'clocked',
        period = 8,
        phase = 0,
        action = function(scaled, raw)
            params:set(ID_LPF_FREQ_MOD, controlspec_lpf_freq_mod:map(scaled), false)
        end
    }
    lpf_lfo:set('reset_target', 'mid: rising')
end

return page
