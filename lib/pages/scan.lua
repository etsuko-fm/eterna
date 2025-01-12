local Page = include("bits/lib/pages/Page")
local page_name = "Scan"
local Window = include("bits/lib/graphics/Window")
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
    w = 96,
    h = 64,
    title="SCAN",
    font_face=68,
    brightness=15,
    border=true,
    selected=true,
    horizontal_separations=0,
    vertical_separations=0,
})

local window_lfo = Window:new({
    x = 98,
    y = 0,
    w = 30,
    h = 64,
    title="LFO",
    font_face=68,
    brightness=15,
    border=true,
    selected=false,
    horizontal_separations=0,
    vertical_separations=1,
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

local function calculate_gaussian_levels(state)
    -- convert state.scan_val to levels for each softcut voice
    local num_voices = 6
    for i = 1, num_voices do
        -- translate scan value to a virtual 'position' so that it matches the voice range (1 <= pos <= num_voices)
        local pos = 1 + (state.scan_val * (num_voices))

        -- the 'distance' from the current voice to the scan position
        -- ex: scan pos 1, voice 5: abs(1 - 5) = abs(-4) = 4
        -- ex: scan pos 5, voice 1: abs(5 - 1)) = abs(4) = 4
        -- local distance = math.abs(pos - i) -- 0 <= distance <= 5
        local distance = math.min(
            math.abs(pos - i),
            num_voices - math.abs(pos - i)
        )

        -- Calculate the level for the current voice using a Gaussian formula:
        -- level = e^(-(distance^2) / (2 * sigma^2))
        -- where distance^2 makes farther voices quieter.
        -- where sigma controls how "wide" the Gaussian curve is (how quickly levels fade).
        local level = math.exp(-(distance ^ 2) / (2 * state.sigma ^ 2)) -- 0 <= level <= 1

        -- update levels in global state
        state.levels[i] = level
        -- print('distance['..i..'] = ' .. distance .. ', level['..i..'] = ' .. level)
    end
end

local function gaussian_scan(state, d)
    -- you need to invoke this logic in the main script to create a good starting condition.. or page.initialize()
    adjust_param(state, 'scan_val', d, 1 / 60, 0, 1, true)
    calculate_gaussian_levels(state)
end



local function adjust_sigma(state, d)
    adjust_param(state, 'sigma', d, .1, 0.3, 10)
    gaussian_scan(state, 0) --update scan to reflect new curve in state
end

local function switch_window(state)
    local n = nil
    for _, window in ipairs(state.scan.windows) do
        if window.selected == true then
            window.selected = false
            n = _
        end
    end
end



local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = gaussian_scan,
    e3 = adjust_sigma,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = switch_window,
    k2_off = nil,
    k3_on = nil,
    k3_off = nil,
})


function page:render(state)
    -- todo: this should be a graphic component, the entire thing belongs together
    screen.clear()
    local scan_bar_width = 72 -- dividable by 6 and 8
    local offsetx = (96 - scan_bar_width) / 2
    local offsety = 44
    local margin = 4
    local bar_width = 6
    local num_bars = 6
    local dash_width = 2
    local scan_bar_height = 4
    local level_height = 24

    -- window
    window_scan:render()
    window_lfo:render()

    -- rect for scanning
    screen.level(15)
    screen.line_width(1)
    screen.rect(offsetx+1, offsety, scan_bar_width-1, scan_bar_height)
    screen.stroke() -- stroke might give it a pixel extra compared to fill

    -- dash (scan pos)
    screen.level(10)
    screen.rect(offsetx + (state.scan_val * (scan_bar_width - dash_width)), offsety, dash_width, scan_bar_height)
    screen.move(10, 10)

    -- 6 bars
    for i = 0, 5 do
        -- total width of bars should be equal to scan_bar_width.
        screen.move(i * 20, 10)
        --screen.text(string.format("%.2f", state.levels[i + 1]))
        screen.rect(
            offsetx + (i * (scan_bar_width - bar_width) / (num_bars - 1)),
            offsety - margin,
            bar_width,
            -level_height * state.levels[i + 1]
        )
        screen.fill()
        softcut.level(i, state.levels[i + 1])
    end

    -- lfo toggle
    screen.rect(103, 17, 4, 4)
    screen.move(110, 21)
    screen.text('ON')
    screen.stroke(0)
    

    -- lfo halfline
    -- screen.move(99, 34)
    -- screen.line(127,34)
    -- screen.stroke()
    
    -- lfo HZ
    screen.move(103, 50)
    screen.text("30 Hz")

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
    -- I'm not sure to what extent a page should have business logic like this
    calculate_gaussian_levels(state)
    table.insert(state.scan.windows, window_scan)
    table.insert(state.scan.windows, window_lfo)
end

return page
