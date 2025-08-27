---
--- ENVELOPES params
---
local page_id = "env_"

ID_ENVELOPES_MOD = page_id.."mod"
ID_ENVELOPES_TIME = page_id.."time"
ID_ENVELOPES_FILTER_ENV = page_id .."filter_env"
ID_ENVELOPES_CURVE = page_id .. "curve"
ID_ENVELOPES_SHAPE = page_id .. "shape"

ENVELOPE_CURVES = {-3, 0, 3}
ENVELOPE_NAMES = {"NEG", "LIN", "POS"}

ENV_TIME_MIN = 0.0015
ENV_TIME_MAX = 5
ENV_ATTACK_MAX = 2.5
ENV_DECAY_MAX = 2.5
local ENV_FILTER_MIN = 50
local ENV_FILTER_MAX = 20000

controlspec_env_time = controlspec.def {
    min = ENV_TIME_MIN,
    max = ENV_TIME_MAX,
    warp = 'exp',
    step = 0.002,
    default = 1.0,
    units = '',
    quantum = 0.005,
    wrap = false
}

controlspec_env_shape = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = 0.001,
    default = 0,
    units = '',
    quantum = 0.01,
    wrap = false
}


controlspec_env_filter = controlspec.def {
    min = ENV_FILTER_MIN,
    max = ENV_FILTER_MAX,
    warp = 'exp',
    step = 0.01,
    default = 20000,
    units = '',
    quantum = 0.001,
    wrap = false
}

params:add_separator("ENVELOPE", "ENVELOPE")
params:add_binary(ID_ENVELOPES_MOD, "mod", "toggle", 1)
params:add_control(ID_ENVELOPES_TIME, "time", controlspec_env_time)
params:add_control(ID_ENVELOPES_SHAPE, "shape", controlspec_env_shape)
params:add_option(ID_ENVELOPES_CURVE, "curve", ENVELOPE_CURVES)
params:add_control(ID_ENVELOPES_FILTER_ENV, "filter env", controlspec_env_filter)
