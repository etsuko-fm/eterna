local lfo_period_values = {
    1 / 16, 1 / 8, 1 / 4, 1 / 2,
    1, 2, 4, 8, 12, 16, 20,
    24, 28, 32, 36, 40, 44, 48,
    52, 56, 60, 64, 68, 72, 76, 80, 84, 88, 92, 96,
    100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144, 148, 152,
    156, 160, 164, 168, 172, 176, 180, 184, 188, 192, 196, 200, 204, 208,
    212, 216, 220, 224, 228, 232, 236, 240, 244, 248, 252, 256
}

-- labels only, e.g. for paramset options
local lfo_period_labels = {}

-- for converting from label to float value
local lfo_period_label_values = {}

-- for converting from float value to label
local lfo_period_value_labels = {}

local function gcd(a, b)
    while b ~= 0 do
        a, b = b, a % b
    end
    return a
end

local function decimal_to_fraction(x)
    local precision = 1e-6
    local denominator = 1
    while true do
        local numerator = x * denominator
        if math.abs(numerator - math.floor(numerator + 0.5)) < precision then
            numerator = math.floor(numerator + 0.5)
            local g = gcd(numerator, denominator)
            return numerator // g, denominator // g
        end
        denominator = denominator + 1
        if denominator > 512 then break end -- prevent infinite loop
    end
    return x, 1                             -- fallback
end

local function fraction_to_label(v)
    if v < 4 and v % 1 ~= 0 then
        local num, denom = decimal_to_fraction(v)
        return string.format("%d/%d", num, denom)
    else
        return tostring(v)
    end
end

for i, v in ipairs(lfo_period_values) do
    -- period represents _beats_; convert to fraction of 4/4 bar (1 > 1/4)
    local fraction = v / 4
    -- format fraction (0.25) to a string ("1/4")
    local label = fraction_to_label(fraction)
    lfo_period_label_values[label] = v
    lfo_period_labels[i] = label
    lfo_period_value_labels[v] = label
end

local function adjust_lfo_rate(d, lfo)
    -- d should be a positive or negative integer
    local values = lfo_period_values
    local current_val = lfo:get('period')

    -- Find the closest index in the predefined values
    local closest_index = 1
    for i = 1, #values do
        if math.abs(values[i] - current_val) < math.abs(values[closest_index] - current_val) then
            closest_index = i
        end
    end

    -- Move to the next or previous value based on `d`
    local new_index = math.max(1, math.min(#values, closest_index + d))
    local new_val = values[new_index]

    -- Apply the new value
    lfo:set('period', new_val)
end

local function toggle_shape(lfo, available_shapes)
    local shape = lfo:get('shape')
    local index = 1

    for i, s in ipairs(available_shapes) do
        if s == shape then
            index = i
            break
        end
    end

    local next_index = (index % #available_shapes) + 1
    lfo:set('shape', available_shapes[next_index])
end

local function action_lfo(v, lfo, shapes, phase)
    -- helper method to enable/disable LFO and set LFO shape
    -- TODO: remove once implemented everywhere w on/off button
    local selection = shapes[v]
    if selection == "off" then
        lfo:stop()
    else
        if lfo:get("enabled") == 0 then lfo:start() end
        lfo:set('shape', selection)
    end
    if phase ~= nil then lfo:set('phase', phase) end
end

local function action_lfo_toggle(v, lfo, phase)
    -- helper method to enable/disable LFO
    if v == 0 then
        lfo:stop()
    else
        lfo:start()
    end
    if phase ~= nil then lfo:set('phase', phase) end
end

local function action_lfo_shape(v, lfo, shapes, phase)
    -- helper method to set LFO shape
    local selection = shapes[v]
    lfo:set('shape', selection)
end



return {
    lfo_period_values = lfo_period_values,
    lfo_period_labels = lfo_period_labels,
    lfo_period_value_labels = lfo_period_value_labels,
    lfo_period_label_values = lfo_period_label_values,
    toggle_shape = toggle_shape,
    adjust_lfo_rate = adjust_lfo_rate,
    action_lfo = action_lfo,
    action_lfo_toggle = action_lfo_toggle,
    action_lfo_shape = action_lfo_shape,
}
