local perlin = include("symbiosis/lib/ext/perlin")
local sequence_speeds = { "1/64", "1/32", "1/16", "1/8", "1/4" }
local default_speed_idx = 3

-- table with indexes matching to the sequence_speeds table above
local convert_sequence_speed = {
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
    note=note,
    generate_perlin_seq = generate_perlin_seq,
    get_step_envelope = get_step_envelope,
}
