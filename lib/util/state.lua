local function adjust_param(tbl, param, d, mult, min, max, loop)
    local fraction = d * mult
    if loop and max ~= nil then
        tbl[param] = (tbl[param] + fraction) % max
    elseif min ~= nil and tbl[param] + fraction < min then
        tbl[param] = min
    elseif max ~= nil and tbl[param] + fraction > max then
        tbl[param] = max
    else
        tbl[param] = tbl[param] + fraction
    end
    return tbl[param] -- for inspection
end

return {
    adjust_param = adjust_param
}