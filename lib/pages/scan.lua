local Page = include("bits/lib/pages/Page")
local page_name = "Scan"
local Window = include("bits/lib/graphics/Window")
local Toggle = include("bits/lib/graphics/Toggle")
local TextParam = include("bits/lib/graphics/TextParam")
local Slider = include("bits/lib/graphics/Slider")
local GaussianBars = include("bits/lib/graphics/GaussianBars")

-- graphics settings
local scan_bar_width = 72 -- dividable by 6 and 8
local scan_bar_height = 4
local window_left_width = 96
local offsetx = (window_left_width - scan_bar_width) / 2
local offsety = 44
local margin = 4
local bar_width = 6
local num_bars = 6
local level_height = 24
local sigma_min = 0.3
local sigma_max = 15
-- these graphics are initialized in page:initialize
local h_slider
local v_slider
local bars




--[[
Scan page
Graphics:
- 6 vertical bars that show the level of each softcut voice
- 1 horizontal bar that shows the current scan value
- Temporary: digit w level of each voice

Interactions:
 E2: adjust sigma (standard deviation) of gaussian curve
 E3: adjust scan value
 todo:
 K2: cycle through sigma values
 K3: cycle through scan values
]]
local window_index = 1

local function cycle_window_forward(state)
    -- Increment the current index, reset to 1 if it exceeds table length
    window_index = (window_index % #state.scan.windows) + 1
    for n, window in ipairs(state.scan.windows) do
        state.scan.windows[n].selected = n == window_index
    end
end

local window_scan = Window:new({
    x = 0,
    y = 0,
    w = 96,
    h = 64,
    title = "SCAN",
    font_face = 68,
    brightness = 15,
    border = true,
    selected = true,
    horizontal_separations = 0,
    vertical_separations = 0,
})

local window_lfo = Window:new({
    x = 98,
    y = 0,
    w = 30,
    h = 64,
    title = "LFO",
    font_face = 68,
    brightness = 15,
    border = true,
    selected = false,
    horizontal_separations = 0,
    vertical_separations = 1,
})

local toggle = Toggle:new({
    x = 103,
    y = 17,
    size = 4
})

local lfo_rate = TextParam:new({
    x = 103,
    y = 50,
    val = 30,
    unit = ' Hz',
})


-- Function to calculate x and y positions based on time parameter
local function figure_eight(t, width, height)
    local x = width * math.sin(t)          -- X follows a sine wave
    local y = height * math.sin(2 * t) / 2 -- Y follows a sine wave with twice the frequency
    return x, y
end


local function adjust_param(tbl, param, d, mult, min, max, loop)
    -- todo: unify with adjust_param in timecontrols
    local fraction = d * mult
    if min == nil then min = 0 end
    if max == nil then max = 128 end
    if loop then
        tbl[param] = (tbl[param] + fraction) % max
    elseif tbl[param] + fraction < min then
        tbl[param] = min
    elseif tbl[param] + fraction > max then
        tbl[param] = max
    else
        tbl[param] = tbl[param] + fraction
    end
    return tbl[param] -- for inspection
end

local function gaussian_scan(state, d)
    adjust_param(state, 'scan_val', d, 1 / 60, 0, 1, true)
    h_slider.val = state.scan_val
    bars.scan_val = state.scan_val
end

local function map_sigma(v)
    return util.linlin(sigma_min, sigma_max, 0, 1, v)
end

local function adjust_sigma(state, d)
    -- call this function with d=0 to update the state of the gaussian bars graphic and both sliders
    local k = (10 ^ math.log(state.sigma, 10)) / 25
    adjust_param(state, 'sigma', d, k, sigma_min, sigma_max, false)
    v_slider.val = map_sigma(state.sigma)
    bars.sigma = state.sigma -- update bars graphic, as it renders the bars based on sigma
end

local function toggle_lfo(state)
    if toggle.on then
        state.scan_lfo:stop()
        print('stop phase: '..state.scan_lfo:get('phase'))
    else
        print('start phase: '..state.scan_lfo:get('phase'))
        state.scan_lfo:start()
    end
    toggle.on = not toggle.on
end

local function adjust_lfo_rate(state, d)
    lfo_rate.val = lfo_rate.val + d
end

local function e2(state, d)
    if state.scan.windows[1].selected == true then
        gaussian_scan(state, d)
    else
        toggle_lfo(state)
    end
end

local function e3(state, d)
    if state.scan.windows[1].selected == true then
        adjust_sigma(state, d)
    else
        adjust_lfo_rate(state, d)
    end
end

local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = e2,
    e3 = e3,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = cycle_window_forward,
    k3_on = nil,
    k3_off = cycle_window_forward,
})

function page:render(state)
    -- todo: this should be a graphic component, the entire thing belongs together
    screen.clear()

    -- window
    window_scan:render()
    window_lfo:render()

    -- slider
    h_slider:render()
    v_slider:render()

    -- 6 bars
    bars.levels = state.levels
    bars:render()
    for i = 1, 6 do
        softcut.level(i, state.levels[i])
    end

    -- lfo toggle
    toggle:render()

    -- lfo halfline
    -- screen.move(99, 34)
    -- screen.line(127,34)
    -- screen.stroke()

    -- lfo HZ
    lfo_rate:render()

    -- fig8
    screen.move(64, 64)

    local size = 10
    local x, y = figure_eight(state.scan_val * math.pi * 2, 10, 10)
    screen.level(15)

    -- screen.move(56, 64)
    -- screen.text(state.scan_val)
    screen.update()
end

function page:initialize(state)
    -- windows
    table.insert(state.scan.windows, window_scan)
    table.insert(state.scan.windows, window_lfo)

    -- graphics
    bars = GaussianBars:new({
        x = offsetx,
        y = offsety - margin,
        bar_width = bar_width,
        max_bar_height = level_height,
        num_bars = num_bars,
        sigma = state.sigma,
        scan_val = state.scan_val,
    })
    h_slider = Slider:new({
        direction = 'HORIZONTAL',
        x = offsetx + 1, -- account for stroke width
        y = offsety,
        w = scan_bar_width - 1,
        h = scan_bar_height,
        dash_size = 2,
        val = state.scan_val,
    })
    v_slider = Slider:new({
        direction = 'VERTICAL',
        x = window_left_width - 8,
        y = 16,
        w = 4,
        h = level_height,
        dash_size = 2,
        val = map_sigma(state.sigma),
    })

    -- lfo
    state.scan_lfo = _lfos:add {
        shape = 'saw',   -- shape
        min = 0,          -- min
        max = 1,          -- max
        depth = 1,        -- depth (0 to 1)
        mode = 'free', -- mode
        period = 6,       -- period (in 'clocked' mode, represents beats)
        -- pass our 'scaled' value (bounded by min/max and depth) to the engine:
        action = function(scaled, raw)
            print('raw: '..raw)
            state.scan_val = scaled
            h_slider.val = scaled
            bars.scan_val = scaled        
        end      -- action, always passes scaled and raw values
    }
end

return page
