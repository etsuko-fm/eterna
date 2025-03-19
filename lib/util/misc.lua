local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function trim(s, max_length)
    if #s > max_length then
        return string.sub(s, 1, max_length)
    else
        return s
    end
end

return {
    round = round,
    trim = trim,
}