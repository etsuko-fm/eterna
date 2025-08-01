

controlspec_perlin = controlspec.def {
    min = 0,
    max = 100,
    warp = 'lin',
    step = .01,
    default = math.random(4) * 25.0,
    units = '',
    quantum = .1,
    wrap = true
}

controlspec_perlin_y = controlspec.def {
    min = 0,
    max = 25,
    warp = 'lin',
    step = .00001,
    default = math.random(4) * 25.0,
    units = '',
    quantum = .00001,
    wrap = true
}


controlspec_perlin_density = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = .001,
    default = 0.5, -- default value
    units = '',
    quantum = .01,
    wrap = false
}

local PAN_TWIST_MIN = 0
local PAN_TWIST_MAX = 1

controlspec_pan_twist = controlspec.def {
    min = PAN_TWIST_MIN,
    max = PAN_TWIST_MAX,
    warp = 'lin',
    step = 0.005,
    default = 0.0,
    units = '',
    quantum = 0.005,
    wrap = true
}

local PAN_SPREAD_MIN = 0
local PAN_SPREAD_MAX = 1

controlspec_pan_spread = controlspec.def {
    min = PAN_SPREAD_MIN,
    max = PAN_SPREAD_MAX,
    warp = 'lin',
    step = 0.01,
    default = 0.8,
    units = '',
    quantum = 0.01,
    wrap = false
}

-- SAMPLING
SLICES_MIN = 1
SLICES_MAX = 32
SLICES_DEFAULT = 6

controlspec_slices = controlspec.def {
    min = SLICES_MIN,
    max = SLICES_MAX,
    warp = 'lin',
    step = 1,
    default = SLICES_DEFAULT,
    units = '',
    quantum = 1,
    wrap = false
}

local START_MIN = 1
local START_MAX = 32 -- dynamic, todo: deal with that

controlspec_start = controlspec.def {
    min = START_MIN,
    max = START_MAX,
    warp = 'lin',
    step = 1,
    default = 1,
    units = '',
    quantum = 1,
    wrap = false
}
