local function screen_level(amt, mod, min, max)
    local v = util.clamp(amt + (mod or 0), min or 1, max or 15)
    screen.level(v)
end

return {
    screen_level = screen_level
}