local Symbiosis            = {}

Symbiosis.master_drive_min = -12
Symbiosis.master_drive_max = 18
Symbiosis.master_out_min   = -60
Symbiosis.master_out_max   = 0
Symbiosis.env_time_min     = 0.0015
Symbiosis.env_time_max     = 5

local engine_prefix        = "symbiosis_"

Symbiosis.echo_styles      = { "CLEAR", "DUST", "MIST" }

local filter_spec          = controlspec.def {
    min = 20,
    max = 20000,
    warp = 'exp',
    step = 0.01,
    default = 1000,
    units = 'Hz',
    quantum = 0.005,
    wrap = false
}

local simple_spec          = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = 0.01,
    default = 0,
    units = '',
    quantum = 0.01,
    wrap = false
}

local voice_loop_spec      = controlspec.def {
    min = 0,
    max = 349,                -- 5.8 minutes;  2**24 samples at 48khz (limit of Supercollider BufRd.ar)
    warp = 'lin',
    step = 1 / (48000 * 349), -- allow sample accurate output
    default = 1,
    units = 'sec',
    quantum = 1 / (48000 * 349),
    wrap = false
}

local env_spec             = controlspec.def {
    min = Symbiosis.env_time_min,
    max = Symbiosis.env_time_max,
    warp = 'exp',
    step = 0.001,
    default = 1,
    units = 'sec',
    quantum = 0.001 / (Symbiosis.env_time_max - Symbiosis.env_time_min),
    wrap = false
}

Symbiosis.specs            = {
    ["echo_wet"] = { spec = simple_spec },
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

Symbiosis.options          = {
    ["echo_style"] = {
        options = Symbiosis.echo_styles,
    }
}

local function no_underscore(s)
    return s:gsub("_", " ")
end

Symbiosis.get_id = function(command, voice_id)
    -- 1 <= voice id <= 6
    if voice_id ~= nil then
        if voice_id >= 1 and voice_id <= 6 then
            return engine_prefix .. command .. "_" .. voice_id
        else
            print("voice id should be between 1 and 6, found " .. voice_id)
        end
    else
        return engine_prefix .. command
    end
end

Symbiosis.voice_params = {
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

local function count_params()
    local keys = {}
    for k, _ in pairs(Symbiosis.specs) do
        table.insert(keys, k)
    end

    for k, _ in pairs(Symbiosis.options) do
        table.insert(keys, k)
    end
    local amt = #keys + (#Symbiosis.voice_params * 6)
    return amt
end


Symbiosis.voice_specs = {
    ["voice_attack"] = { spec = env_spec },
    ["voice_decay"] = { spec = env_spec },
    ["voice_env_curve"] = {
        spec = controlspec.def {
            min = -4,
            max = 4,
            warp = 'lin',
            step = 0.01,
            default = 1,
            units = '',
            quantum = 0.01 / 8,
            wrap = false
        },
    },
    ["voice_env_level"] = { spec = simple_spec },
    ["voice_level"] = { spec = simple_spec },
    ["voice_loop_start"] = { spec = voice_loop_spec },
    ["voice_loop_end"] = { spec = voice_loop_spec },
    ["voice_lpg_freq"] = { spec = filter_spec },
    ["voice_pan"] = { spec = controlspec.PAN },
    ["voice_rate"] = {
        spec = controlspec.def {
            min = -8,
            max = 8,
            warp = 'lin',
            step = 0.001,
            default = 1,
            units = '',
            quantum = 0.01 / 16,
            wrap = false
        },
    },
    ["metering_rate"] = {
        spec = controlspec.def {
            min = 0,
            max = 5000,
            warp = "lin",
            step = 1,
            default = 1000,
            units = 'Hz',
            quantum = 1 / 5000,
        }
    }
}

Symbiosis.voice_toggles = {
    ["voice_enable_env"] = {},
    ["voice_enable_lpg"] = {},
}

for _, param in pairs(Symbiosis.voice_params) do
    -- create methods that sets all 6 voices to the same value for a given param
    -- e.g. Symbiosis.each_voice_level(v)
    Symbiosis["each_" .. param] = function(v)
        print("each " .. param .. " to " .. v)
        for i = 1, 6 do
            params:set(Symbiosis.get_id(param, i), v)
        end
    end

    -- create methods that set an engine param for a given voice id,
    -- translating the lua 1-based indexes to Supercollider 0-based array indexes
    Symbiosis[param] = function(i, v)
        params:set(Symbiosis.get_id(param, i), v)
    end
end

function Symbiosis.voice_trigger(voice_id)
    if voice_id >= 1 and voice_id <= 6 then
        engine.voice_trigger(voice_id - 1)
    else
        print("voice_id should be between 1 and 6, found " .. voice_id)
    end
end

function Symbiosis.load_file(path)
    -- Perform sanity checks before sending to engine
    if util.file_exists(path) then
        local ch, samples, samplerate = audio.file_info(path)
        local duration = samples / samplerate
        print("loading file: " .. path)
        print("  channels:\t" .. ch)
        print("  samples:\t" .. samples)
        print("  sample rate:\t" .. samplerate .. "hz")
        print("  duration:\t" .. duration .. " sec")
        if samplerate ~= 48000 then
            print("Sample rate of 48KHz expected, found " .. samplerate)
        end
        if duration > 60 then
            -- TODO: check actual max duration
            print("Duration longer than 60 seconds are trimmed")
        end
        engine.load_file(path)
    else
        print('file not found: ' .. path .. ", loading cancelled")
    end
end

function Symbiosis.request_amp_history()
    -- Upon receiving this command, the engine sends back 2 OSC messages to
    -- /amp_history_left and /amp_history_right
    -- with the values of the last 32 samples that were recorded for this purpose.
    -- the speed of recording is dependent on engine.metering_rate().
    -- The result can be used for visualizations, e.g. a lissajous curve
    -- or an amplitude graph.
    engine.request_amp_history()
end

function Symbiosis.blob_to_table(blob, len)
    -- converts OSC blobs, assuming to be an array of 32 bit integers, to a lua table
    -- usage:
    --[[
    function osc.event(path, args, from)
        if path == "/amp_history_left" then
            local blob = args[1]
            result = Symbiosis.blob_to_table(blob)
        end
    end
  ]] --

    local ints = {}
    local size = #blob
    local offset = 1

    while offset <= size do
        -- iterate over blob, starting at `offset` (1 = first char)
        local value
        -- Unpack using ">i1" for big-endian single-byte integer, see lua docs 6.4.2
        value, offset = string.unpack(">i1", blob, offset)
        table.insert(ints, value)
    end

    return ints
end

function Symbiosis.process_amp_history(args)
    local blob = args[1]
    return Symbiosis.blob_to_table(blob)
end

function Symbiosis.process_waveform(args)
    local blob = args[1] -- the int8 array from OSC
    local channel = args[2] -- 0 or 1 for left, right
    print('channel: '.. tonumber(channel))
    local waveform = Symbiosis.blob_to_table(blob)
    for i, v in ipairs(waveform) do
      -- convert int8 array to floats
      waveform[i] = waveform[i] / 127
    end
    -- supercollider uses 0-based, convert to 1-based
    return channel + 1, waveform
end


function Symbiosis.add_params()
    params:add_group("Symbiosis", count_params())

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

    -- add controlspec-based voice params
    for command, entry in pairs(Symbiosis.voice_specs) do
        for i = 1, 6 do
            local sc_idx = i - 1
            local id = Symbiosis.get_id(command, i)
            params:add {
                type = "control",
                id = id,
                name = no_underscore(id),
                controlspec = entry.spec,
                action = function(v) engine[command](sc_idx, v) end
            }
            params:hide(id)
        end
    end

    -- add toggle-based voice params
    for command, _ in pairs(Symbiosis.voice_toggles) do
        for i = 1, 6 do
            local sc_idx = i - 1
            local id = Symbiosis.get_id(command, i)
            params:add {
                type = "binary",
                id = id,
                name = no_underscore(id),
                action = function(v) engine[command](sc_idx, v) end
            }
            params:hide(id)
        end
    end

    params:bang()
end

return Symbiosis
