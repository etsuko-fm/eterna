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
    -- Keep a specified percentage of values of a sorted list.
    -- Assusming sorted descendingly, it keeps the top % of values.
    local keep_count = math.floor(density * #values)
    for i, v in ipairs(values) do
        local keep = i <= keep_count
        v['value'] = keep and 1 or 0
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
    -- sort descending by perlin noise values
    table.sort(values, function(a, b) return a.value > b.value end)

    -- by now values itself are actually irrelevant, just the sorted list is
    -- removing the values saves some memory during memoization (384kb for 1000 sequences)
    for _, v in ipairs(values) do
        v.value = nil
    end
    return values
end

local function copy_sequence(seq)
    local result = {}
    for i, v in ipairs(seq) do
        result[i] = {
            value = v.value,
            voice = v.voice,
            step  = v.step
        }
    end
    return result
end

-- for memoization
local perlin_cache = {}

local function mem_generate_perlin(rows, cols, x, y, z, zoom)
    -- memoized version of generate_perlin, as it takes some milliseconds to generate
    local key = table.concat({rows, cols, x, y, z, zoom}, ":")

    local cached = perlin_cache[key]
    if cached then
        return copy_sequence(cached)
    end

    -- fallback to original function
    local values = generate_perlin(rows, cols, x, y, z, zoom)

    perlin_cache[key] = copy_sequence(values)
    return values
end

local seeds = {}
for i = 1, 16 do
    seeds[i] = math.random(0, 1000) / 100
end

-- Memoization cache for velocity values
local velocity_cache = {}

local function noise_to_velocity(noise, center, spread)
    local r = util.linlin(-1, 1, 0, 1, noise)
    local half_range = spread / 2
    local velocity = (center - half_range) + r * spread
    return util.clamp(velocity, 0.01, 1)
end

local function generate_velocity(center, spread, step)
    step = step or 1
    local key = step .. ":" .. math.floor(seeds[step] * 100 + 0.5)

    local cached = velocity_cache[key]
    if cached then
        seeds[step] = seeds[step] + 0.05
        return noise_to_velocity(seeds[step], center, spread)
    end

    local pnoise = perlin:noise(seeds[step])
    local normalized = util.clamp(pnoise / 0.75, -1, 1)
    velocity_cache[key] = normalized
    return noise_to_velocity(normalized, center, spread)
end

return {
    sequence_speeds = sequence_speeds,
    convert_sequence_speed = convert_sequence_speed,
    generate_perlin = mem_generate_perlin,
    generate_velocity = generate_velocity,
    density_filter = density_filter,
}
