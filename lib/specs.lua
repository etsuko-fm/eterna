-- Sigma - i.e. the Gaussian distribution concept
LEVELS_SIGMA_MIN = 0.3
LEVELS_SIGMA_MAX = 15
LEVELS_LFO_SHAPES = { "sine", "up", "down", "random" }

local LEVELS_POSITION_MIN = 0
local LEVELS_POSITION_MAX = 1

controlspec_pos = controlspec.def {
    min = LEVELS_POSITION_MIN,
    max = LEVELS_POSITION_MAX,
    warp = 'lin',
    step = 0.01,
    default = 0.42,
    units = '',
    quantum = 0.01,
    wrap = true
}

-- Amp maps the arbitrary sigma range from 0 to 1
local LEVELS_AMP_MIN = 0
local LEVELS_AMP_MAX = 1

controlspec_amp = controlspec.def {
    min = LEVELS_AMP_MIN,
    max = LEVELS_AMP_MAX,
    warp = 'lin',
    step = 0.01,
    default = 0.45,
    units = '',
    quantum = 0.01,
    wrap = false
}


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
