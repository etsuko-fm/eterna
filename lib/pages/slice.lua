local SampleGraphic = include(from_root("lib/graphics/SampleGraphic"))

local page_name = "SLICE"

local slice_lfo

local page = Page:create({
    name = page_name,
    --
    sample_duration = nil,
})

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
    local start = params:get(ID_SAMPLER_SLICE_START)

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

function page:adjust_num_slices(d)
    if params:get(ID_SAMPLER_AUDIO_FILE) then
        misc_util.adjust_param(d, ID_SAMPLER_NUM_SLICES, controlspec_num_slices.quantum)
    end
end

function page:adjust_slice_start(d)
    if params:get(ID_SAMPLER_AUDIO_FILE) then
        local p = ID_SAMPLER_SLICE_START
        local max_slices = params:get(ID_SAMPLER_NUM_SLICES)
        local new = util.wrap(params:get(p) + d, 1, max_slices)
        params:set(p, new)
    end
end

local function cycle_lfo_shape()
    misc_util.cycle_param(ID_SLICE_LFO_SHAPE, SLICE_START_LFO_SHAPES)
end

local function action_lfo_shape(v)
    lfo_util.action_lfo_shape(v, slice_lfo, SLICE_START_LFO_SHAPES, params:get(ID_SAMPLER_SLICE_START))
end
local function toggle_lfo()
    misc_util.toggle_param(ID_SLICE_LFO_ENABLED)
end
local function action_lfo_toggle(v)
    lfo_util.action_lfo_toggle(v, slice_lfo, params:get(ID_SAMPLER_SLICE_START))
end

local function e2(d)
    -- todo: can you make this a function of the lfo util?
    if slice_lfo:get("enabled") == 1 then
        lfo_util.adjust_lfo_rate(d, slice_lfo)
    else
        page:adjust_slice_start(d)
    end
end


function page:render()
    local lfo_enabled = params:get(ID_SLICE_LFO_ENABLED)
    local lfo_shape = SLICE_START_LFO_SHAPES[params:get(ID_SLICE_LFO_SHAPE)]
    for i = 1, 6 do
        env_polls[i]:update()
    end

    if params:get(ID_SAMPLER_AUDIO_FILE) ~= "-" then
        self.graphic:render(true)

        page.footer.button_text.e2.value = params:get(ID_SAMPLER_SLICE_START)
        page.footer.button_text.e3.value = params:get(ID_SAMPLER_NUM_SLICES)
        page.footer.button_text.k2.value = lfo_enabled == 1 and "ON" or "OFF"
        page.footer.button_text.k3.value = string.upper(lfo_shape)

        if lfo_enabled == 1 then
            -- When LFO is disabled, E2 controls LFO rate
            page.footer.button_text.e2.name = "RATE"
            -- convert period to label representation
            local period = slice_lfo:get('period')
            page.footer.button_text.e2.value = lfo_util.lfo_period_value_labels[period]
        else
            page.footer.button_text.e2.name = "START"
        end
    else
        screen.level(3)
        screen.font_face(DEFAULT_FONT)
        screen.move(64, 32)
    end

    window:render()
    page.footer:render()
end

function page:add_params()
    -- number of slices
    params:set_action(ID_SAMPLER_NUM_SLICES, function(v) self:action_num_slices(v) end)

    -- starting slice
    params:set_action(ID_SAMPLER_SLICE_START, function(v) self:action_slice_start(v) end)
    local num_slices = params:get(ID_SAMPLER_NUM_SLICES)
    constrain_max_start(num_slices)

    -- lfo
    params:set_action(ID_SLICE_LFO_SHAPE, action_lfo_shape)
    params:set_action(ID_SLICE_LFO_ENABLED, action_lfo_toggle)
end

function page:set_sample_duration(v)
    print('Sample duration: ' .. v)
    self.sample_duration = v
    self:update_loop_ranges()
end

function page:initialize()
    self.graphic = SampleGraphic:new()
    self.e2 = e2
    self.e3 = function(v) page:adjust_num_slices(v) end
    self.k2_off = toggle_lfo
    self.k3_off = cycle_lfo_shape

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
            params:set(ID_SAMPLER_SLICE_START, controlspec_slice_start:map(scaled))
        end
    }
    slice_lfo:set('reset_target', 'mid: rising')

    self:add_params()


    page.footer = Footer:new({
        button_text = {
            k2 = { name = "LFO", value = "" },
            k3 = { name = "WAVE", value = "" },
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
    window.title = "SLICES"
end

function page:exit()
    self:disable_env_polls()
end

return page
