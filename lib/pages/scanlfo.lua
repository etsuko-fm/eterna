local Page = include("bits/lib/pages/Page")
local page_name = "ScanLfo"
local Window = include("bits/lib/graphics/Window")
local Slider = include("bits/lib/graphics/Slider")
local GaussianBars = include("bits/lib/graphics/GaussianBars")
local Toggle = include("bits/lib/graphics/Toggle")
local TextParam = include("bits/lib/graphics/TextParam")
local gaussian = include("bits/lib/util/gaussian")

local toggle
local lfo_rate_graphic
local window_scan_lfo = Window:new({
    x = 0,
    y = 0,
    w = 128,
    h = 64,
    title = "SCAN: LFO",
    font_face = 1,
    brightness = 15,
    border = false,
    selected = true,
    horizontal_separations = 0,
    vertical_separations = 0,
})

local bars
local function map_sigma(state, v)
    return util.linlin(state.sigma_min, state.sigma_max, 0, 1, v)
end

local footer = Footer:new({
    e1 = "rate",
    e2 = "",
    k2 = "ON"
})


local function toggle_lfo(state)
    footer.active_knob = "k2"
    if toggle.on then
        state.scan_lfo:stop()
    else
        state.scan_lfo:start()
        state.scan_lfo:set('phase', state.scan_val)
    end
    toggle.on = not toggle.on
end

local function adjust_lfo_rate(state, d)
    local k = (10 ^ math.log(state.scan_lfo:get('period'), 10)) / 50
    local min = 0.2
    local max = 256

    new_val = state.scan_lfo:get('period') + (d*k)
    if new_val < min then
        new_val = min
    end
    if new_val > max then
        new_val = max
    end
    state.scan_lfo:set('period', new_val)
    state.scan_lfo_period = new_val
    footer.active_knob = "e2"
end

local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = adjust_lfo_rate,
    e3 = nil,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = toggle_lfo,
    k3_on = nil,
    k3_off = nil,
})

function page:render(state)
    -- todo: this should be a graphic component, the entire thing belongs together
    h_slider.val = state.scan_val
    state.levels = gaussian.calculate_gaussian_levels(state.scan_val, state.sigma)
    bars.levels = state.levels
    screen.clear()
    bars:render()
    h_slider:render()
    -- toggle:render()
    -- lfo_rate_graphic:render()
    window_scan_lfo:render()
    footer.e1 = string.format("%.2f", state.scan_lfo_period)
    if toggle.on then
        footer.k2 = "OFF"
    else
        footer.k2 = "ON"
    end
    footer:render()
end

function page:initialize(state)
    -- graphics
    bars = GaussianBars:new({
        x = state.graph_x,
        y = state.graph_y,
        bar_width = state.bar_width,
        max_bar_height = state.bar_height,
        num_bars = state.num_bars,
        brightness=15,
    })
    h_slider = Slider:new({
        direction = 'HORIZONTAL',
        x = state.graph_x,
        y = state.graph_y + 3,
        w = state.graph_width,
        h = 3,
        dash_size = 1,
        dash_fill=5,
        val = state.scan_val,
    })
    lfo_rate_graphic = TextParam:new({
        x = 103,
        y = 50,
        val = state.scan_lfo_period,
        unit = '',
    })
    bars.levels = state.levels

    toggle = Toggle:new({
        x = state.graph_x + 1,
        y = state.graph_y + 18,
        size = 4
    })

    -- lfo
    state.scan_lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'free',
        period = state.scan_lfo_period,
        phase = 0,
        action = function(scaled, raw)
            state.scan_val = scaled
            bars.scan_val = scaled
        end
    }
    state.scan_lfo:set('reset_target', 'mid: rising')
end

return page