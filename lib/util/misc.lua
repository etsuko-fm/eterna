local function round(num, num_decimal_places)
    local mult = 10^(num_decimal_places or 0)
    return math.floor(num * mult + 0.5) / mult
end

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

return {
    round = round,
    trim = trim,
    list_to_set = list_to_set,
    set_contains = set_contains,
}
