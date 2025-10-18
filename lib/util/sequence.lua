local sequence_speeds = { "1/64", "1/32", "1/16", "1/8", "1/4" }
local default_speed_idx = 3
local perlin = include("symbiosis/lib/ext/perlin")

-- table with indexes matching to the sequence_speeds table above
local convert_sequence_speed = {
    1,
    2,
    4,
    8,
    16,
}

--- Returns the modulus condition for when it's safe to change step division
--- in a system where 1 = 1/64 note, 2 = 1/32, 4 = 1/16, 8 = 1/8, etc.
---
--- @param old_div number  -- old step division (1 = fastest)
--- @param new_div number  -- new step division (larger = slower)
--- @return number condition  -- number to use in current_step % condition == 0
function sync_modulus(old_div, new_div)
    --- Example:
    ---   old_div = 4  -- 1/16 note
    ---   new_div = 8  -- 1/8 note
    ---   division_sync_modulus(4, 8) => 2
    ---   => change step division when current_step % 2 == 0
    if new_div <= old_div then
        -- going to smaller or equal step size: can change anytime
        return 1
    else
        -- going to larger step size: wait until we are aligned
        local ratio = new_div / old_div
        return math.floor(ratio + 0.5)
    end
end

local switch_step = {
    -- modulo of the global step when a speed switch should be performed
    1,
    2,
    4,
    8,
    16,
}

local function generate_perlin_seq(rows, cols, x, y, z, density, zoom)
    local velocities = {}
    for row = 1, rows do
        local perlin_y = row * zoom + y
        for step = 1, cols do
            local perlin_x = step * zoom + x
            local pnoise = perlin:noise(perlin_x, perlin_y, z)
            local velocity = util.linlin(-1, 1, 0, 1, pnoise)
            table.insert(velocities, { value = velocity, voice = row, step = step })
        end
    end

    table.sort(velocities, function(a, b) return a.value > b.value end)
    local keep_count = math.floor(density * #velocities)
    for i, v in ipairs(velocities) do
        local keep = i <= keep_count
        v['value'] = keep and v.value or 0
    end
    return velocities
end

local function get_step_envelope(max_time, max_shape, enable_mod, velocity)
    local mod_amt
    if enable_mod ~= "OFF" then
        -- use half of sequencer val for modulation
        mod_amt = 0.5 + velocity / 2
    else
        mod_amt = 1
    end

    -- modulate time and shape
    local time = max_time * mod_amt
    local shape = max_shape * mod_amt
    local attack = get_attack(time, shape)
    local decay = get_decay(time, shape)

    return attack, decay
end

return {
    sequence_speeds = sequence_speeds,
    default_speed_idx = default_speed_idx,
    convert_sequence_speed = convert_sequence_speed,
    sync_modulus=sync_modulus,
    note=note,
    switch_step = switch_step,
    generate_perlin_seq = generate_perlin_seq,
    get_step_envelope = get_step_envelope,
}
