
local sequence_speeds = {"1/32", "1/16", "1/8", "1/4", "1/2", "1", "2", "4", "8"}
local default_speed_idx = 2
local convert_sequence_speed = {
     -- all fractions of 1/4th notes
    1/8,
    1/4,
    1/2,
    1,
    2,
    4,
    8,
    16,
    32,
}

return {
    sequence_speeds = sequence_speeds,
    default_speed_idx=default_speed_idx,
    convert_sequence_speed=convert_sequence_speed,
}