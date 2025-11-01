local Symbiosis = {}
local Formatters = require 'formatters'
local ENV_FILTER_MIN = 50
local ENV_FILTER_MAX = 20000
local RATE_MIN = 1 / 8
local RATE_MAX = 8

-- goals of this file:
--- abstract ```for i=1,6 do engine.func(i-1, val) end ```
--- any params that only do `engine.func()` become obsolete, currently:
-- done 
--- ID_ECHO_DRYWET
--- ID_ECHO_FEEDBACK
--- ID_ECHO_STYLE (with table lookup)
--- ID_HPF_FREQ
--- ID_HPF_RES
--- ID_LPF_FREQ
--- ID_LPF_RES
-- todo
--- ID_MASTER_COMP_DRIVE
--- ID_MASTER_MONO_FREQ (with table lookup)

local ID_ECHO_WET = "symbiosis_echo_wet"
local ID_ECHO_FEEDBACK = "symbiosis_echo_feedback"
local ID_ECHO_STYLE = "symbiosis_echo_style"
local ID_LPF_RES = "symbiosis_lpf_res"
local ID_HPF_RES = "symbiosis_hpf_res"

ECHO_STYLES = { "CLEAR", "DUST", "MIST" }

Symbiosis.specs = {
    ["echo_wet"] = {
        id = ID_ECHO_WET,
        spec = controlspec.def {
            min = 0,
            max = 1,
            warp = 'lin',
            step = 0.01,
            default = 0.2,
            units = '',
            quantum = 0.02,
            wrap = false
        }
    },
    ["echo_feedback"] = {
        id = ID_ECHO_FEEDBACK,
        spec = controlspec.def {
            min = 0,
            max = 1,
            warp = 'lin',
            step = 0.01,
            default = 0.6,
            units = '',
            quantum = 0.02,
            wrap = false
        }
    },
    ["lpf_freq"] = {
        id = ID_LPF_FREQ,
        spec = controlspec.def {
            min = 20,
            max = 20000,
            warp = 'exp',
            step = 0.1,
            default = 440.0,
            units = 'Hz',
            quantum = 0.005,
            wrap = false
        }
    },
    ["hpf_freq"] = {
        id = ID_HPF_FREQ,
        spec = controlspec.def {
            min = 20,
            max = 20000,
            warp = 'exp',
            step = 0.1,
            default = 440.0,
            units = 'Hz',
            quantum = 0.005,
            wrap = false
        }
    },
    ["lpf_res"] = {
        id = ID_LPF_RES,
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
        id = ID_HPF_RES,
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
}

Symbiosis.options = {
    ["echo_style"] = {
        id = ID_ECHO_STYLE,
        options = ECHO_STYLES,
    }
}

local keys = {}
for k, _ in pairs(Symbiosis.specs) do
    table.insert(keys, k)
end

function Symbiosis.add_params()
    params:add_group("Symbiosis", #keys)

    -- add controlspec-based params
    for command, entry in pairs(Symbiosis.specs) do
        params:add {
            type = "control",
            id = entry.id,
            name = command,
            controlspec = entry.spec,
            action = function(x) engine[command](x) end
        }
    end

    -- add option-based params
    for command, entry in pairs(Symbiosis.options) do
        params:add {
            type = "option",
            id = entry.id,
            name = command,
            options = entry.options,
            action = function(v) engine[command](entry.options[v]) end
        }
    end
    params:bang()
end

-- Voice engine commands are not exposed as pset params here;
-- there're so many of them (11 params * 6 voices) that it's pretty bad UX
-- to expose them all to the end user individually.
-- Depending on the script, acceptable ranges may vary -
-- e.g. for attack and decay, depending on whether it's a percussive or drone app.
-- Scripts using this engine may instead define params and controls themselves.
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


--[[
Engine.register_commands; count: 35
___ engine commands ___
bass_mono_dry:  f
bass_mono_enabled:  i
bass_mono_freq:  f
comp_drive:  f
comp_out_level:  f
comp_ratio:  f
comp_threshold:  f
echo_feedback:  f
echo_style:  s
echo_time:  f
echo_wet:  f
hpf_dry:  f
hpf_freq:  f
hpf_gain:  f
hpf_res:  f
load_file:  s
lpf_dry:  f
lpf_freq:  f
lpf_gain:  f
lpf_res:  f
metering_rate:  i
request_amp_history
trigger:  i
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
