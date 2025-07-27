---
--- ENVELOPES params
---
local page_id = "env_"

ID_ENVELOPES_ENABLE = page_id.."enable"
ID_ENVELOPES_ATTACK = page_id.."attack"
ID_ENVELOPES_DECAY = page_id.."decay"
ID_ENVELOPES_FILTER_ENV = page_id .."filter_env"
ID_ENVELOPES_CURVE = page_id .. "curve"

ENVELOPE_CURVES = {-3, 0, 3}
ENVELOPE_NAMES = {"CONVX", "LIN", "CNCAV"}


local ENV_ATTACK_MIN = 0.01
local ENV_ATTACK_MAX = 10.0
local ENV_DECAY_MIN = 0.01
local ENV_DECAY_MAX = 10.0
local ENV_FILTER_MIN = 50
local ENV_FILTER_MAX = 20000

controlspec_env_attack = controlspec.def {
    min = ENV_ATTACK_MIN,
    max = ENV_ATTACK_MAX,
    warp = 'exp',
    step = 0.0001,
    default = ENV_ATTACK_MIN,
    units = '',
    quantum = 0.005,
    wrap = false
}

controlspec_env_decay = controlspec.def {
    min = ENV_DECAY_MIN,
    max = ENV_DECAY_MAX,
    warp = 'exp',
    step = 0.0001,
    default = 3.0,
    units = '',
    quantum = 0.005,
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
params:add_binary(ID_ENVELOPES_ENABLE, "enable", "toggle")
params:add_control(ID_ENVELOPES_ATTACK, "attack", controlspec_env_attack)
params:add_control(ID_ENVELOPES_DECAY, "decay", controlspec_env_decay)
params:add_option(ID_ENVELOPES_CURVE, "curve", ENVELOPE_CURVES)
params:add_control(ID_ENVELOPES_FILTER_ENV, "filter env", controlspec_env_filter)
