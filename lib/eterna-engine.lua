local Eterna            = {}

-- constants that may be read by scripts
Eterna.master_drive_min = -12
Eterna.master_drive_max = 18
Eterna.master_out_min   = -60
Eterna.master_out_max   = 0
Eterna.env_time_min     = 0.0015
Eterna.env_time_max     = 5

local engine_prefix     = "eterna_engine_"

-- -.-
local sc_to_lua         = {
    [0] = 1,
    [1] = 2,
    [2] = 3,
    [3] = 4,
    [4] = 5,
    [5] = 6,
}

local lua_to_sc         = {
    [1] = 0,
    [2] = 1,
    [3] = 2,
    [4] = 3,
    [5] = 4,
    [6] = 5,
}
Eterna.echo_styles      = { "DUB", "MIST" }

local filter_spec       = controlspec.def {
    min = 20,
    max = 20000,
    warp = 'exp',
    step = 0.01,
    default = 1000,
    units = 'Hz',
    quantum = 0.005,
    wrap = false
}

local simple_spec       = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = 0.01,
    default = 0,
    units = '',
    quantum = 0.01,
    wrap = false
}

Eterna.params           = {
    specs   = {
        ["echo_wet"] = controlspec.def {
            min = 0,
            max = 1,
            warp = 'lin',
            step = 0.01,
            default = 0.5,
            units = '',
            quantum = 0.01,
            wrap = false
        },
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
        ["echo_feedback"] = controlspec.def {
            min = 0,
            max = 1,
            warp = 'lin',
            step = 0.01,
            default = 0.4,
            units = '',
            quantum = 0.01,
            wrap = false
        },
        ["lpf_freq"] = filter_spec,
        ["hpf_freq"] = filter_spec,
        ["lpf_res"] = controlspec.def {
            min = 0.0,
            max = 0.98,
            warp = 'lin',
            step = 0.01,
            default = 0,
            units = '',
            quantum = 0.02,
            wrap = false
        },
        ["hpf_res"] = controlspec.def {
            min = 0.0,
            max = 0.98,
            warp = 'lin',
            step = 0.01,
            default = 0,
            units = '',
            quantum = 0.02,
            wrap = false
        },
        ["lpf_dry"] = simple_spec,
        ["hpf_dry"] = simple_spec,
        ["comp_drive"] = controlspec.def {
            min = 0,
            max = 24,
            warp = 'lin',
            step = 0.01,
            default = 0,
            units = 'dB',
            quantum = 0.2 / (Eterna.master_drive_max - Eterna.master_drive_min),
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
            min = Eterna.master_out_min,
            max = Eterna.master_out_max,
            warp = 'lin',
            step = 0.1,
            default = 1,
            units = 'dB',
            quantum = 0.2 / (Eterna.master_out_max - Eterna.master_out_min),
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
            max = 600, -- values > approx 650 seem to cause issues with processing on SC side
            warp = "lin",
            step = 1,
            default = 0,
            units = 'Hz',
            quantum = 1 / 5000,
        }
    },
    options = {
        ["echo_style"] = {
            options = Eterna.echo_styles,
            default = 2,
        },
    },
    voices  = {
        specs = {
            ["voice_env_level"] = simple_spec,
            ["voice_level"] = simple_spec,
            ["voice_lpg_freq"] = filter_spec,
            ["voice_pan"] = controlspec.PAN,
            ["voice_drive"] = controlspec.def {
                min = 0,
                max = 24,
                warp = "lin",
                step = 0.01,
                default = 0,
                units = 'dB',
                quantum = 0.01,
            }
        },
        numbers = {
            ["voice_loop_start"] = {
                min = 0,
                max = (2 ^ 24) / 48000,
                default = 0,
                wrap = true
            },
            ["voice_loop_end"] = {
                min = 0,
                max = (2 ^ 24) / 48000,
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
                min = Eterna.env_time_min,
                max = Eterna.env_time_max,
                default = 0.1,
                wrap = false
            },
            ["voice_decay"] = {
                min = Eterna.env_time_min,
                max = Eterna.env_time_max,
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
        },
        options = {
            ["voice_bufnum"] = {
                options = { 0, 1, 2, 3, 4, 5 },
            },
        }
    }
}

-- All polls defined in the engine
Eterna.available_polls  = {
    ["pre_comp"] = { "pre_comp_left", "pre_comp_right" },
    ["post_comp"] = { "post_comp_left", "post_comp_right" },
    ["post_gain"] = { "post_gain_left", "post_gain_right" },
    ["master"] = { "master_left", "master_right" },
    ["voice_amp"] = { "voice1amp", "voice2amp", "voice3amp", "voice4amp", "voice5amp", "voice6amp" },
    ["voice_env"] = { "voice1env", "voice2env", "voice3env", "voice4env", "voice5env", "voice6env" },
}

Eterna.get_polls        = function(name, as_tuple)
    -- Returns poll instances corresponding to the mapping in Eterna.available_polls
    -- Usage:
    --[[
          left, right = engine_lib.enable_poll("pre_comp")
    ---]]
    if as_tuple == nil then as_tuple = true end -- default to returning tuple
    local t = Eterna.available_polls[name]
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

Eterna.get_id = function(command, voice_id)
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

-- Generic helpers
local function set_param_by_delta(d, param_id, quantum)
    local incr = d * quantum
    local curr = params:get_raw(param_id)
    local new = curr + incr
    params:set_raw(param_id, new)
end

local function modify(param_id, v, is_delta)
    if is_delta then
        local spec = Eterna.params.specs[param_id]
        local quantum
        if spec then
            quantum = spec.quantum
        else
            quantum = 1 / 100
        end
        set_param_by_delta(v, Eterna.get_id(param_id), quantum)
    else
        params:set(param_id, v)
    end
end

local function set_each_voice_param(param, v)
    for i = 1, 6 do
        params:set(Eterna.get_id(param, i), v)
    end
end

local function modify_voice(param, i, v, is_delta)
    if i < 1 or i > 6 then
        print("Error: voice for " .. param .. "() should be 1..6, got " .. i)
        return
    end

    local param_id = Eterna.get_id(param, i)

    if is_delta then
        local spec = Eterna.params.voices.specs[param_id]
        local quantum
        if spec then
            quantum = spec.quantum
        else
            quantum = 1 / 100
        end
        set_param_by_delta(v, param_id, quantum)
    else
        params:set(param_id, v)
    end
end


-- Voice helper methods
function Eterna.each_voice_attack(v)
    set_each_voice_param("voice_attack", v)
end

function Eterna.voice_attack(i, v)
    modify_voice("voice_attack", i, v)
end

function Eterna.each_voice_decay(v)
    set_each_voice_param("voice_decay", v)
end

function Eterna.voice_decay(i, v)
    modify_voice("voice_decay", i, v)
end

function Eterna.each_voice_enable_lpg(v)
    set_each_voice_param("voice_enable_lpg", v)
end

function Eterna.voice_enable_lpg(i, v)
    modify_voice("voice_enable_lpg", i, v)
end

function Eterna.each_voice_env_curve(v)
    set_each_voice_param("voice_env_curve", v)
end

function Eterna.voice_env_curve(i, v)
    modify_voice("voice_env_curve", i, v)
end

function Eterna.each_voice_env_level(v)
    set_each_voice_param("voice_env_level", v)
end

function Eterna.voice_env_level(i, v)
    modify_voice("voice_env_level", i, v)
end

function Eterna.each_voice_level(v)
    set_each_voice_param("voice_level", v)
end

function Eterna.voice_level(i, v)
    modify_voice("voice_level", i, v)
end

function Eterna.each_voice_loop_start(v)
    set_each_voice_param("voice_loop_start", v)
end

function Eterna.voice_loop_start(i, v)
    modify_voice("voice_loop_start", i, v)
end

function Eterna.each_voice_loop_end(v)
    set_each_voice_param("voice_loop_end", v)
end

function Eterna.voice_loop_end(i, v)
    modify_voice("voice_loop_end", i, v)
end

function Eterna.each_voice_lpg_freq(v)
    set_each_voice_param("voice_lpg_freq", v)
end

function Eterna.voice_lpg_freq(i, v)
    modify_voice("voice_lpg_freq", i, v)
end

function Eterna.each_voice_pan(v)
    set_each_voice_param("voice_pan", v)
end

function Eterna.voice_pan(i, v)
    modify_voice("voice_pan", i, v)
end

function Eterna.each_voice_rate(v)
    set_each_voice_param("voice_rate", v)
end

function Eterna.voice_rate(i, v)
    modify_voice("voice_rate", i, v)
end

function Eterna.each_voice_bufnum(v)
    set_each_voice_param("voice_bufnum", v)
end

function Eterna.voice_bufnum(i, v)
    modify_voice("voice_bufnum", i, v)
end

function Eterna.each_voice_drive(v, is_delta)
    for i = 1, 6 do
        modify_voice("voice_drive", i, v, is_delta)
    end
end

function Eterna.voice_drive(i, v)
    modify_voice("voice_drive", i, v)
end

function Eterna.voice_trigger(voice)
    if voice >= 1 and voice <= 6 then
        engine.voice_trigger(lua_to_sc[voice])
    else
        print("voice should be between 1 and 6, found " .. voice)
    end
end

-- Echo
function Eterna.echo_wet(v, is_delta)
    modify("echo_wet", v, is_delta)
end

function Eterna.echo_time(v, is_delta)
    modify("echo_time", v, is_delta)
end

function Eterna.echo_feedback(v, is_delta)
    modify("echo_feedback", v, is_delta)
end

-- LPF
function Eterna.lpf_freq(v, is_delta)
    modify("lpf_freq", v, is_delta)
end

function Eterna.lpf_res(v, is_delta)
    modify("lpf_res", v, is_delta)
end

function Eterna.lpf_dry(v, is_delta)
    modify("lpf_dry", v, is_delta)
end

-- HPF
function Eterna.hpf_freq(v, is_delta)
    modify("hpf_freq", v, is_delta)
end

function Eterna.hpf_res(v, is_delta)
    modify("hpf_res", v, is_delta)
end

function Eterna.hpf_dry(v, is_delta)
    modify("hpf_dry", v, is_delta)
end

-- Compressor
function Eterna.comp_drive(v, is_delta)
    modify("comp_drive", v, is_delta)
end

function Eterna.comp_ratio(v, is_delta)
    modify("comp_ratio", v, is_delta)
end

function Eterna.comp_threshold(v, is_delta)
    modify("comp_threshold", v, is_delta)
end

function Eterna.comp_out_level(v, is_delta)
    modify("comp_out_level", v, is_delta)
end

-- Bass mono
function Eterna.bass_mono_freq(v, is_delta)
    modify("bass_mono_freq", v, is_delta)
end

-- Metering
function Eterna.metering_rate(v, is_delta)
    modify("metering_rate", v, is_delta)
end

function Eterna.verify_file(path, channel, buffer)
    -- Perform sanity checks, this may be called prior to Eterna.load_file()
    if util.file_exists(path) then
        local channels, samples, samplerate = audio.file_info(path)
        local duration = samples / samplerate
        if channel == 1 then
            print("loading file: " .. path)
            print("  channels:\t" .. channels)
            print("  samples:\t" .. samples)
            print("  sample rate:\t" .. samplerate .. "hz")
            print("  duration:\t" .. duration .. " sec")
        else
            print("loading channel "..channel)
        end

        if samplerate ~= 48000 then
            print("Sample rate of 48KHz expected, found " ..
                samplerate .. ". The file will load but playback at the wrong pitch.")
        end
        if duration > 349 then
            print("Files longer than 349 seconds are truncated")
        end
        if channel > channels then
            print("Can't load channel " .. channel .. ', file only has' .. channels .. ' channels')
            return false
        elseif buffer > 6 or buffer < 1 then
            print("buffer should be 1..6")
            return false
        end
        return true
    else
        print('file not found: ' .. path .. ", loading cancelled")
        return false
    end
end

function Eterna.load_file(path, channel, buffer)
    engine.load_channel_to_buffer(path, lua_to_sc[channel], lua_to_sc[buffer])
end

function Eterna.normalize(buffer)
    if buffer > 6 or buffer < 1 then
        print("buffer should be 1..6")
        return false
    end

    -- normalizes an individual buffer
    engine.normalize(lua_to_sc[buffer])
    return true
end

function Eterna.get_waveform(buffer, num_samples)
    print('Requesting waveform for buffer ' .. buffer)
    engine.get_waveform(lua_to_sc[buffer], num_samples)
end

function Eterna.request_amp_history()
    -- Upon receiving this command, the engine sends back an OSC message
    -- to /amp_history
    -- with the int8 values of the last 32 samples that were recorded for this purpose.
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

function Eterna.process_amp_history(args)
    -- usage:
    --[[
    sym = include('lib/eterna_engine')

    function osc.event(path, args, from)
        local values
        if path == "/amp_history" then
            left, right = engine_lib.process_amp_history(args)
        end
    end
  ]] --
    local left = args[1]
    local right = args[2]
    return blob_to_table(left), blob_to_table(right)
end

function Eterna.process_waveform(args)
    local blob = args[1]   -- the int8 array from OSC
    local buffer = args[2] -- 0-5
    buffer = sc_to_lua[buffer]
    local waveform = blob_to_table(blob)
    for i, v in ipairs(waveform) do
        -- convert int8 array to floats
        waveform[i] = waveform[i] / 127
    end
    return buffer, waveform
end

function Eterna.add_params()
    -- Script has to call this method in order to add params. All will be hidden by default,
    -- as there're so many they may not make much sense to the end user.
    -- Scripts may still expose (a selection of ) these,
    -- or define controlspecs on top of them,
    -- tuned to their desired range, steps, formatting, grouping, etc.

    -- add controlspec-based params
    for command, spec in pairs(Eterna.params.specs) do
        local id = Eterna.get_id(command)
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
    for command, entry in pairs(Eterna.params.options) do
        local id = Eterna.get_id(command)
        params:add {
            type = "option",
            id = id,
            name = no_underscore(command),
            options = entry.options,
            default = entry.default,
            action = function(v) engine[command](entry.options[v]) end
        }
        params:hide(id)
    end

    -- add controlspec-based voice params (define one per voice)
    for command, entry in pairs(Eterna.params.voices.specs) do
        for voice = 1, 6 do
            local id = Eterna.get_id(command, voice)
            params:add({
                type = "control",
                id = id,
                name = no_underscore(id),
                controlspec = entry,
                action = function(v) engine[command](lua_to_sc[voice], v) end
            })
            params:hide(id)
        end
    end

    -- add toggle-based voice params (define one per voice)
    for _, command in pairs(Eterna.params.voices.toggles) do
        for voice = 1, 6 do
            local id = Eterna.get_id(command, voice)
            params:add({
                type = "binary",
                behavior = "toggle",
                id = id,
                name = no_underscore(id),
                action = function(v)
                    engine[command](lua_to_sc[voice], v)
                end
            })
            params:hide(id)
        end
    end

    -- add options-based voice params (define one per voice)
    for command, entry in pairs(Eterna.params.voices.options) do
        for voice = 1, 6 do
            local id = Eterna.get_id(command, voice)
            params:add({
                type = "option",
                id = id,
                name = no_underscore(id),
                options = entry.options,
                action = function(v)
                    engine[command](lua_to_sc[voice], entry.options[v])
                end
            })
            params:hide(id)
        end
    end

    -- add number-based voice params (define one per voice)
    for command, entry in pairs(Eterna.params.voices.numbers) do
        print("adding " .. command)
        for i = 1, 6 do
            local sc_idx = i - 1
            local id = Eterna.get_id(command, i)
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
end

function Eterna.osc_event(path, args, from)
    if path == "/waveform" then
        channel, waveform = Eterna.process_waveform(args)
        Eterna.on_waveform(waveform, channel)
        --
    elseif path == "/duration" then
        local duration = tonumber(args[1])
        Eterna.on_duration(duration)
        --
    elseif path == "/amp_history" then
        local left, right = engine_lib.process_amp_history(args)
        Eterna.on_amp_history(left, right)
        --
    elseif path == "/file_load_result" then
        local success = args[1]
        local file_path = args[2]
        local channel = sc_to_lua[args[3]]
        local buffer = sc_to_lua[args[4]]
        if success == 1 then
            Eterna.on_file_load_success(file_path, channel, buffer)
        else
            Eterna.on_file_load_fail(file_path, channel, buffer)
        end
        --
    elseif path == "/normalized" then
        local voice = sc_to_lua[args[1]]
        Eterna.on_normalize(voice)
    elseif path == "/pong" then
        Eterna.on_pong()
    end 
end

function Eterna.ping()
    -- Initiates connection check
    engine.ping()
end

function Eterna.flush()
    -- clears all voices
    engine.flush()
end

-- These functions can be overloaded by script
function Eterna.on_normalize(voice) end

function Eterna.on_duration(duration) end

function Eterna.on_waveform(waveform, channel) end

function Eterna.on_file_load_success(path, channel, buffer) end

function Eterna.on_amp_history(left, right) end

function Eterna.on_pong() print("pong") end

function Eterna.install_osc_hook()
    -- Allows this module to process SuperCollider's OSC events;
    -- if a script also defines its own osc.event function,
    -- this hook should be invoked after that definition.

    -- reference to script's osc.event function (if any)
    original = osc.event

    -- capture osc events
    osc.event = function(path, args, from)
        -- process event within this engine
        Eterna.osc_event(path, args, from)

        -- pass to original handler
        if original then
            return original(path, args, from)
        end
    end
end

return Eterna
