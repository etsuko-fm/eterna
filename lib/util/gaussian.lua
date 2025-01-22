function calculate_gaussian_levels(skew, sigma)
    -- skew = the current center of the graph (0-1, 0.5 = symmetrical)
    -- convert state.scan_val to levels for each softcut voice
    num_vals = 6
    levels = {}
    for i = 1, num_vals do
        -- translate scan value to a virtual 'position' so that it matches the number of bars (1 <= pos <= num_bars)
        local pos = 1 + (skew * num_vals)

        -- the 'distance' from the current voice to the scan position
        -- example [6 bars]: scan pos 1, bar 5: abs(1 - 5) = abs(-4) = 4
        --                   scan pos 5, bar 1: abs(5 - 1)) = abs(4) = 4
        local distance = math.min(
            math.abs(pos - i),
            num_vals - math.abs(pos - i)
        )

        -- Calculate the level for the current voice using a Gaussian formula:
        -- level = e^(-(distance^2) / (2 * sigma^2))
        -- where distance^2 makes farther voices quieter.
        -- where sigma controls how "wide" the Gaussian curve is (how quickly levels fade).
        local level = math.exp(-(distance ^ 2) / (2 * sigma ^ 2)) -- 0 <= level <= 1

        levels[i] = level
        -- print('distance['..i..'] = ' .. distance .. ', level['..i..'] = ' .. level)
    end
    return levels
end

return {
    calculate_gaussian_levels = calculate_gaussian_levels
}