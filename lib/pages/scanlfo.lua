local Page = include("bits/lib/pages/Page")
local page_name = "ScanLfo"
local Window = include("bits/lib/graphics/Window")
local Slider = include("bits/lib/graphics/Slider")
local GaussianBars = include("bits/lib/graphics/GaussianBars")
local Toggle = include("bits/lib/graphics/Toggle")
local TextParam = include("bits/lib/graphics/TextParam")

local toggle
local lfo_rate_graphic
local window_scan_lfo = Window:new({
    x = 0,
    y = 0,
    w = 128,
    h = 64,
    title = "SCAN: LFO",
    font_face = 68,
    brightness = 15,
    border = false,
    selected = true,
    horizontal_separations = 0,
    vertical_separations = 0,
})

local bars

local function toggle_lfo(state)
    if toggle.on then
        state.scan_lfo:stop()
    else
        state.scan_lfo:start()
        state.scan_lfo:set('phase', state.scan_val)
    end
    toggle.on = not toggle.on
end

local function adjust_lfo_rate(state, d)
    new_val = state.scan_lfo:get('period') + (d / 4)
    if new_val < 1 / 4 then
        new_val = 1 / 4
    end
    state.scan_lfo:set('period', new_val)
    state.scan_lfo_period = new_val
    lfo_rate_graphic.val = new_val
end

local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = nil,
    e3 = nil,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = nil,
    k3_on = nil,
    k3_off = nil,
})

function page:render(state)
    -- todo: this should be a graphic component, the entire thing belongs together
    screen.clear()
    bars:render()

    -- window
    window_scan_lfo:render()
end

function page:initialize(state)
    -- graphics
    bars = GaussianBars:new({
        x = state.graph_x,
        y = state.graph_y,
        bar_width = state.bar_width,
        max_bar_height = state.bar_height,
        num_bars = state.num_bars,
        sigma = state.sigma,
        scan_val = state.scan_val,
        brightness=15,
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
        -- pass our 'scaled' value (bounded by min/max and depth) to the engine:
        action = function(scaled, raw)
            state.scan_val = scaled
            bars.scan_val = scaled
        end
    }
    state.scan_lfo:set('reset_target', 'mid: rising')
end

return page