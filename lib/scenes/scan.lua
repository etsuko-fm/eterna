local Scene = include("bits/lib/scenes/Scene")
local scene_name = "Scan"

--[[
Scan scene
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

local function adjust_param(state, param, d, mult, min, max)
    -- todo: unify with adjust_param in timecontrols
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

local function calculate_gaussian_levels(state)
    -- convert state.scan_val to levels for each softcut voice
    local num_voices = 6
    for i = 1, num_voices do
        local pos = state.scan_val * (num_voices-1) -- convert scan value to position (0 <= pos <= 5). 
        -- The first and last level don't have full range, because the level shouldn't fade out as scan_val approaches 1.
        -- therefore the range is 0-5 instead of 0-6.
        local distance = math.abs(pos - (i-1) ) -- 0 <= distance <= 5
        local level = math.exp(-(distance^2) / (2 * state.sigma^2)) -- 0 <= level <= 1
        state.levels[i] = level
        -- print('distance['..i..'] = ' .. distance .. ', level['..i..'] = ' .. level)
    end

end

local function gaussian_scan(state, d)
    -- you need to invoke this logic in the main script to create a good starting condition.. or scene.initialize()
    adjust_param(state, 'scan_val', d, 1 / 60, 0, 1)
    calculate_gaussian_levels(state)
end



local function adjust_sigma(state, d)
    s = adjust_param(state, 'sigma', d, .1,0.3,10)
    gaussian_scan(state, 0) --update scan to reflect new curve in state
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
    screen.rect(offsetx + (state.scan_val * (scan_bar_width - dash_width - 1)), offsety, dash_width, scan_bar_height)
    screen.move(10,10)

    -- bars
    for i = 0, 5 do
        -- total width of bars should be equal to scan_bar_width.
        screen.move(i*20, 10)
        screen.text(string.format("%.2f", state.levels[i + 1]))
        screen.rect(
            offsetx + (i * (scan_bar_width - bar_width) / (num_bars - 1)),
            offsety - margin,
            bar_width,
            -level_height * state.levels[i + 1]
        )
        screen.fill()
        softcut.level(i, state.levels[i + 1])
    end
    screen.update()
end

function scene:initialize(state)
    -- I'm not sure to what extent a scene should have business logic like this
    calculate_gaussian_levels(state)
end

return scene
