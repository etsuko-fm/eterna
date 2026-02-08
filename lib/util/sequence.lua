local perlin = include(from_root("lib/ext/perlin"))
local sequence_speeds = { "1/32", "1/16", "1/8", "1/4" }

-- table with indexes matching to the sequence_speeds table above
local convert_sequence_speed = {
    1,
    2,
    4,
    8,
}

local function density_filter(values, density)
    table.sort(values, function(a, b) return a.value > b.value end)
    -- Steps are kept by preserving the top number of velocities (sorted by value)
    -- and zeroing out the rest, maintaining only the strongest hits based on density
    local keep_count = math.floor(density * #values)
    for i, v in ipairs(values) do
        local keep = i <= keep_count
        v['value'] = keep and v.value or 0
    end
    return values
end

local function generate_perlin(rows, cols, x, y, z, zoom)
    local values = {}
    for row = 1, rows do
        local perlin_y = row * zoom + y
        for step = 1, cols do
            local perlin_x = step * zoom + x
            local pnoise = perlin:noise(perlin_x, perlin_y, z)
            -- perlin:noise generates values in range (-1, 1); scale to (0, 1)
            local value = util.linlin(-1, 1, 0, 1, pnoise)
            table.insert(values, { value = value, voice = row, step = step })
        end
    end
    return values
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
    convert_sequence_speed = convert_sequence_speed,
    generate_perlin = generate_perlin,
    density_filter = density_filter,
    get_step_envelope = get_step_envelope,
}
