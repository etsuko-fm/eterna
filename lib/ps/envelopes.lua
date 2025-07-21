---
--- ENVELOPES params
---
local page_id = "env_"

ID_ENVELOPES_ATTACK = page_id.."attack"
ID_ENVELOPES_DECAY = page_id.."decay"
ID_ENVELOPES_FILTER_ENV = page_id .."filter_env"
local ENV_ATTACK_MIN = 0.001
local ENV_ATTACK_MAX = 10.0
local ENV_DECAY_MIN = 0.01
local ENV_DECAY_MAX = 10.0
local ENV_FILTER_MIN = 50
local ENV_FILTER_MAX = 20000

controlspec_env_attack = controlspec.def {
    min = ENV_ATTACK_MIN,
    max = ENV_ATTACK_MAX,
    warp = 'exp',
    step = 0.01,
    default = 0.01,
    units = '',
    quantum = 0.01,
    wrap = false
}

controlspec_env_decay = controlspec.def {
    min = ENV_DECAY_MIN,
    max = ENV_DECAY_MAX,
    warp = 'exp',
    step = 0.01,
    default = 3.0,
    units = '',
    quantum = 0.01,
    wrap = false
}

controlspec_env_filter = controlspec.def {
    min = ENV_FILTER_MIN,
    max = ENV_FILTER_MAX,
    warp = 'exp',
    step = 0.01,
    default = 4000,
    units = '',
    quantum = 0.001,
    wrap = false
}

params:add_separator("ENVELOPE", "ENVELOPE")
params:add_control(ID_ENVELOPES_ATTACK, "attack", controlspec_env_attack)
params:add_control(ID_ENVELOPES_DECAY, "decay", controlspec_env_decay)
params:add_control(ID_ENVELOPES_FILTER_ENV, "filter env", controlspec_env_filter)