-- local function round(num, num_decimal_places)
--     local mult = 10^(num_decimal_places or 0)
--     return math.floor(num * mult + 0.5) / mult
-- end

local function trim(s, max_length)
    if #s > max_length then
        return string.sub(s, 1, max_length)
    else
        return s
    end
end

-- Converts a list (array) into a set (table with keys)
local function list_to_set(list)
    local set = {}
    for _, value in ipairs(list) do
        set[value] = true
    end
    return set
end

-- Utility function to check if a number exists in the set
local function set_contains(set, number)
    return set[number] == true
end

-- Convert exponential range [slo, shi] to linear range [dlo, dhi]
function explin(slo, shi, dlo, dhi, f, exp)
    exp = exp or 1  -- exponentiality factor (1 = plain log scaling)

    -- sanity checks
    if slo == 0 or shi == 0 or (slo * shi < 0) then
        error("slo and shi must be non-zero and of the same sign")
    end

    -- normalize input exponentially
    local t = (math.log(math.abs(f)) - math.log(math.abs(slo))) /
              (math.log(math.abs(shi)) - math.log(math.abs(slo)))

    -- apply exponentiality factor
    t = t ^ exp

    -- scale to linear destination
    return dlo + (dhi - dlo) * t
end

-- Convert linear range [slo, shi] to exponential range [dlo, dhi]
function linexp(slo, shi, dlo, dhi, f, exp)
    exp = exp or 1  -- exponentiality factor (1 = plain log scaling)

    -- sanity checks
    if dlo == 0 or dhi == 0 or (dlo * dhi < 0) then
        error("dlo and dhi must be non-zero and of the same sign")
    end

    -- normalize input linearly
    local t = (f - slo) / (shi - slo)

    -- apply exponentiality factor (inverse of explin's power)
    t = t ^ (1 / exp)

    -- scale to exponential destination
    return math.exp(
        math.log(math.abs(dlo)) +
        (math.log(math.abs(dhi)) - math.log(math.abs(dlo))) * t
    )
end

return {
    linexp = linexp,
    explin = explin,
    trim = trim,
    list_to_set = list_to_set,
    set_contains = set_contains,
}

