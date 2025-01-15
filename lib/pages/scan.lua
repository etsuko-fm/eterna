local Page = include("bits/lib/pages/Page")
local page_name = "Scan"
local Window = include("bits/lib/graphics/Window")
local Slider = include("bits/lib/graphics/Slider")
local GaussianBars = include("bits/lib/graphics/GaussianBars")

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

local window_scan = Window:new({
    x = 0,
    y = 0,
    w = 128,
    h = 64,
    title = "SCAN",
    font_face = 68,
    brightness = 15,
    border = false,
    selected = true,
    horizontal_separations = 0,
    vertical_separations = 0,
})


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

local function map_sigma(state, v)
    return util.linlin(state.sigma_min, state.sigma_max, 0, 1, v)
end

local function adjust_sigma(state, d)
    -- call this function with d=0 to update the state of the gaussian bars graphic and both sliders
    local k = (10 ^ math.log(state.sigma, 10)) / 25
    adjust_param(state, 'sigma', d, k, state.sigma_min, state.sigma_max, false)
    v_slider.val = map_sigma(state, state.sigma)
    bars.sigma = state.sigma -- update bars graphic, as it renders the bars based on sigma
end


local function e2(state, d)
    gaussian_scan(state, d)
end

local function e3(state, d)
    adjust_sigma(state, d)
end

local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = e2,
    e3 = e3,
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

    -- window
    window_scan:render()

    -- slider
    h_slider:render()
    v_slider:render()

    -- 6 bars
    state.levels = bars.levels
    bars:render()
    for i = 1, 6 do
        softcut.level(i, state.levels[i])
    end
end

function page:initialize(state)
    -- windows
    table.insert(state.scan.windows, window_scan)

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
    h_slider = Slider:new({
        direction = 'HORIZONTAL',
        x = state.graph_x + 1, -- account for stroke width
        y = state.graph_y,
        w = state.graph_width - state.bar_width - 3,
        h = 3,
        dash_size = 1,
        val = state.scan_val,
        hide=true,
    })
    v_slider = Slider:new({
        direction = 'VERTICAL',
        x = state.window_width - 8,
        y = 16,
        w = 2,
        h = state.bar_height,
        dash_size = 1,
        val = map_sigma(state, state.sigma),
        hide=true,
    })

end

return page
