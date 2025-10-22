local PanningGraphic = include("symbiosis/lib/graphics/PanningGraphic")
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
        engine.pan(i, pan)
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

local function cycle_lfo()
    local p = ID_PANNING_LFO
    local new_val = util.wrap(params:get(p) + 1, 1, #SLICES_LFO_SHAPES)
    params:set(p, new_val)
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
    k2_off = cycle_lfo,
    k3_off = nil,
})

local function action_lfo(v)
    lfo_util.action_lfo(v, panning_lfo, PANNING_LFO_SHAPES, params:get(ID_PANNING_TWIST))
end

local function action_lfo_rate(v)
    panning_lfo:set('period', lfo_util.lfo_period_label_values[params:string(ID_PANNING_LFO_RATE)])
end

local function add_params()
    params:set_action(ID_PANNING_LFO, action_lfo)
    params:set_action(ID_PANNING_LFO_RATE, action_lfo_rate)
    params:set_action(ID_PANNING_TWIST, calculate_pan_positions)
    params:set_action(ID_PANNING_SPREAD, calculate_pan_positions)
end

function page:render()
    self.window:render()
    local lfo_state = params:get(ID_PANNING_LFO)
    local twist = params:get(ID_PANNING_TWIST)
    local spread = params:get(ID_PANNING_SPREAD)
    panning_graphic:render()
    page.footer.button_text.k2.value = string.upper(PANNING_LFO_SHAPES[lfo_state])
    if panning_lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate

        page.footer.button_text.e2.name = "RATE"
        -- convert period to label representation
        local period = panning_lfo:get('period')
        page.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]
    else
        -- When LFO is disabled, E2 controls pan position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "TWIST"
        page.footer.button_text.e2.value = misc_util.trim(tostring(twist), 5)

        -- Hide LFO shape button
        page.footer.button_text.k3.name = ""
        page.footer.button_text.k3.value = ""
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
