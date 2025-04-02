local Page = include("bits/lib/pages/Page")
local Window = include("bits/lib/graphics/Window")
local PanningCircle = include("bits/lib/graphics/PanningCircle")
local state_util = include("bits/lib/util/state")
local misc_util = include("bits/lib/util/misc")

local page_name = "Panning"
local footer
local window

local panning_graphic


local function calculate_pan_positions(state)
    for i = 0, 5 do
        local angle = (i / 6) * math.pi * 2 + state.panning_twist-- Divide full circle into 6 parts
        state.pan_positions[i+1] = state.panning_spread / 8 * math.cos(angle)
    end
    for i = 1, 6 do
        softcut.pan(i, state.pan_positions[i])
    end
end

local function adjust_spread(state, d)
    state_util.adjust_param(state, 'panning_spread', d, 1, 0, 8, false)
    calculate_pan_positions(state)

end

function adjust_twist(state, d)
    state_util.adjust_param(state, 'panning_twist', d/5, 1, 0, math.pi*2, true)
    calculate_pan_positions(state)
end


local function toggle_lfo(state)
    print(state.pan_lfo:get("enabled"))
    if state.pan_lfo:get("enabled") == 1 then
        state.pan_lfo:stop()
    else
        state.pan_lfo:start()
    end
end

local function adjust_lfo_rate(state, d)
    -- todo: code is duplicated with PanningCircle
    local k = (10 ^ math.log(state.pan_lfo:get('period'), 10)) / 50
    local min = 0.2
    local max = 256

    new_val = state.pan_lfo:get('period') + (d * k)
    if new_val < min then
        new_val = min
    end
    if new_val > max then
        new_val = max
    end
    state.pan_lfo:set('period', new_val)
    state.pan_lfo_period = new_val
    footer.active_knob = "e2"
end

local function e2(state, d)
    if state.pan_lfo:get("enabled") == 1 then
        adjust_lfo_rate(state, d)
    else 
        adjust_twist(state, d)
    end
end

local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = e2,
    e3 = adjust_spread,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = toggle_lfo,
    k3_on = nil,
    k3_off = nil,
    footer = footer,
})

function page:render(state)
    screen.clear()
    window:render()
    panning_graphic.w = state.panning_spread
    panning_graphic.twist = state.panning_twist
    panning_graphic:render()
    if state.pan_lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        page.footer.button_text.k2.value = "ON"
        page.footer.button_text.e2.name = "RATE"
        page.footer.button_text.e2.value = misc_util.trim(tostring(state.pan_lfo_period), 5)
    else
        -- When LFO is disabled, E2 controls pan position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "TWIST"
        page.footer.button_text.e2.value = misc_util.trim(tostring( state.panning_twist), 5)
    end
    page.footer.button_text.e3.value = misc_util.trim(tostring(state.panning_spread), 5)
    page.footer:render()
end

function page:initialize(state)
    print("panning initialized")
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "STEREO FIELD",
        font_face = state.title_font,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    -- graphics
    panning_graphic = PanningCircle:new({
        w=state.panning_spread,
    })
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
        font_face = state.footer_font,
    })
    -- lfo
    state.pan_lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'free',
        period = state.pan_lfo_period,
        phase = 0,
        action = function(scaled, raw)
            state.panning_twist = scaled * math.pi * 2
            panning_graphic.twist = state.panning_twist
            calculate_pan_positions(state)
        end
    }
    state.pan_lfo:set('reset_target', 'mid: rising')
    
end

return page