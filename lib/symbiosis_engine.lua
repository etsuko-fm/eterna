local Symbiosis        = {}
local Formatters       = require 'formatters'
local ENV_FILTER_MIN   = 50
local ENV_FILTER_MAX   = 20000
local RATE_MIN         = 1 / 8
local RATE_MAX         = 8

-- goals of this file:
--- abstract ```for i=1,6 do engine.func(i-1, val) end ```
--- any params that only do `engine.func()` become obsolete, currently:

local MASTER_DRIVE_MIN = -12
local MASTER_DRIVE_MAX = 18

MASTER_OUT_MIN         = -60
local MASTER_OUT_MAX   = 0

local engine_prefix    = "symbiosis_"

Symbiosis.echo_styles  = { "CLEAR", "DUST", "MIST" }

local filter_spec      = controlspec.def {
    min = 20,
    max = 20000,
    warp = 'exp',
    step = 0.01,
    default = 1000,
    units = 'Hz',
    quantum = 0.005,
    wrap = false
}

local simple_spec      = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = 0.01,
    default = 0,
    units = '',
    quantum = 0.01,
    wrap = false
}

Symbiosis.specs        = {
    ["echo_wet"] = {spec = simple_spec },
    ["echo_time"] = {
        spec = controlspec.def {
            min = 0,
            max = 2, -- seconds
            warp = 'lin',
            step = 0.001,
            default = 0.2,
            units = '',
            quantum = 0.001,
            wrap = false
        }
    },
    ["echo_feedback"] = { spec = simple_spec },
    ["lpf_freq"] = { spec = filter_spec },
    ["hpf_freq"] = { spec = filter_spec },
    ["lpf_res"] = {
        spec = controlspec.def {
            min = 0.0,
            max = 0.98,
            warp = 'lin',
            step = 0.01,
            default = 0.2,
            units = '',
            quantum = 0.02,
            wrap = false
        }
    },
    ["hpf_res"] = {
        spec = controlspec.def {
            min = 0.0,
            max = 0.98,
            warp = 'lin',
            step = 0.01,
            default = 0.2,
            units = '',
            quantum = 0.02,
            wrap = false
        }
    },
    ["lpf_dry"] = { spec = simple_spec },
    ["hpf_dry"] = { spec = simple_spec },
    ["comp_drive"] = {
        spec = controlspec.def {
            min = -12,
            max = 18,
            warp = 'lin',
            step = 0.01,
            default = 0,
            units = 'dB',
            quantum = 0.1 / (MASTER_DRIVE_MAX - MASTER_DRIVE_MIN),
            wrap = false
        },
    },
    ["comp_ratio"] = {
        spec = controlspec.def {
            min = 1,
            max = 20,
            warp = 'lin',
            step = 0.01,
            default = 1,
            units = '',
            quantum = 0.005,
            wrap = false
        },
    },
    ["comp_threshold"] = {
        spec = controlspec.def {
            min = 0.01,
            max = 1,
            warp = 'lin',
            step = 0.01,
            default = 0,
            units = '',
            quantum = 0.01,
            wrap = false
        }
    },
    ["comp_out_level"] = {
        spec = controlspec.def {
            min = MASTER_OUT_MIN,
            max = MASTER_OUT_MAX,
            warp = 'lin',
            step = 0.1,
            default = 1,
            units = 'dB',
            quantum = 0.2 / (MASTER_OUT_MAX - MASTER_OUT_MIN),
            wrap = false
        },
    },
    ["bass_mono_freq"] = {
        spec = controlspec.def {
            min = 20,
            max = 20000,
            warp = 'exp',
            step = 0.1,
            default = 1,
            units = 'Hz',
            quantum = 0.005,
            wrap = false
        },
    }
}

Symbiosis.options      = {
    ["echo_style"] = {
        options = Symbiosis.echo_styles,
    }
}

local function no_underscore(s)
    return s:gsub("_", " ")
end

local keys = {}
for k, _ in pairs(Symbiosis.specs) do
    table.insert(keys, k)
end

for k, _ in pairs(Symbiosis.options) do
    table.insert(keys, k)
end

Symbiosis.get_id = function(command)
    return engine_prefix .. command
end

function Symbiosis.add_params()
    params:add_group("Symbiosis", #keys)

    -- add controlspec-based params
    for command, entry in pairs(Symbiosis.specs) do
        params:add {
            type = "control",
            id = Symbiosis.get_id(command),
            name = no_underscore(command),
            controlspec = entry.spec,
            action = function(x) engine[command](x) end
        }
    end

    -- add option-based params
    for command, entry in pairs(Symbiosis.options) do
        params:add {
            type = "option",
            id = Symbiosis.get_id(command),
            name = no_underscore(command),
            options = entry.options,
            action = function(v) engine[command](entry.options[v]) end
        }
    end

    -- add voice params
    params:bang()
end

-- Voice engine commands are not exposed as params here;
-- there're so many of them (12 commands * 6 voices) that it's a bit overwhelming
-- to expose them all to the end user individually.
-- Instead, some convenience methods are provided to set the params.
-- Scripts may use these in actions instead of direct engine invocations,
-- and add their own paramset based on what they want to expose.

-- but then you can just hide them?
local voice_params = {
    "voice_attack",     -- acceptable range: 0 - 10~30 sec?
    "voice_decay",
    "voice_enable_env", -- toggle
    "voice_enable_lpg", -- toggle
    "voice_env_curve",  -- -4 to 4
    "voice_env_level",  -- 0 to 1
    "voice_level",      -- 0 to 1
    "voice_loop_start", -- 0 to max buff length
    "voice_loop_end",
    "voice_lpg_freq",   -- 20 to 20k
    "voice_pan",        -- -1 to 1
    "voice_rate",       -- 1/8 to 8
}

for p = 1, #voice_params do
    -- create methods that sets all 6 voices to the same value for a given param
    -- e.g. Symbiosis.each_voice_level(v)
    Symbiosis["each_" .. voice_params[p]] = function(v)
        for i = 0, 5 do
            engine[voice_params[p]](i, v)
        end
    end
end

local ENV_TIME_MIN = 0.0015
local ENV_TIME_MAX = 5

local voice_loop_spec = controlspec.def {
    min = 0,
    max = 349,         -- 5.8 minutes;  2**24 samples at 48khz (limit of Supercollider BufRd.ar)
    warp = 'lin',
    step = 0.01,
    default = 1,
    units = '',
    quantum = 0.001,
    wrap = false
}

Symbiosis.voice_specs = {
    ["voice_attack"] = {
        spec = controlspec.def {
            min = ENV_TIME_MIN,
            max = ENV_TIME_MAX,
            warp = 'lin',
            step = 0.01,
            default = 1,
            units = '',
            quantum = 0.01,
            wrap = false
        },
    },
    ["voice_decay"] = {
        spec = controlspec.def {
            min = ENV_TIME_MIN,
            max = ENV_TIME_MAX,
            warp = 'lin',
            step = 0.01,
            default = 1,
            units = '',
            quantum = 0.01,
            wrap = false
        },
    },
    ["voice_env_curve"] = {
        spec = controlspec.def {
            min = -4,
            max = 4,
            warp = 'lin',
            step = 0.01,
            default = 1,
            units = '',
            quantum = 0.01,
            wrap = false
        },
    },
    ["voice_env_level"] = { spec = simple_spec },
    ["voice_level"] = { spec = simple_spec },
    ["voice_loop_start"] = { spec = voice_loop_spec },
    ["voice_loop_end"] = { spec = voice_loop_spec },
    ["voice_lpg_freq"] = { spec = filter_spec },
    ["voice_pan"] = { spec = controlspec.PAN },
    ["voice_rate"] = { spec = controlspec.RATE }
}

Symbiosis.voice_toggles = {
    ["voice_enable_env"] = {}, -- toggle
    ["voice_enable_lpg"] = {}, -- toggle
}

--[[
Engine.register_commands; count: 35
___ engine commands ___
*bass_mono_enabled:  i
*bass_mono_freq:  f
*comp_drive:  f
*comp_out_level:  f
*comp_ratio:  f
*comp_threshold:  f
*echo_feedback:  f
*echo_style:  s
*echo_time:  f
*echo_wet:  f
*hpf_dry:  f
*hpf_freq:  f
*hpf_res:  f
load_file:  s
*lpf_dry:  f
*lpf_freq:  f
*lpf_res:  f
metering_rate:  i
request_amp_history
voice_trigger:  i
voice_attack:  if
voice_decay:  if
voice_enable_env:  if
voice_enable_lpg:  if
voice_env_curve:  if
voice_env_level:  if
voice_level:  if
voice_loop_end:  if
voice_loop_start:  if
voice_lpg_freq:  if
voice_pan:  if
voice_rate:  if
]]

return Symbiosis
