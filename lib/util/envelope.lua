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
    get_step_envelope = get_step_envelope,
}
