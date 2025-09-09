---
--- PANNING
---
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

ID_PANNING_LFO_ENABLED = "panning_lfo_enabled"
ID_PANNING_LFO_SHAPE = "panning_lfo_shape"
ID_PANNING_LFO_RATE = "panning_lfo_rate"
ID_PANNING_TWIST = "panning_twist"
ID_PANNING_SPREAD = "panning_spread"
-- todo: add tri?
PANNING_LFO_SHAPES = { "sine", "up", "down", "random" }
DEFAULT_PANNING_LFO_RATE_IDX = 16

params:add_separator("PANNING", "PANNING")
params:add_binary(ID_PANNING_LFO_ENABLED, "LFO enabled", "toggle", 1)
params:add_option(ID_PANNING_LFO_SHAPE, "LFO shape", PANNING_LFO_SHAPES, 2)
params:add_option(ID_PANNING_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, DEFAULT_PANNING_LFO_RATE_IDX)
params:add_control(ID_PANNING_TWIST, "twist", controlspec_pan_twist)
params:add_control(ID_PANNING_SPREAD, "spread", controlspec_pan_spread)
