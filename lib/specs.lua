-- Sigma - i.e. the Gaussian distribution concept
LEVELS_SIGMA_MIN = 0.3
LEVELS_SIGMA_MAX = 15
LEVELS_LFO_SHAPES = { "sine", "up", "down", "random" }

local LEVELS_POSITION_MIN = 0
local LEVELS_POSITION_MAX = 1

controlspec_pos = controlspec.def {
    min = LEVELS_POSITION_MIN, -- the minimum value
    max = LEVELS_POSITION_MAX, -- the maximum value
    warp = 'lin',              -- a shaping option for the raw value
    step = 0.01,               -- output value quantization
    default = 0.42,            -- default value
    units = '',                -- displayed on PARAMS UI
    quantum = 0.01,            -- each delta will change raw value by this much
    wrap = true                -- wrap around on overflow (true) or clamp (false)
}

-- Amp maps the arbitrary sigma range from 0 to 1
local LEVELS_AMP_MIN = 0
local LEVELS_AMP_MAX = 1

controlspec_amp = controlspec.def {
    min = LEVELS_AMP_MIN, -- the minimum value
    max = LEVELS_AMP_MAX, -- the maximum value
    warp = 'lin',         -- a shaping option for the raw value
    step = 0.01,          -- output value quantization
    default = 0.6,        -- default value
    units = '',           -- displayed on PARAMS UI
    quantum = 0.01,       -- each delta will change raw value by this much
    wrap = false          -- wrap around on overflow (true) or clamp (false)
}

PITCH_CENTER_MIN = -2
PITCH_CENTER_MAX = 2
PITCH_CENTER_QUANTUM = 1 / 120
PITCH_CENTER_QUANTUM_QNT = 1.0

PITCH_SPREAD_MIN = -2
PITCH_SPREAD_MAX = 2
PITCH_SPREAD_MIN_QNT = -2
PITCH_SPREAD_MAX_QNT = 2
PITCH_SPREAD_QUANTUM = 0.01
PITCH_SPREAD_QUANTUM_QNT = 0.5

controlspec_center = controlspec.def {
    min = PITCH_CENTER_MIN,             -- the minimum value
    max = PITCH_CENTER_MAX,             -- the maximum value
    warp = 'lin',                       -- a shaping option for the raw value
    step = 1 / 120,                     -- output value quantization
    default = 0.0,                      -- default value
    units = '',                         -- displayed on PARAMS UI
    quantum = PITCH_CENTER_QUANTUM_QNT, -- each delta will change raw value by this much
    wrap = false                        -- wrap around on overflow (true) or clamp (false)
}

controlspec_spread = controlspec.def {
    min = PITCH_SPREAD_MIN_QNT,         -- the minimum value
    max = PITCH_SPREAD_MAX_QNT,         -- the maximum value
    warp = 'lin',                       -- a shaping option for the raw value
    step = 0.01,                        -- output value quantization
    default = 0.0,                      -- default value
    units = '',                         -- displayed on PARAMS UI
    quantum = PITCH_SPREAD_QUANTUM_QNT, -- each delta will change raw value by this much
    wrap = false                        -- wrap around on overflow (true) or clamp (false)
}

controlspec_perlin = controlspec.def {
    min = 0,      -- the minimum value
    max = 100,    -- the maximum value
    warp = 'lin', -- a shaping option for the raw value
    step = .01,   -- output value quantization
    default = 0,  -- default value
    units = '',   -- displayed on PARAMS UI
    quantum = .1, -- each delta will change raw value by this much
    wrap = true   -- wrap around on overflow (true) or clamp (false)
}

controlspec_perlin_density = controlspec.def {
    min = 0,        -- the minimum value
    max = 1,        -- the maximum value
    warp = 'lin',   -- a shaping option for the raw value
    step = .001,    -- output value quantization
    default = 0.35, -- default value
    units = '',     -- displayed on PARAMS UI
    quantum = .01,  -- each delta will change raw value by this much
    wrap = false    -- wrap around on overflow (true) or clamp (false)
}

local TWIST_MIN = 0
local TWIST_MAX = 1

controlspec_twist = controlspec.def {
    min = TWIST_MIN, -- the minimum value
    max = TWIST_MAX, -- the maximum value
    warp = 'lin',    -- a shaping option for the raw value
    step = 0.005,    -- output value quantization
    default = 0.0,   -- default value
    units = '',      -- displayed on PARAMS UI
    quantum = 0.005, -- each delta will change raw value by this much
    wrap = true      -- wrap around on overflow (true) or clamp (false)
}

local SPREAD_MIN = 0
local SPREAD_MAX = 1

controlspec_spread = controlspec.def {
    min = SPREAD_MIN, -- the minimum value
    max = SPREAD_MAX, -- the maximum value
    warp = 'lin',     -- a shaping option for the raw value
    step = 0.01,      -- output value quantization
    default = 0.2,    -- default value
    units = '',       -- displayed on PARAMS UI
    quantum = 0.01,   -- each delta will change raw value by this much
    wrap = false      -- wrap around on overflow (true) or clamp (false)
}

-- SAMPLING
SLICES_MIN = 1
SLICES_MAX = 32
SLICES_DEFAULT = 6

controlspec_slices = controlspec.def {
    min = SLICES_MIN, -- the minimum value
    max = SLICES_MAX, -- the maximum value
    warp = 'lin',     -- a shaping option for the raw value
    step = 1,         -- output value quantization
    default = SLICES_DEFAULT,      -- default value
    units = '',       -- displayed on PARAMS UI
    quantum = 1,      -- each delta will change raw value by this much
    wrap = false      -- wrap around on overflow (true) or clamp (false)
}

local START_MIN = 1
local START_MAX = 32 -- dynamic, todo: deal with that

controlspec_start = controlspec.def {
    min = START_MIN, -- the minimum value
    max = START_MAX, -- the maximum value
    warp = 'lin',    -- a shaping option for the raw value
    step = 1,        -- output value quantization
    default = 1,     -- default value
    units = '',      -- displayed on PARAMS UI
    quantum = 1,     -- each delta will change raw value by this much
    wrap = false     -- wrap around on overflow (true) or clamp (false)
}