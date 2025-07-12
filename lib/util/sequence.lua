
local sequence_speeds = {"1/16", "1/8", "1/4", "1/2", "1/1"}
local default_speed_idx = 2
local max_steps = 256

-- table with indexes matching to the sequence_speeds table above
local convert_sequence_speed = {
     -- x, when 256/x == number of 1/16th notes that composes 1 step for a given sequence speed
    1,
    2,
    4,
    8,
    16,
}

local switch_step = {
    -- modulo of the global step when a speed switch should be performed
    1,
    2,
    4,
    8,
    16,
}
return {
    sequence_speeds = sequence_speeds,
    default_speed_idx=default_speed_idx,
    convert_sequence_speed=convert_sequence_speed,
    max_steps=max_steps,
    switch_step=switch_step,
}