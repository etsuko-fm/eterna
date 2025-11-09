local Symbiosis            = {}

-- constants that may be read by scripts
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

Symbiosis.params           = {
    specs   = {
        ["echo_wet"] = simple_spec,
        ["echo_time"] = controlspec.def {
            min = 0,
            max = 2, -- seconds
            warp = 'lin',
            step = 0.001,
            default = 0.2,
            units = '',
            quantum = 0.001,
            wrap = false
        },
        ["echo_feedback"] = simple_spec,
        ["lpf_freq"] = filter_spec,
        ["hpf_freq"] = filter_spec,
        ["lpf_res"] = controlspec.def {
            min = 0.0,
            max = 0.98,
            warp = 'lin',
            step = 0.01,
            default = 0.2,
            units = '',
            quantum = 0.02,
            wrap = false
        },
        ["hpf_res"] = controlspec.def {
            min = 0.0,
            max = 0.98,
            warp = 'lin',
            step = 0.01,
            default = 0.2,
            units = '',
            quantum = 0.02,
            wrap = false
        },
        ["lpf_dry"] = simple_spec,
        ["hpf_dry"] = simple_spec,
        ["comp_drive"] = controlspec.def {
            min = -12,
            max = 18,
            warp = 'lin',
            step = 0.01,
            default = 0,
            units = 'dB',
            quantum = 0.1 / (Symbiosis.master_drive_max - Symbiosis.master_drive_min),
            wrap = false
        },
        ["comp_ratio"] = controlspec.def {
            min = 1,
            max = 20,
            warp = 'lin',
            step = 0.01,
            default = 1,
            units = '',
            quantum = 0.005,
            wrap = false
        },
        ["comp_threshold"] = controlspec.def {
            min = 0.01,
            max = 1,
            warp = 'lin',
            step = 0.01,
            default = 0,
            units = '',
            quantum = 0.01,
            wrap = false
        },
        ["comp_out_level"] = controlspec.def {
            min = Symbiosis.master_out_min,
            max = Symbiosis.master_out_max,
            warp = 'lin',
            step = 0.1,
            default = 1,
            units = 'dB',
            quantum = 0.2 / (Symbiosis.master_out_max - Symbiosis.master_out_min),
            wrap = false
        },
        ["bass_mono_freq"] = controlspec.def {
            min = 20,
            max = 20000,
            warp = 'exp',
            step = 0.1,
            default = 1,
            units = 'Hz',
            quantum = 0.005,
            wrap = false
        },
        ["metering_rate"] = controlspec.def {
            min = 0,
            max = 5000,
            warp = "lin",
            step = 1,
            default = 1000,
            units = 'Hz',
            quantum = 1 / 5000,
        }
    },
    options = {
        ["echo_style"] = {
            options = Symbiosis.echo_styles,
        },
    },
    voices  = {
        specs = {
            ["voice_env_level"] = simple_spec,
            ["voice_level"] = simple_spec,
            ["voice_lpg_freq"] = filter_spec,
            ["voice_pan"] = controlspec.PAN,
        },
        numbers = {
            ["voice_loop_start"] = {
                min = 0,
                max = (2^22)/48000,
                default = 0,
                wrap = true
            },
            ["voice_loop_end"] = {
                min = 0,
                max = (2^22)/48000,
                default = 0,
                wrap = true
            },
            ["voice_rate"] = {
                min = -8,
                max = 8,
                default = 1,
                wrap = false
            },
            ["voice_attack"] = {
                min = Symbiosis.env_time_min,
                max = Symbiosis.env_time_max,
                default = 0.1,
                wrap = false
            },
            ["voice_decay"] = {
                min = Symbiosis.env_time_min,
                max = Symbiosis.env_time_max,
                default = 1,
                wrap = false
            },
            ["voice_env_curve"] = {
                min = -4,
                max = 4,
                default = 1,
                wrap = false
            },
        },
        -- Voice params that are binary toggles
        toggles = {
            "voice_enable_lpg",
        }
    }
}

-- All voice params, used to define helper methods
Symbiosis.voice_params     = {
    "voice_attack",
    "voice_decay",
    "voice_enable_lpg",
    "voice_env_curve",
    "voice_env_level",
    "voice_level",
    "voice_loop_start",
    "voice_loop_end",
    "voice_lpg_freq",
    "voice_pan",
    "voice_rate",
}

-- all polls defined in the engine
Symbiosis.available_polls  = {
    ["file_loaded"] = { "file_loaded" },
    ["pre_comp"] = { "pre_comp_left", "pre_comp_right" },
    ["post_comp"] = { "post_comp_left", "post_comp_right" },
    ["post_gain"] = { "post_gain_left", "post_gain_right" },
    ["master"] = { "master_left", "master_right" },
    ["voice_amp"] = { "voice1amp", "voice2amp", "voice3amp", "voice4amp", "voice5amp", "voice6amp" },
    ["voice_env"] = { "voice1env", "voice2env", "voice3env", "voice4env", "voice5env", "voice6env" },
}

Symbiosis.get_polls      = function(name, as_tuple)
    -- Returns poll instances corresponding to the mapping in Symbiosis.available_polls
    -- Usage:
    --[[
          left, right = sym.enable_poll("pre_comp")
    ---]]
    if as_tuple == nil then as_tuple = true end -- default to returning tuple
    local t = Symbiosis.available_polls[name]
    local result = {}
    if t then
        for n, poll_name in pairs(t) do
            result[n] = poll.set(poll_name)
        end
    else
        print("poll does not exist: " .. name)
    end
    if as_tuple then
        -- return tuple
        return table.unpack(result)
    end
    -- return table
    return result
end

local function no_underscore(s) return s:gsub("_", " ") end

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

-- Voice helper methods
for _, param in pairs(Symbiosis.voice_params) do
    -- create methods that sets all 6 voices to the same value for a given param
    -- e.g. Symbiosis.each_voice_level(v)
    Symbiosis["each_" .. param] = function(v)
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
        if duration > 87.3 then
            print("Files longer than 87.3 seconds are trimmed")
        end
        engine.load_file(path)
        return true
    else
        print('file not found: ' .. path .. ", loading cancelled")
        return false
    end
end

function Symbiosis.normalize()
    -- normalize buffers individually (does not preserve peaks relative to each other)
    engine.normalize()
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

local function blob_to_table(blob, len)
    -- converts OSC blobs, assuming to be an array of 32 bit integers, to a lua table
    -- example usage:
    --[[
    function osc.event(path, args, from)
        if path == "/amp_history_left" then
            local blob = args[1]
            result = blob_to_table(blob)
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
    -- usage:
    --[[
    sym = include('lib/symbiosis_engine')

    function osc.event(path, args, from)
        local values
        if path == "/amp_history_left" then
            values = sym.process_amp_history(args)
        end
    end
  ]] --
    local blob = args[1]
    return blob_to_table(blob)
end

function Symbiosis.process_waveform(args)
    local blob = args[1]    -- the int8 array from OSC
    local channel = args[2] -- 0 or 1 for left, right
    print('channel: ' .. tonumber(channel))
    local waveform = blob_to_table(blob)
    for i, v in ipairs(waveform) do
        -- convert int8 array to floats
        waveform[i] = waveform[i] / 127
    end
    -- supercollider uses 0-based, convert to 1-based
    return channel + 1, waveform
end

function Symbiosis.add_params()
    -- Script has to call this method in order to add params. All will be hidden by default,
    -- as there're so many they may not make much sense to the end user.
    -- Scripts may still expose (a selection of ) these,
    -- or define controlspecs on top of them, 
    -- tuned to their desired range, steps, formatting, grouping, etc.

    -- add controlspec-based params
    for command, spec in pairs(Symbiosis.params.specs) do
        local id = Symbiosis.get_id(command)
        params:add {
            type = "control",
            id = id,
            name = no_underscore(command),
            controlspec = spec,
            action = function(x) engine[command](x) end
        }
        params:hide(id)
    end

    -- add option-based params
    for command, entry in pairs(Symbiosis.params.options) do
        local id = Symbiosis.get_id(command)
        params:add {
            type = "option",
            id = id,
            name = no_underscore(command),
            options = entry.options,
            action = function(v) engine[command](entry.options[v]) end
        }
        params:hide(id)
    end

    -- add controlspec-based voice params (define one per voice)
    for command, entry in pairs(Symbiosis.params.voices.specs) do
        for i = 1, 6 do
            local sc_idx = i - 1
            local id = Symbiosis.get_id(command, i)
            params:add({
                type = "control",
                id = id,
                name = no_underscore(id),
                controlspec = entry,
                action = function(v) engine[command](sc_idx, v) end
            })
            params:hide(id)
        end
    end

    -- add toggle-based voice params (define one per voice)
    for _, command in pairs(Symbiosis.params.voices.toggles) do
        for i = 1, 6 do
            local sc_idx = i - 1
            local id = Symbiosis.get_id(command, i)
            params:add({
                type = "binary",
                behavior = "toggle",
                id = id,
                name = no_underscore(id),
                action = function(v)
                    engine[command](sc_idx, v)
                end
            })
            params:hide(id)
        end
    end

    -- add number-based voice params (define one per voice)
    for command, entry in pairs(Symbiosis.params.voices.numbers) do
        print("adding " .. command)
        for i = 1, 6 do
            local sc_idx = i - 1
            local id = Symbiosis.get_id(command, i)
            params:add({
                type = "number",
                id = id,
                name = no_underscore(id),
                min = entry.min,
                max = entry.max,
                default = entry.default,
                wrap = entry.wrap,
                action = function(v) engine[command](sc_idx, v) end
            })
            params:hide(id)
        end
    end
    params:bang()
end

return Symbiosis
