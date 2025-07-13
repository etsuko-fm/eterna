local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local PanningGraphic = include("bits/lib/graphics/PanningGraphic")
local misc_util = include("bits/lib/util/misc")
local lfo_util = include("bits/lib/util/lfo")

local page_name = "PANNING"
local window
local panning_graphic
local panning_lfo

local function calculate_pan_positions()
    local twist = params:get(ID_PANNING_TWIST)
    local spread = params:get(ID_PANNING_SPREAD)
    for i = 0, 5 do
        local voice = i + 1
        local angle = (twist + i / 6) * (math.pi * 2) -- Divide the range of radians into 6 equal parts, add offset
        local pan =  spread * math.cos(angle)
        softcut.pan(voice, pan)
        panning_graphic.pans[voice] = pan
    end
end

local function adjust_spread(d)
    local new_val = params:get(ID_PANNING_SPREAD) + d * controlspec_pan_spread.quantum
    params:set(ID_PANNING_SPREAD, new_val, false)
end

local function adjust_twist(d)
    local new_val = params:get(ID_PANNING_TWIST) + d * controlspec_pan_twist.quantum
    params:set(ID_PANNING_TWIST, new_val, false)
end

local function toggle_lfo()
    params:set(ID_PANNING_LFO_ENABLED, 1 - panning_lfo:get("enabled"), false)
end

local function toggle_shape()
    local index = params:get(ID_PANNING_LFO_SHAPE)
    local next_index = (index % #PANNING_LFO_SHAPES) + 1
    params:set(ID_PANNING_LFO_SHAPE, next_index, false)
end

local function e2(d)
    if panning_lfo:get("enabled") == 1 then
        lfo_util.adjust_lfo_rate_quant(d, panning_lfo)
    else
        adjust_twist(d)
    end
end

local page = Page:create({
    name = page_name,
    e2 = e2,
    e3 = adjust_spread,
    k2_off = toggle_lfo,
    k3_off = toggle_shape,
})

local function action_enable_lfo(v)
    if panning_lfo:get("enabled") == 1 then
        panning_lfo:stop()
    else
        panning_lfo:start()
    end
    panning_lfo:set('phase', params:get(ID_PANNING_TWIST))
end

local function action_lfo_shape(v)
    panning_lfo:set('shape', params:string(ID_PANNING_LFO_SHAPE))
end

local function action_lfo_rate(v)
    panning_lfo:set('period', lfo_util.lfo_period_label_values[params:string(ID_PANNING_LFO_RATE)])
end

local function add_params()
    params:set_action(ID_PANNING_LFO_ENABLED, action_enable_lfo)
    params:set_action(ID_PANNING_LFO_SHAPE, action_lfo_shape)
    params:set_action(ID_PANNING_LFO_RATE, action_lfo_rate)
    params:set_action(ID_PANNING_TWIST, calculate_pan_positions)
    params:set_action(ID_PANNING_SPREAD, calculate_pan_positions)
end

function page:render()
    window:render()
    local twist = params:get(ID_PANNING_TWIST)
    local spread = params:get(ID_PANNING_SPREAD)
    panning_graphic:render()
    if panning_lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        page.footer.button_text.k2.value = "ON"
        page.footer.button_text.e2.name = "RATE"
        -- convert period to label representation
        local period = panning_lfo:get('period')
        page.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]
    else
        -- When LFO is disabled, E2 controls pan position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "TWIST"
        page.footer.button_text.e2.value = misc_util.trim(tostring(twist), 5)
    end
    page.footer.button_text.e3.value = misc_util.trim(tostring(spread), 5)
    page.footer.button_text.k3.value = string.upper(panning_lfo:get("shape"))
    page.footer:render()
end

function page:initialize()
    add_params()
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "PANNING",
        font_face = TITLE_FONT,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    -- graphics
    panning_graphic = PanningGraphic:new()
    calculate_pan_positions()
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
                name = "TWIST",
                value = "",
            },
            e3 = {
                name = "WIDTH",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })
    -- lfo
    panning_lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'clocked',
        period = 8,
        phase = 0,
        action = function(scaled, raw)
            params:set(ID_PANNING_TWIST, controlspec_pan_twist:map(scaled), false)
        end
    }
    panning_lfo:set('reset_target', 'mid: rising')
end

return page
