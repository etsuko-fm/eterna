---
--- HPF params
---

local page_id = "hpf_"
ID_HPF_WET = page_id .. "wet"
ID_HPF_TYPE = page_id .. "type"
ID_HPF_LFO = page_id .. "lfo"
ID_HPF_FREQ_MOD = page_id .. "freq_mod"
ID_HPF_LFO_RATE = page_id .. "lfo_rate"
HPF_LFO_SHAPES = { "off", "sine" }
DRY_WET_TYPES = { "DRY", "50/50", "WET" }

-- multiplies with cutoff value
local FREQ_MOD_RANGE_MIN = 0.5
local FREQ_MOD_RANGE_MAX = 2

controlspec_hpf_freq_mod = controlspec.def {
    min = FREQ_MOD_RANGE_MIN,
    max = FREQ_MOD_RANGE_MAX,
    warp = 'lin',
    step = 0.001,
    default = 1,
    units = '',
    quantum = 0.005,
    wrap = false
}

params:add_separator("HPF", "HPF")
params:add_option(ID_HPF_LFO, "LFO shape", HPF_LFO_SHAPES, 1)
params:add_option(ID_HPF_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, 8)
params:add_option(ID_HPF_WET, "dry/wet", DRY_WET_TYPES, 1)
params:add_control(ID_HPF_FREQ_MOD, "frequency_mod", controlspec_hpf_freq_mod)
params:hide(ID_HPF_FREQ_MOD) -- to be modified by lfo only
