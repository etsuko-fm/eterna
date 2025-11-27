local PanningGraphic = include(from_root("lib/graphics/PanningGraphic"))
local page_name = "PANNING"
local panning_graphic
local lfo

local function calculate_pan_positions()
    local twist = params:get(ID_PANNING_TWIST)
    local spread = params:get(ID_PANNING_SPREAD)
    for i = 0, 5 do
        local voice = i + 1
        local angle = (twist + i / 6) * (math.pi * 2) -- Divide the range of radians into 6 equal parts, add offset
        local pan = spread * math.cos(angle)
        local voice_pan = engine_lib.get_id("voice_pan", voice)
        params:set(voice_pan, pan)
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

local function cycle_lfo_shape()
    misc_util.cycle_param(ID_PANNING_LFO_SHAPE, PANNING_LFO_SHAPES)
end

local function toggle_lfo()
    misc_util.toggle_param(ID_PANNING_LFO_ENABLED)
end

local function e2(d)
    if lfo:get("enabled") == 1 then
        lfo_util.adjust_lfo_rate_quant(d, lfo)
    else
        adjust_twist(d)
    end
end

local page = Page:create({
    name = page_name,
    e2 = e2,
    e3 = adjust_spread,
    k2_off = toggle_lfo,
    k3_off = cycle_lfo_shape,
})

local function action_lfo_toggle(v)
    lfo_util.action_lfo_toggle(v, lfo, params:get(ID_PANNING_TWIST))
end


local function action_lfo_rate(v)
    lfo:set('period', lfo_util.lfo_period_label_values[params:string(ID_PANNING_LFO_RATE)])
end

local function action_lfo_shape(v)
    lfo_util.action_lfo_shape(v, lfo, PANNING_LFO_SHAPES, params:get(ID_PANNING_TWIST))
end


local function add_params()
    params:set_action(ID_PANNING_LFO_ENABLED, action_lfo_toggle)
    params:set_action(ID_PANNING_LFO_SHAPE, action_lfo_shape)
    params:set_action(ID_PANNING_LFO_RATE, action_lfo_rate)
    params:set_action(ID_PANNING_TWIST, calculate_pan_positions)
    params:set_action(ID_PANNING_SPREAD, calculate_pan_positions)
end

function page:render()
    self.window:render()
    local lfo_shape = params:get(ID_PANNING_LFO_SHAPE)
    local twist = params:get(ID_PANNING_TWIST)
    local spread = params:get(ID_PANNING_SPREAD)
    panning_graphic:render()
    local lfo_enabled = params:get(ID_PANNING_LFO_ENABLED)
    self.footer.button_text.k2.value = lfo_enabled == 1 and "ON" or "OFF"
    page.footer.button_text.k3.value = string.upper(PANNING_LFO_SHAPES[lfo_shape])
    if lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate

        page.footer.button_text.e2.name = "RATE"
        -- convert period to label representation
        local period = lfo:get('period')
        page.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]
    else
        -- When LFO is disabled, E2 controls pan position
        page.footer.button_text.e2.name = "TWIST"
        page.footer.button_text.e2.value = misc_util.trim(tostring(twist), 5)
    end
    page.footer.button_text.e3.value = misc_util.trim(tostring(spread), 5)
    page.footer:render()
end

function page:initialize()
    add_params()
    self.window = Window:new({ title = page_name, font_face = TITLE_FONT })
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
    lfo = _lfos:add {
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
    lfo:set('reset_target', 'mid: rising')
end

return page
