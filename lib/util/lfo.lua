local lfo_period_values = {
        1/8, 1/6, 1/4, 1/3, 1/2, 
        1, 1.25, 1 + 1/3, 1.5, 1 + 2/3, 1.75,
        2, 2.25, 2 + 1/3, 2.5, 2 + 2/3, 2.75,
        3, 3.25, 3 + 1/3, 3.5, 3 + 2/3, 3.75,
        4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
        22, 24, 26, 28, 30, 32, 33, 34, 36, 38, 40, 48, 50,
        52, 56, 60, 64, 68, 72, 75, 76, 80, 84, 88, 92, 96, 
        100, 104, 108, 112, 116, 120, 124, 125, 128, 132, 136, 140, 144, 148, 150, 152, 
        156, 160, 164, 168, 172, 175, 176, 180, 184, 188, 192, 196, 200, 204, 208, 
        212, 216, 220, 224, 225, 228, 232, 236, 240, 244, 248, 250, 252, 256
}

local function adjust_lfo_rate(state, d, lfo)
    local k = (10 ^ math.log(lfo:get('period'), 10)) / 50
    local min = 0.2
    local max = 256

    new_val = lfo:get('period') + (d * k)
    if new_val < min then
        new_val = min
    end
    if new_val > max then
        new_val = max
    end
    lfo:set('period', new_val)
end

local function adjust_lfo_rate_quant(d, lfo)
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


return {
    lfo_period_values = lfo_period_values,
    adjust_lfo_rate_quant = adjust_lfo_rate_quant,
    adjust_lfo_rate = adjust_lfo_rate,
}