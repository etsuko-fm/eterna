local SampleGraphic = include(from_root("lib/graphics/SampleGraphic"))

local page_name = "SAMPLE"
local fileselect = require('fileselect')
local page_disabled = false

local filename = ""
-- local selected_sample = nil -- assign path to load a default sample on script startup (e.g. "audio/etsuko/chris/play-safe.wav")
local selected_sample = "audio/etsuko/chris/play-safe.wav"

-- In rare cases sample loading may fail, these are for a retry mechanism
local MAX_RETRIES = 1
local retries = {}

-- State of loading file, per channel of file
local ready = {}
local slice_lfo

local active_channels = 1


-- when true, preloads a sample
local debug_mode = true

local page = Page:create({
    name = page_name,
    --
    sample_duration = nil,
})

local function path_to_file_name(file_path)
    -- strips '/foo/bar/audio.wav' to 'audio.wav'
    local split_at = string.match(file_path, "^.*()/")
    return string.sub(file_path, split_at + 1)
end

local function remove_extension(filename)
    return filename:match("^(.*)%.[^%.]+$") or filename
end

local function to_sample_name(path)
    local s = string.upper(remove_extension(path_to_file_name(path)))
    return util.trim_string_to_width(s, 80)
end

function page:get_slice_length()
    -- returns slice length in seconds
    local n_slices = params:get(ID_SAMPLER_NUM_SLICES)
    if n_slices and self.sample_duration then
        return (1 / n_slices) * self.sample_duration
    else
        return nil
    end
end

function page:update_loop_ranges()
    -- updates the playback range of each voice in params, based on num_slices, slices_start, and sample duration
    local n_slices = params:get(ID_SAMPLER_NUM_SLICES)

    -- if slices > num_voices, not all slices can be assigned to a voice
    -- 6 consecutive slices are assigned to voice 1-6
    local start = params:get(ID_SAMPLER_START)

    -- edit buffer ranges per voice
    local slice_start_timestamps = {} -- start position of each slice, in seconds
    local slice_length = self:get_slice_length()
    if not slice_length then return end

    for i = 1, n_slices do
        -- slice 1 starts at 0.0 seconds;
        -- slice 2 starts at 1*slice_length,
        -- slice 3 starts at 2*slice_length, etc
        slice_start_timestamps[i] = (i - 1) * slice_length
    end

    for i = 0, 5 do
        local voice = i + 1

        -- start >= 1; table indexing starts at 1;
        --- start + i maps from 1 to 6 when start = 1,
        --- or 26-32 when start=26.
        --- this works fine for n_slices > 6; else, voices need to recycle slices;
        --- hence the modulo.
        local slice_index = util.wrap(start + i, 1, n_slices)
        self.graphic.active_slices[voice] = slice_index -- update slice graphic
        local start_pos = slice_start_timestamps[slice_index]
        -- loop start/end works as buffer range when loop not enabled
        -- end point is where the next slice starts
        local end_pos = start_pos + (slice_length * .999) -- leave a small gap to prevent overlap

        local voice_loop_start = engine_lib.get_id("voice_loop_start", voice)
        local voice_loop_end = engine_lib.get_id("voice_loop_end", voice)
        params:set(voice_loop_start, start_pos)
        params:set(voice_loop_end, end_pos)
    end
end

local function all_true(t)
    for _, v in pairs(t) do
        if not v then
            return false
        end
    end
    return true
end



function page:load_sample(file)
    print("page:load_sample(" .. file .. ")")
    -- use specified `file` as a sample and store enabled length of buffer in state
    if not file or file == "-" then return end
    local num_channels = audio_util.num_channels(file)
    ready = {}
    -- TODO: Clear buffers not needed before loading new
    retries = {}
    for channel = 1, math.min(num_channels, 6) do
        -- load file to buffer corresponding to channel
        ready[channel] = false
        local buffer = channel
        if engine_lib.load_file(file, channel, buffer) then
            active_channels = num_channels
            self.graphic.num_channels = num_channels
        end
    end
end

function engine_lib.on_normalize(buffer)
    print("buffer " .. buffer .. " normalized")
    engine_lib.get_waveform(buffer, 64)
end

function engine_lib.on_duration(duration)
    page:set_sample_duration(duration)
end

function engine_lib.on_waveform(waveform, channel)
    print("Lua: /waveform received from SC")
    page.graphic.waveform_graphics[channel].samples = waveform
end

function engine_lib.on_file_load_success(path, channel, buffer)
    print('successfully loaded channel ' .. channel .. " of " .. path .. " to buffer " .. buffer)
    print('normalizing...')
    ready[channel] = true
    engine_lib.normalize(buffer)
    if all_true(ready) then
        for voice = 1, 6 do
            local buffer_idx = util.wrap(voice, 1, active_channels)
            params:set(engine_lib.get_id("voice_bufnum", voice), buffer_idx)
            print("lua: voice " .. voice .. "set to buffer " .. buffer_idx)
        end
    end
end

function engine_lib.on_file_load_fail(path, channel, buffer)
    if retries[channel] == nil then
        retries[channel] = 0
    end
    if retries[channel] < MAX_RETRIES then
        -- try once more
        print("retry #" .. retries[channel])
        engine_lib.load_file(path, channel, buffer)
        retries[channel] = retries[channel] + 1
    else
        print('failed to load channel ' .. channel .. "of " .. path .. " to buffer " .. buffer)
    end
    -- deselect sample? retry?
end

local function select_sample()
    print("select_sample()")
    local function callback(file_path)
        if file_path ~= 'cancel' then
            print("setting path to " .. file_path)
            params:set(ID_SAMPLER_AUDIO_FILE, file_path)
        end
        page_disabled = false -- proceed with rendering page instead of file menu
        page_indicator_disabled = false
    end
    fileselect.enter(_path.audio, callback, "audio")
    page_disabled = true           -- don't render current page
    page_indicator_disabled = true -- hide page indicator
end

local function constrain_max_start(num_slices)
    -- side effect of adjusting controlspec_slice_start.maxval, is that (raw * maxval) of the controlspec
    -- is a new value, which is why this method implicitly adjusts the value of slice start
    controlspec_slice_start.maxval = num_slices
end

function page:action_num_slices(v)
    -- update max start based on number of slices
    constrain_max_start(v)
    self.graphic.slice_len = 1 / v
    self.graphic.num_slices = v
    self:update_loop_ranges()
end

function page:action_slice_start(v)
    self:update_loop_ranges()
end

local function adjust_num_slices(d)
    if selected_sample then
        misc_util.adjust_param(d, ID_SAMPLER_NUM_SLICES, controlspec_num_slices.quantum)
    end
end

local function adjust_slice_start(d)
    if selected_sample then
        local p = ID_SAMPLER_START
        local max_slices = params:get(ID_SAMPLER_NUM_SLICES)
        local new = util.wrap(params:get(p) + d, 1, max_slices)
        params:set(p, new)
    end
end

local function cycle_lfo()
    local p = ID_SAMPLER_LFO
    local new_val = util.wrap(params:get(p) + 1, 1, #SLICE_START_LFO_SHAPES)
    params:set(p, new_val)
end

local function action_lfo(v)
    lfo_util.action_lfo(v, slice_lfo, SLICE_START_LFO_SHAPES, params:get(ID_SAMPLER_START))
end

local function e2(d)
    -- todo: can you make this a function of the lfo util?
    if slice_lfo:get("enabled") == 1 then
        lfo_util.adjust_lfo_rate_quant(d, slice_lfo)
    else
        adjust_slice_start(d)
    end
end


function page:render()
    if page_disabled then
        fileselect:redraw()
        return
    end -- for rendering the fileselect interface
    local lfo_val = SLICE_START_LFO_SHAPES[params:get(ID_SAMPLER_LFO)]
    for i = 1, 6 do
        env_polls[i]:update()
    end

    if selected_sample then
        -- show filename of selected sample in title bar
        self.window.title = filename
        self.graphic:render()

        page.footer.button_text.e2.value = params:get(ID_SAMPLER_START)
        page.footer.button_text.e3.value = params:get(ID_SAMPLER_NUM_SLICES)
        page.footer.button_text.k2.value = string.upper(lfo_val)

        if slice_lfo:get("enabled") == 1 then
            -- When LFO is disabled, E2 controls LFO rate
            page.footer.button_text.e2.name = "RATE"
            -- convert period to label representation
            local period = slice_lfo:get('period')
            page.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]
        else
            -- When LFO is disabled, E2 controls pan position
            -- page.footer.button_text.k2.value = "OFF"
            page.footer.button_text.e2.name = "START"
            -- page.footer.button_text.e2.value = misc_util.trim(tostring(), 5)
        end
    else
        screen.level(3)
        screen.font_face(DEFAULT_FONT)
        self.window.title = "SAMPLING"
        screen.move(64, 32)
        screen.text_center("PRESS K2 TO LOAD SAMPLE")
    end

    self.window:render()
    page.footer:render()
end

function page:add_params()
    -- file selection
    params:set_action(ID_SAMPLER_AUDIO_FILE,
        function(file)
            if file ~= "-" then
                filename = to_sample_name(file)
                self:load_sample(file)
            end
        end
    )

    -- number of slices
    params:set_action(ID_SAMPLER_NUM_SLICES, function(v) self:action_num_slices(v) end)

    -- starting slice
    params:set_action(ID_SAMPLER_START, function(v) self:action_slice_start(v) end)
    local num_slices = params:get(ID_SAMPLER_NUM_SLICES)
    constrain_max_start(num_slices)

    -- lfo
    params:set_action(ID_SAMPLER_LFO, action_lfo)
end

function page:set_sample_duration(v)
    print('Sample duration: ' .. v)
    self.sample_duration = v
    self:update_loop_ranges()
end

function page:initialize()
    self.graphic = SampleGraphic:new()
    self.e2 = e2
    self.e3 = adjust_num_slices
    self.k2_off = cycle_lfo
    self.k3_off = select_sample

    -- lfo
    slice_lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'clocked',
        period = 8,
        phase = 0,
        action = function(scaled, raw)
            params:set(ID_SAMPLER_START, controlspec_slice_start:map(scaled))
        end
    }
    slice_lfo:set('reset_target', 'mid: rising')

    self:add_params()

    if selected_sample then
        filename = to_sample_name(selected_sample)
        print("initialize, file load")
        if debug_mode then
            -- silent set, main module invokes params:bang() after initialization
            params:set(ID_SAMPLER_AUDIO_FILE, _path.dust .. selected_sample, true)
        end
    end

    self.window = Window:new({ title = "SAMPLING" })

    page.footer = Footer:new({
        button_text = {
            k2 = { name = "LFO", value = "" },
            k3 = { name = "LOAD", value = "" },
            e2 = { name = "START", value = "" },
            e3 = { name = "SLCS", value = "" },
        },
        font_face = FOOTER_FONT,
    })
end

function page:enable_env_polls()
    for i = 1, 6 do
        env_polls[i].callback = function(v) self.graphic.voice_env[i] = amp_to_log(v) end
    end
end

function page:disable_env_polls()
    for i = 1, 6 do
        env_polls[i].callback = nil
        self.graphic.voice_env[i] = 0
    end
end

function page:enter()
    self:enable_env_polls()
end

function page:exit()
    self:disable_env_polls()
end

return page
