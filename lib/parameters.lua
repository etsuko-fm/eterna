---
--- SLICES
---

SLICES_MIN = 1
SLICES_MAX = 32
SLICES_DEFAULT = 16

controlspec_slices = controlspec.def {
    min = SLICES_MIN,
    max = SLICES_MAX,
    warp = 'lin',
    step = 1,
    default = SLICES_DEFAULT,
    units = '',
    quantum = 1 / SLICES_MAX,
    wrap = false
}

local START_MIN = 1
local START_MAX = 32 -- dynamic, todo: deal with that

controlspec_slice_start = controlspec.def {
    min = START_MIN,
    max = START_MAX,
    warp = 'lin',
    step = 1,
    default = 1,
    units = '',
    quantum = 1 / START_MAX,
    wrap = true
}

ID_SLICES_AUDIO_FILE = "slices_audio_file"
ID_SLICES_NUM_SLICES = "slices_num_slices"
ID_SLICES_START = "slices_slice_start"
ID_SLICES_LFO = "slices_lfo"
SLICES_LFO_SHAPES = { "off", "up", "down", "random" }

ID_SLICES_SECTIONS = {}

function get_slice_start_param_id(voice)
    return "slices_" .. voice .. "_start"
end

function get_slice_end_param_id(voice)
    return "slices_" .. voice .. "_end"
end

for voice = 1, 6 do
    ID_SLICES_SECTIONS[voice] = {
        loop_start = get_slice_start_param_id(voice),
        loop_end = get_slice_end_param_id(voice),
    }
end


---
--- SEQUENCER
---

-- some values to seed the perlin noise, fact that they're primes is just for fun, can provide
-- any set of reasonably spread numbers
local primes = {
    1, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
    31, 37, 41, 43, 47, 53, 59, 61, 67,
    71, 73, 79, 83, 89, 97
}


controlspec_perlin = controlspec.def {
    min = 0,
    max = 100,
    warp = 'lin',
    step = .01,
    default = primes[math.floor(math.random(1, #primes))],
    units = '',
    quantum = .05,
    wrap = true
}

controlspec_perlin_z = controlspec.def {
    min = 0,
    max = 100,
    warp = 'lin',
    step = .01,
    default = 1,
    units = '',
    quantum = .05,
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
    default = 0.0,
    units = '',
    quantum = .01,
    wrap = false
}

controlspec_num_steps = controlspec.def {
    min = 1,
    max = 16,
    warp = 'lin',
    step = 1,
    default = 16,
    units = '',
    quantum = 1 / 16,
    wrap = false
}

local component = "sequencer_"
ID_SEQ_SPEED = component .. "speed"
ID_SEQ_PERLIN_X = component .. "perlin_x"
ID_SEQ_PERLIN_Y = component .. "perlin_y"
ID_SEQ_PERLIN_Z = component .. "perlin_z"
ID_SEQ_PERLIN_DENSITY = component .. "perlin_density"
ID_SEQ_STYLE = component .. "style"
ID_SEQ_NUM_STEPS = component .. "num_steps"
ID_SEQ_STEP = {}
SEQ_ROWS = 6
SEQ_COLUMNS = 16

---
--- ENVELOPES params
---
local page_id = "env_"

ID_ENVELOPES_MOD = page_id .. "mod"
ID_ENVELOPES_TIME = page_id .. "time"
ID_ENVELOPES_FILTER_ENV = page_id .. "filter_env"
ID_ENVELOPES_CURVE = page_id .. "curve"
ID_ENVELOPES_SHAPE = page_id .. "shape"

ENVELOPE_CURVES = { -3, 0, 3 }
ENVELOPE_NAMES = { "NEG", "LIN", "POS" }
ENVELOPE_MOD_OPTIONS = { "OFF", "TIME", "LPG" }

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
    default = 0.5,
    units = '',
    quantum = 0.005,
    wrap = false
}

controlspec_env_shape = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = 0.001,
    default = 0.25,
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

---
--- PLAYBACK RATES
---

-- Helpers

function get_voice_dir_param_id(i)
  -- get voice directions; also used for other pages, hence global
  return "rates_v" .. i .. "_dir"
end

RATES_CENTER_MIN = -2
RATES_CENTER_MAX = 2
RATES_CENTER_QUANTUM = 1

RATES_SPREAD_MIN = -2
RATES_SPREAD_MAX = 2
RATES_SPREAD_MIN_QNT = -2
RATES_SPREAD_MAX_QNT = 2
RATES_SPREAD_QUANTUM = 1
RATES_SPREAD_QUANTUM = 1

controlspec_rates_center = controlspec.def {
    min = RATES_CENTER_MIN,
    max = RATES_CENTER_MAX,
    warp = 'lin',
    step = 1,
    default = -1,
    units = '',
    quantum = RATES_CENTER_QUANTUM,
    wrap = false
}

controlspec_rates_spread = controlspec.def {
    min = RATES_SPREAD_MIN_QNT,
    max = RATES_SPREAD_MAX_QNT,
    warp = 'lin',
    step = 1,
    default = 1,
    units = '',
    quantum = RATES_SPREAD_QUANTUM,
    wrap = false
}

ID_RATES_DIRECTION = "rates_direction"
ID_RATES_RANGE = "rates_range"
ID_RATES_CENTER = "rates_center"
ID_RATES_SPREAD = "rates_spread"

FWD = "FWD"
REV = "REV"
FWD_REV = "BI"
PLAYBACK_TABLE = { FWD, REV, FWD_REV }

THREE_OCTAVES = "3 OCT"
FIVE_OCTAVES = "5 OCT"
RANGE_TABLE = { THREE_OCTAVES, FIVE_OCTAVES }
RANGE_DEFAULT = 2 -- 5 octaves by default


---
--- LEVELS
---

-- Sigma (σ in normal distribution)
LEVELS_SIGMA_MIN = 0.3
LEVELS_SIGMA_MAX = 15
LEVELS_LFO_SHAPES = { "off", "up", "down", "random" }

local LEVELS_POSITION_MIN = 0
local LEVELS_POSITION_MAX = 1

controlspec_pos = controlspec.def {
    min = LEVELS_POSITION_MIN,
    max = LEVELS_POSITION_MAX,
    warp = 'lin',
    step = 1/180,
    default = 0.42,
    units = '',
    quantum = 1/180,
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

ID_LEVELS_LFO = "levels_lfo_enabled"
ID_LEVELS_LFO_RATE = "levels_lfo_rate"
ID_LEVELS_POS = "levels_pos"
ID_LEVELS_AMP = "levels_sigma"

local LEVELS_LFO_DEFAULT_RATE_INDEX = 20

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

ID_PANNING_LFO = "panning_lfo_enabled"

ID_PANNING_LFO_RATE = "panning_lfo_rate"
ID_PANNING_TWIST = "panning_twist"
ID_PANNING_SPREAD = "panning_spread"
PANNING_LFO_SHAPES = { "off", "up", "down", "random" }
DEFAULT_PANNING_LFO_RATE_IDX = 16

---
--- LPF params
---

local page_id = "lpf_"
ID_LPF_WET = page_id .. "wet"
ID_LPF_TYPE = page_id .. "type"
ID_LPF_LFO = page_id .. "lfo"
ID_LPF_FREQ_MOD = page_id .. "freq_mod"
ID_LPF_LFO_RATE = page_id .. "lfo_rate"
LPF_LFO_SHAPES = { "off", "sine" }
DRY_WET_TYPES = { "DRY", "50/50", "WET" }

-- multiplies with cutoff value
local FREQ_MOD_RANGE_MIN = 0.5
local FREQ_MOD_RANGE_MAX = 2

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

---
--- ECHO params
---
local page_id = "echo_"

ID_ECHO_TIME = page_id .. "time"
ECHO_TIME_AMOUNTS = { 0.0625, 0.125, 0.1875, 0.25, 0.375, 0.5, 0.625, 0.75, 1, 1.25 }
ECHO_TIME_NAMES = {"1/64", "1/32", "1/32D", "1/16", "1/16D", "1/8", "5/32", "1/8D", "1/4", "5/16" }

---
--- MASTER params
---

ID_MASTER_MONO_FREQ = "master_mono_freq"
ID_MASTER_COMP_AMOUNT = "master_comp_amount"

BASS_MONO_FREQS_STR = {"OFF", "50Hz", "100Hz", "200Hz", "FULL"}
BASS_MONO_FREQS_INT = {20, 50, 100, 200, 20000}

COMP_AMOUNTS = {"OFF", "SOFT", "MEDIUM", "HARD"}


--- MENU
params:add_separator("BITS", "BITS")

params:add_separator("SAMPLE_SLICES", "SAMPLE SLICES")
params:add_file(ID_SLICES_AUDIO_FILE, 'sample', nil)
params:add_option(ID_SLICES_LFO, "lfo", SLICES_LFO_SHAPES)
params:add_control(ID_SLICES_NUM_SLICES, "slices", controlspec_slices)
params:add_control(ID_SLICES_START, "start", controlspec_slice_start)

for voice = 1, 6 do
    -- ranges per voice; each voice plays 1 slice
    params:add_number(ID_SLICES_SECTIONS[voice].loop_start, ID_SLICES_SECTIONS[voice].loop_start, 0)
    params:add_number(ID_SLICES_SECTIONS[voice].loop_end, ID_SLICES_SECTIONS[voice].loop_end, 0)
    params:hide(ID_SLICES_SECTIONS[voice].loop_start)
    params:hide(ID_SLICES_SECTIONS[voice].loop_end)
end

params:add_separator("SEQUENCER", "SEQUENCER")
params:add_control(ID_SEQ_NUM_STEPS, "steps", controlspec_num_steps)
params:add_option(ID_SEQ_SPEED, "step size", sequence_util.sequence_speeds, 2)
params:add_control(ID_SEQ_PERLIN_X, "seed", controlspec_perlin)
params:add_control(ID_SEQ_PERLIN_Y, "perlin y", controlspec_perlin_y)
params:add_control(ID_SEQ_PERLIN_Z, "perlin z", controlspec_perlin_z)
params:add_control(ID_SEQ_PERLIN_DENSITY, "density", controlspec_perlin_density)

params:hide(ID_SEQ_PERLIN_Y)
params:hide(ID_SEQ_PERLIN_Z)

-- add 6x16 params for sequence step status
for y = 1, SEQ_ROWS do
    ID_SEQ_STEP[y] = {}
    for x = 1, SEQ_COLUMNS do
        ID_SEQ_STEP[y][x] = "sequencer_step_" .. y .. "_" .. x
        params:add_number(ID_SEQ_STEP[y][x], ID_SEQ_STEP[y][x], -1, 1, 0)
        params:hide(ID_SEQ_STEP[y][x])
    end
end

params:add_separator("ENVELOPE", "ENVELOPE")
params:add_option(ID_ENVELOPES_MOD, "mod", ENVELOPE_MOD_OPTIONS, 2)
params:add_control(ID_ENVELOPES_TIME, "time", controlspec_env_time)
params:add_control(ID_ENVELOPES_SHAPE, "shape", controlspec_env_shape)
params:add_option(ID_ENVELOPES_CURVE, "curve", ENVELOPE_CURVES)
params:add_control(ID_ENVELOPES_FILTER_ENV, "filter env", controlspec_env_filter)

params:add_separator("PLAYBACK_RATES", "PLAYBACK RATES")
params:add_option(ID_RATES_RANGE, 'range', RANGE_TABLE, RANGE_DEFAULT)
params:add_control(ID_RATES_CENTER, "center", controlspec_rates_center)
params:add_control(ID_RATES_SPREAD, "spread", controlspec_rates_spread)
params:add_option(ID_RATES_DIRECTION, "direction", PLAYBACK_TABLE, 1)

for voice = 1, 6 do
    -- add params for playback direction per voice
    local param_id = get_voice_dir_param_id(voice)
    params:add_option(param_id, param_id, PLAYBACK_TABLE, 1)
    params:hide(param_id)
end

params:add_separator("VOICE LEVELS", "LEVELS")
params:add_option(ID_LEVELS_LFO, "LFO", LEVELS_LFO_SHAPES)
params:add_option(ID_LEVELS_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, LEVELS_LFO_DEFAULT_RATE_INDEX)
params:add_control(ID_LEVELS_POS, "position", controlspec_pos)
params:add_control(ID_LEVELS_AMP, "amp", controlspec_amp)

params:add_separator("PANNING", "PANNING")
params:add_option(ID_PANNING_LFO, "LFO", PANNING_LFO_SHAPES)
params:add_option(ID_PANNING_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, DEFAULT_PANNING_LFO_RATE_IDX)
params:add_control(ID_PANNING_TWIST, "twist", controlspec_pan_twist)
params:add_control(ID_PANNING_SPREAD, "spread", controlspec_pan_spread)

params:add_separator("LPF", "LPF")
params:add_option(ID_LPF_LFO, "LFO shape", LPF_LFO_SHAPES, 1)
params:add_option(ID_LPF_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, 8)
params:add_option(ID_LPF_WET, "dry/wet", DRY_WET_TYPES, 1)
params:add_control(ID_LPF_FREQ_MOD, "frequency_mod", controlspec_lpf_freq_mod)

params:hide(ID_LPF_FREQ_MOD) -- to be modified by lfo only

params:add_separator("HPF", "HPF")
params:add_option(ID_HPF_LFO, "LFO shape", HPF_LFO_SHAPES, 1)
params:add_option(ID_HPF_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, 8)
params:add_option(ID_HPF_WET, "dry/wet", DRY_WET_TYPES, 1)
params:add_control(ID_HPF_FREQ_MOD, "frequency_mod", controlspec_hpf_freq_mod)
params:hide(ID_HPF_FREQ_MOD) -- to be modified by lfo only

params:add_separator("ECHO", "ECHO")
params:add_option(ID_ECHO_TIME, "time", ECHO_TIME_NAMES, 4)

params:add_separator("MASTER", "MASTER")
params:add_option(ID_MASTER_MONO_FREQ, "bass mono freq", BASS_MONO_FREQS_STR, 2)
params:add_option(ID_MASTER_COMP_AMOUNT, "compressor amount", COMP_AMOUNTS, 2)
