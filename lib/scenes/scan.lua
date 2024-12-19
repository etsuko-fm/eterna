local Scene = include("bits/lib/scenes/Scene")
local scene_name = "Scan"

local lstate = {
    scan_val = 0, -- 0 to 1
    levels = { 1, 1, 1, 1, 1, 1 },
    sigma = 1,-- Width of the gaussian curve, adjustable for sharper or broader curves
}

local function adjust_param(state, param, d, mult, min, max)
    local fraction = d * mult
    if min == nil then min = 0 end
    if max == nil then max = 128 end
    if state[param] + fraction < min then
        state[param] = min
    elseif state[param] + fraction > max then
        state[param] = max
    else
        state[param] = state[param] + fraction
    end
    return state[param] -- for inspection
end

local function gaussian_scan(state, d)
    -- for v = 0, 1 = 1 and 6 = 0
    -- for v = 1, 1 = 0 and 6 = 1
    adjust_param(lstate, 'scan_val', d, 1 / 60, 0, 1)
    -- print('scan val:' .. lstate.scan_val)

    -- distance to bar: multiply pos by 6; distance = math.abs(pos - i)

    -- pos should be 6 steps [0,1,2,3,4,5] or [1,2,3,4,5,6]
    -- voice number decides how close; if voice = 1, then distance = 1-1 = 0

    -- height of a bar is a function of the x distance to the dash.
    -- the further the bar from the dash, the lower the height.
    mu = 0  -- Center of the curve, you can adjust this to shift the peak of the curve

    num_voices = 6
    for i = 1, num_voices do
        pos = lstate.scan_val * (num_voices-1) -- convert scan value to a (0 <= pos <= 5)
        distance = math.abs(pos - (i-1) ) -- 0 <= distance <= 5
        bar_gaussian_height = math.exp(-((distance - mu)^2) / (2 * lstate.sigma^2))
        lstate.levels[i] = bar_gaussian_height
        -- print('distance['..i..'] = ' .. distance .. ', bar_height['..i..'] = ' .. bar_gaussian_height)
    end
end


local function adjust_sigma(state, d)
    s = adjust_param(lstate, 'sigma', d, .1,0.3,10)
    print('sigma: '..s)
    gaussian_scan(state, 0) --update scan
end

local scene = Scene:create({
    name = scene_name,
    e1 = nil,
    e2 = adjust_sigma,
    e3 = gaussian_scan,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = nil,
    k3_on = nil,
    k3_off = nil,
})


function scene:render(state)
    -- todo: this should be a graphic component, the entire thing belongs together
    screen.clear()
    local scan_bar_width = 72 -- dividable by 6 and 8
    local offsetx = (128 - scan_bar_width) / 2
    local offsety = 48
    local margin = 4
    local bar_width = 6
    local num_bars = 6
    local dash_width = 2
    local scan_bar_height = 4
    local level_height = 24

    -- rect
    screen.level(15)
    screen.line_width(1)
    screen.rect(offsetx, offsety, scan_bar_width, scan_bar_height)
    screen.stroke() -- stroke might give it a pixel extra compared to fill

    -- dash
    screen.level(10)
    screen.rect(offsetx + (lstate.scan_val * (scan_bar_width - dash_width - 1)), offsety, dash_width, scan_bar_height)
    screen.move(10,10)

    -- bars
    for i = 0, 5 do
        -- total width of bars should be equal to scan_bar_width.
        screen.move(i*20, 10)
        screen.text(string.format("%.2f", lstate.levels[i + 1]))
        screen.rect(
            offsetx + (i * (scan_bar_width - bar_width) / (num_bars - 1)),
            offsety - margin,
            bar_width,
            -level_height * lstate.levels[i + 1]
        )
        screen.fill()
        softcut.level(i, lstate.levels[i + 1])
    end
    screen.update()
end

function scene:initialize()
    -- empty
end

return scene
