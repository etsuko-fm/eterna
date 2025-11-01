---
--- LPF params
---

local page_id = "lpf_"
ID_LPF_FREQ = page_id .. "freq"
ID_LPF_RES = page_id .. "res"
ID_LPF_WET = page_id .. "wet"
ID_LPF_TYPE = page_id .. "type"
ID_LPF_LFO = page_id .. "lfo"
ID_LPF_FREQ_MOD = page_id .. "freq_mod"
ID_LPF_LFO_RATE = page_id .. "lfo_rate"
LPF_LFO_SHAPES = { "off", "sine" }
DRY_WET_TYPES = { "DRY", "50/50", "WET" }

local LPF_FREQ_MIN = 20
local LPF_FREQ_MAX = 20000
local LPF_RES_MIN = 0.0
local LPF_RES_MAX = 0.98

-- multiplies with cutoff value
local FREQ_MOD_RANGE_MIN = 0.5
local FREQ_MOD_RANGE_MAX = 2

-- controlspec_lpf_freq = controlspec.def {
--     min = LPF_FREQ_MIN,
--     max = LPF_FREQ_MAX,
--     warp = 'exp',
--     step = 0.1,
--     default = 440.0,
--     units = '',
--     quantum = 0.005,
--     wrap = false
-- }

controlspec_lpf_freq_mod = controlspec.def {
    min = FREQ_MOD_RANGE_MIN,
    max = FREQ_MOD_RANGE_MAX,
    warp = 'lin',
    step = 0.001,
    default = 1,
    units = '',
    quantum = 0.005,
    wrap = false
}


-- controlspec_lpf_res = controlspec.def {
--     min = LPF_RES_MIN,
--     max = LPF_RES_MAX,
--     warp = 'lin',
--     step = 0.01,
--     default = 0.2,
--     units = '',
--     quantum = 0.02,
--     wrap = false
-- }

params:add_separator("LPF", "LPF")
params:add_option(ID_LPF_LFO, "LFO shape", LPF_LFO_SHAPES, 1)
params:add_option(ID_LPF_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, 8)
params:add_option(ID_LPF_WET, "dry/wet", DRY_WET_TYPES, 1)
-- params:add_control(ID_LPF_FREQ, "frequency", controlspec_lpf_freq)
params:add_control(ID_LPF_FREQ_MOD, "frequency_mod", controlspec_lpf_freq_mod)
-- params:add_control(ID_LPF_RES, "resonance", controlspec_lpf_res)

params:hide(ID_LPF_FREQ_MOD) -- to be modified by lfo only
