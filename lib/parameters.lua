local app        = "eterna"

-- Components, for creating param ids
META             = "meta"
SAMPLER          = "sampler"
SEQUENCER        = "sequencer"
PROCESSOR        = "processor"
MASTER           = "master"

local components = {
    [META] = true,
    [SAMPLER] = true,
    [SEQUENCER] = true,
    [PROCESSOR] = true,
    [MASTER] = true,
}

local function get_id(component, param)
    if components[component] then
        return app .. "_" .. component .. "_" .. param
    else
        print("get_id: component " .. component .. " unknown")
    end
end

-- VERSIONING
local VERSION_STRING = "0.14.0"
local ID_VERSION = get_id(META, "version")

-- PAGE SYSTEM
ID_CURRENT_PAGE = get_id(META, "page")

---
--- SAMPLE
---
ID_SAMPLER_AUDIO_FILE = get_id(SAMPLER, "sample_path")
ID_SAMPLER_DRIVE = get_id(SAMPLER, "drive")
controlspec_sample_drive = engine_lib.params.voices.specs["voice_drive"]

---
--- SLICES
---
controlspec_num_slices = controlspec.def {
    min = 1,
    max = 32,
    warp = 'lin',
    step = 1,
    default = 16,
    quantum = 1 / 32,
    wrap = false
}

controlspec_slice_start = controlspec.def {
    min = 1,
    max = 32,
    warp = 'lin',
    step = 1,
    default = 1,
    quantum = 1 / 32,
    wrap = true
}

ID_SAMPLER_NUM_SLICES = get_id(SAMPLER, "num_slices")
ID_SAMPLER_SLICE_START = get_id(SAMPLER, "start_slice")
ID_SLICE_LFO_ENABLED = get_id(SAMPLER, "slice_lfo_enabled")
ID_SLICE_LFO_SHAPE = get_id(SAMPLER, "slice_lfo_shape")
ID_SLICE_LFO_RATE = get_id(SAMPLER, "slice_lfo_rate")
SLICE_START_LFO_SHAPES = { "up", "down", "random" }

ID_SAMPLER_SECTIONS = {}

function get_slice_start_param_id(voice)
    return get_id(SAMPLER, "slices_" .. voice .. "_start")
end

function get_slice_end_param_id(voice)
    return get_id(SAMPLER, "slices_" .. voice .. "_end")
end

for voice = 1, 6 do
    ID_SAMPLER_SECTIONS[voice] = {
        loop_start = get_slice_start_param_id(voice),
        loop_end = get_slice_end_param_id(voice),
    }
end


---
--- SEQUENCER
---

-- some values to seed the perlin noise
local primes = {
    1, 5, 7, 11, 13, 17, 19, 23, 29,
    31, 37, 41, 43, 47
}

controlspec_perlin = controlspec.def {
    min = 0,
    max = 50,
    warp = 'lin',
    step = 1/1000,
    default = primes[math.floor(math.random(1, #primes))],
    quantum = 1/1000,
    wrap = true
}

controlspec_perlin_density = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = .001,
    default = 0.1,
    quantum = .01,
    wrap = false
}

controlspec_num_steps = controlspec.def {
    min = 1,
    max = 16,
    warp = 'lin',
    step = 1,
    default = 16,
    quantum = 1 / 16,
    wrap = false
}

controlspec_vel_center = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = 0.01,
    default = 0.5,
    quantum = 0.01,
    wrap = false
}

controlspec_vel_spread = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = 0.01,
    default = 0.25,
    quantum = 0.01,
    wrap = false
}

ID_SEQ_SPEED = get_id(SEQUENCER, "step_size")
ID_SEQ_PERLIN_X = get_id(SEQUENCER, "perlin_x")
ID_SEQ_PERLIN_Y = get_id(SEQUENCER, "perlin_x")
ID_SEQ_PERLIN_Z = get_id(SEQUENCER, "perlin_z")
ID_SEQ_VEL_CENTER = get_id(SEQUENCER, "velocity_center")
ID_SEQ_VEL_SPREAD = get_id(SEQUENCER, "velocity_spread")
ID_SEQ_DENSITY = get_id(SEQUENCER, "density")
ID_SEQ_STYLE = get_id(SEQUENCER, "style")
ID_SEQ_BPM = get_id(SEQUENCER, "bpm")
ID_SEQ_NUM_STEPS = get_id(SEQUENCER, "num_steps")
STEPS_PERLIN = {}
STEPS_GRID = {}
ID_SEQ_SOURCE = get_id(SEQUENCER, "current_input")
SOURCE_PERLIN = "PERLIN"
SOURCE_GRID = "GRID"
SEQUENCER_SOURCES = {SOURCE_PERLIN, SOURCE_GRID}
NUM_TRACKS = 6
NUM_STEPS = 16 -- TODO: actually MAX_STEPS

---
--- ENVELOPES params
---
ID_ENVELOPES_MOD = get_id(SAMPLER, "env_velocity_mod")
ID_ENVELOPES_TIME = get_id(SAMPLER, "env_time")
ID_ENVELOPES_CURVE = get_id(SAMPLER, "env_curve")
ID_ENVELOPES_SHAPE = get_id(SAMPLER, "env_shape")

ENVELOPE_CURVES = { -3, 0, 3 }
ENVELOPE_NAMES = { "NEG", "LIN", "POS" }
ENVELOPE_MOD_OPTIONS = { "OFF", "TIME", "LPG" }

controlspec_env_time = controlspec.def {
    min = 0.0015,
    max = 5,
    warp = 'exp',
    step = 0.002,
    default = 0.5,
    quantum = 0.005,
    wrap = false
}

controlspec_env_shape = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = 0.001,
    default = 0.25,
    quantum = 0.01,
    wrap = false
}

controlspec_env_filter = controlspec.def {
    min = 50,
    max = 20000,
    warp = 'exp',
    step = 0.01,
    default = 20000,
    quantum = 0.001,
    wrap = false
}

---
--- PLAYBACK RATES
---

function get_voice_direction_id(voice)
    -- 1 <= voice <= 6
    -- get playback direction param ID for voice; also used for other pages, hence global
    return get_id(SAMPLER, "rates_voice_" .. voice .. "_direction")
end

controlspec_rates_center = controlspec.def {
    min = -2,
    max = 2,
    warp = 'lin',
    step = 1,
    default = 0,
    quantum = 1/4,
    wrap = false
}

controlspec_rates_spread = controlspec.def {
    min = -2,
    max = 2,
    warp = 'lin',
    step = 1,
    default = 0,
    quantum = 1/4,
    wrap = false
}

ID_RATES_DIRECTION = get_id(SAMPLER, "rates_direction")
ID_RATES_RANGE = get_id(SAMPLER, "rates_range")
ID_RATES_CENTER = get_id(SAMPLER, "rates_center")
ID_RATES_SPREAD = get_id(SAMPLER, "rates_spread")

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
LEVELS_SIGMA_MIN                    = 0.3
LEVELS_SIGMA_MAX                    = 15
LEVELS_LFO_SHAPES                   = { "up", "down", "random" }

controlspec_pos                     = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = 1 / 180,
    default = 0.42,
    quantum = 1 / 180,
    wrap = true
}

-- Amp maps the arbitrary sigma range from 0 to 1
controlspec_amp                     = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = 0.01,
    default = 0.45,
    quantum = 0.01,
    wrap = false
}

ID_LEVELS_LFO_ENABLED               = get_id(PROCESSOR, "levels_lfo_enabled")
ID_LEVELS_LFO_SHAPE                 = get_id(PROCESSOR, "levels_lfo_shape")
ID_LEVELS_LFO_RATE                  = get_id(PROCESSOR, "levels_lfo_rate")
ID_LEVELS_POS                       = get_id(PROCESSOR, "levels_pos")
ID_LEVELS_AMP                       = get_id(PROCESSOR, "levels_amp")

local LEVELS_LFO_DEFAULT_RATE_INDEX = 20

---
--- PANNING
---
controlspec_pan_twist               = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = 0.005,
    default = 0.0,
    quantum = 0.005,
    wrap = true
}

controlspec_pan_spread              = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = 0.01,
    default = 1,
    quantum = 0.01,
    wrap = false
}

ID_PANNING_LFO_ENABLED              = get_id(SAMPLER, "panning_lfo_enabled")
ID_PANNING_LFO_SHAPE                = get_id(SAMPLER, "panning_lfo_shape")
ID_PANNING_LFO_RATE                 = get_id(SAMPLER, "panning_lfo_rate")
ID_PANNING_TWIST                    = get_id(SAMPLER, "panning_twist")
ID_PANNING_SPREAD                   = get_id(SAMPLER, "panning_spread")
PANNING_LFO_SHAPES                  = { "up", "down", "random" }
DEFAULT_PANNING_LFO_RATE_IDX        = 16

---
--- Lowpass filter params
---

ID_LPF_WET                          = get_id(PROCESSOR, "lpf_wet")
ID_LPF_TYPE                         = get_id(PROCESSOR, "lpf_type")
ID_LPF_LFO_ENABLED                  = get_id(PROCESSOR, "lpf_lfo")
ID_LPF_LFO_SHAPE                    = get_id(PROCESSOR, "lpf_lfo_shape")
ID_LPF_BASE_FREQ                    = get_id(PROCESSOR, "lpf_freq")
ID_LPF_FREQ_MOD                     = get_id(PROCESSOR, "lpf_freq_mod")
ID_LPF_LFO_RATE                     = get_id(PROCESSOR, "lpf_lfo_rate")
ID_LPF_LFO_RANGE                    = get_id(PROCESSOR, "lpf_lfo_range")

LPF_LFO_SHAPES                      = { "sine", "up", "down", "random" }

-- this exists next to the engine freq, but allows a base frequency to change,
-- while the engine freq is being modulated by the lfo
controlspec_filter_freq             = controlspec.def {
    min = 20,
    max = 20000,
    warp = 'exp',
    step = 0.01,
    default = 1000,
    units = 'Hz',
    quantum = 0.005,
    wrap = false
}

-- multiplies with cutoff value
controlspec_freq_mod            = controlspec.def {
    min = 0,
    max = 2,
    warp = 'lin',
    step = 0.001,
    default = 1,
    quantum = 0.005,
    wrap = false
}

-- sets range of filter lfo
controlspec_lfo_range           = controlspec.def {
    min = 0,
    max = 10,
    warp = 'lin',
    step = 0.01,
    default = 5,
    quantum = 0.01,
    wrap = false
}

---
--- Highpass filter params
---

ID_HPF_WET                          = get_id(PROCESSOR, "hpf_wet")
ID_HPF_TYPE                         = get_id(PROCESSOR, "hpf_type")
ID_HPF_LFO_ENABLED                  = get_id(PROCESSOR, "hpf_lfo")
ID_HPF_LFO_SHAPE                    = get_id(PROCESSOR, "hpf_lfo_shape")
ID_HPF_FREQ_MOD                     = get_id(PROCESSOR, "hpf_freq_mod")
ID_HPF_BASE_FREQ                    = get_id(PROCESSOR, "hpf_freq")
ID_HPF_LFO_RATE                     = get_id(PROCESSOR, "hpf_lfo_rate")
ID_HPF_LFO_RANGE                    = get_id(PROCESSOR, "hpf_lfo_range")

MIX_DRY = "DRY"
MIX_PARALLEL = "50%"
MIX_WET = "WET"
DRY_WET_TYPES                       = { MIX_DRY, MIX_PARALLEL, MIX_WET }
HPF_LFO_SHAPES                      = { "sine", "up", "down", "random" }

---
--- ECHO params
---

ID_ECHO_TIME                        = get_id(PROCESSOR, "echo_time")

-- TODO: zip so time/name is defined together
ECHO_TIME_AMOUNTS                   = { 0.0625, 0.125, 0.1875, 0.25, 0.3125, 0.375, 0.5, 0.625, 0.75 }
ECHO_TIME_NAMES                     = { "1/64", "1/32", "1/32D", "1/16", "5/64", "1/16D", "1/8", "5/32", "1/8D" }

---
--- MASTER params
---

ID_MASTER_MONO_FREQ                 = get_id(MASTER, "bass_mono_freq")
ID_MASTER_COMP_AMOUNT               = get_id(MASTER, "comp_amount")

BASS_MONO_FREQS_STR                 = { "OFF", "50Hz", "100Hz", "200Hz", "FULL" }
BASS_MONO_FREQS_INT                 = { 20, 50, 100, 200, 20000 }

-- cycling FWD+REV here because the gain difference is large otherwise
COMP_AMOUNTS                        = { "OFF", "SOFT", "MEDIUM", "HARD", "MEDIUM", "SOFT" }


--- MENU
params:add_separator("ETERNA", "ETERNA")

params:add_text(ID_VERSION, "version", VERSION_STRING)
params:hide(ID_VERSION)

params:add_text(ID_CURRENT_PAGE, "current_page", "EMPTY") -- would nil work?
params:hide(ID_CURRENT_PAGE)
params:set_save(ID_CURRENT_PAGE, false) -- TODO: check if not actually saved

params:add_file(ID_SAMPLER_AUDIO_FILE, 'sample', nil)
params:add_control(ID_SAMPLER_DRIVE, "drive", controlspec_sample_drive)

params:add_separator("SAMPLE_SLICES", "SLICES")
params:add_binary(ID_SLICE_LFO_ENABLED, "LFO enabeld", "toggle")
params:add_option(ID_SLICE_LFO_SHAPE, "LFO shape", SLICE_START_LFO_SHAPES)
params:add_option(ID_SLICE_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, 6)
params:add_control(ID_SAMPLER_NUM_SLICES, "slices", controlspec_num_slices)
params:add_control(ID_SAMPLER_SLICE_START, "start", controlspec_slice_start)

for voice = 1, 6 do
    -- ranges per voice; each voice plays 1 slice
    params:add_number(ID_SAMPLER_SECTIONS[voice].loop_start, ID_SAMPLER_SECTIONS[voice].loop_start, 0)
    params:add_number(ID_SAMPLER_SECTIONS[voice].loop_end, ID_SAMPLER_SECTIONS[voice].loop_end, 0)
    params:hide(ID_SAMPLER_SECTIONS[voice].loop_start)
    params:hide(ID_SAMPLER_SECTIONS[voice].loop_end)
end

params:add_separator("ENVELOPE", "ENVELOPE")
params:add_option(ID_ENVELOPES_MOD, "mod", ENVELOPE_MOD_OPTIONS, 2)
params:add_control(ID_ENVELOPES_TIME, "time", controlspec_env_time)
params:add_control(ID_ENVELOPES_SHAPE, "shape", controlspec_env_shape)
params:add_option(ID_ENVELOPES_CURVE, "curve", ENVELOPE_NAMES)

params:add_separator("PLAYBACK_RATES", "PLAYBACK RATES")
params:add_option(ID_RATES_RANGE, 'range', RANGE_TABLE, RANGE_DEFAULT)
params:add_control(ID_RATES_CENTER, "center", controlspec_rates_center)
params:add_control(ID_RATES_SPREAD, "spread", controlspec_rates_spread)
params:add_option(ID_RATES_DIRECTION, "direction", PLAYBACK_TABLE, 1)

for voice = 1, 6 do
    -- add params for playback direction per voice
    local param_id = get_voice_direction_id(voice)
    params:add_option(param_id, param_id, PLAYBACK_TABLE, 1)
    params:hide(param_id)
end

params:add_separator("VOICE_LEVELS", "LEVELS")
params:add_binary(ID_LEVELS_LFO_ENABLED, "LFO enabled", "toggle")
params:add_option(ID_LEVELS_LFO_SHAPE, "LFO shape", LEVELS_LFO_SHAPES)
params:add_option(ID_LEVELS_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, LEVELS_LFO_DEFAULT_RATE_INDEX)
params:add_control(ID_LEVELS_POS, "position", controlspec_pos)
params:add_control(ID_LEVELS_AMP, "amp", controlspec_amp)

params:add_separator("PANNING", "PANNING")
params:add_binary(ID_PANNING_LFO_ENABLED,"LFO enabled", "toggle")
params:add_option(ID_PANNING_LFO_SHAPE, "LFO shape", PANNING_LFO_SHAPES)
params:add_option(ID_PANNING_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, DEFAULT_PANNING_LFO_RATE_IDX)
params:add_control(ID_PANNING_TWIST, "twist", controlspec_pan_twist)
params:add_control(ID_PANNING_SPREAD, "spread", controlspec_pan_spread)

params:add_separator("SEQUENCER", "SEQUENCER")
params:add_control(ID_SEQ_NUM_STEPS, "steps", controlspec_num_steps)
params:add_option(ID_SEQ_SPEED, "step size", sequence_util.sequence_speeds, 2)
params:add_control(ID_SEQ_PERLIN_X, "seed", controlspec_perlin)
params:add_number(get_id(SEQUENCER, "perlin_y"), "perlin y", 0, 25, 10, nil, true)
params:add_number(get_id(SEQUENCER, "perlin_z"), "perlin z", 0, 100, nil, true)
params:add_control(ID_SEQ_VEL_CENTER, "vel center", controlspec_vel_center)
params:add_control(ID_SEQ_VEL_SPREAD, "vel spread", controlspec_vel_spread)
params:add_control(ID_SEQ_DENSITY, "density", controlspec_perlin_density)
params:add_number(ID_SEQ_BPM, "bpm", 1, 300)
params:add_option(ID_SEQ_SOURCE, "source", SEQUENCER_SOURCES, 1)
params:hide(get_id(SEQUENCER, "perlin_y"))
params:hide(get_id(SEQUENCER, "perlin_z"))
params:hide(ID_SEQ_BPM)
params:hide(ID_SEQ_SOURCE)

-- add 6x16 params for sequence step status (for perlin noise only)
for track = 1, NUM_TRACKS do
    STEPS_PERLIN[track] = {}
    for step = 1, NUM_STEPS do
        STEPS_PERLIN[track][step] = get_id(SEQUENCER, "step_" .. track .. "_" .. step)
        params:add_number(STEPS_PERLIN[track][step], STEPS_PERLIN[track][step], 0, 1, 0)
        -- Hide from params menu, user can change values with UI/encoders instead
        params:hide(STEPS_PERLIN[track][step])
    end
end

-- add 6x16 params for sequence step status (for grid only)
for track = 1, NUM_TRACKS do
    STEPS_GRID[track] = {}
    for step = 1, NUM_STEPS do
        STEPS_GRID[track][step] = get_id(SEQUENCER, "step_" .. track .. "_" .. step .. "_grid")
        params:add_number(STEPS_GRID[track][step], STEPS_GRID[track][step], 0, 1, 0)
        -- Hide from params menu, user can change values with Grid instead
        params:hide(STEPS_GRID[track][step])
    end
end

params:add_separator("LPF", "LPF")
params:add_binary(ID_LPF_LFO_ENABLED, "LFO enabled", "toggle")
params:add_option(ID_LPF_LFO_SHAPE, "LFO shape", LPF_LFO_SHAPES, 1)
params:add_option(ID_LPF_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, 21)
params:add_option(ID_LPF_WET, "dry/wet", DRY_WET_TYPES, 1)
params:add_control(ID_LPF_BASE_FREQ, "base frequency", controlspec_filter_freq)
params:add_control(ID_LPF_FREQ_MOD, "freq mod", controlspec_freq_mod)
params:add_control(ID_LPF_LFO_RANGE, "LFO range", controlspec_lfo_range)
params:hide(ID_LPF_FREQ_MOD) -- to be modified by lfo only

params:add_separator("HPF", "HPF")
params:add_binary(ID_HPF_LFO_ENABLED, "LFO enabled", "toggle")
params:add_option(ID_HPF_LFO_SHAPE, "LFO shape", HPF_LFO_SHAPES, 1)
params:add_option(ID_HPF_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, 21)
params:add_option(ID_HPF_WET, "dry/wet", DRY_WET_TYPES, 1)
params:add_control(ID_HPF_BASE_FREQ, "base frequency", controlspec_filter_freq)
params:add_control(ID_HPF_FREQ_MOD, "frequency_mod", controlspec_freq_mod)
params:add_control(ID_HPF_LFO_RANGE, "LFO range", controlspec_lfo_range)
params:hide(ID_HPF_FREQ_MOD) -- to be modified by lfo only

params:add_separator("ECHO", "ECHO")
params:add_option(ID_ECHO_TIME, "time", ECHO_TIME_NAMES, 4)

params:add_separator("MASTER", "MASTER")
params:add_option(ID_MASTER_MONO_FREQ, "bass mono freq", BASS_MONO_FREQS_STR, 1)
params:add_option(ID_MASTER_COMP_AMOUNT, "compressor amount", COMP_AMOUNTS, 2)