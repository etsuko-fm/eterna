local SequencerGraphic = include(from_root("lib/graphics/SequencerGraphic"))
local Sequencer = include(from_root("lib/Sequencer"))
local page_name = "SEQUENCER"
local PERLIN_ZOOM = 3.3 -- empirically tuned; really low values (<1) make it more tetrisy
local main_seq_clock_id
local redraw_sequence = false
local TICKS_PER_BEAT = 8 -- quarter note divided by 8, so 1/32nd [call ticks_per_beat?]

local seq = Sequencer.new {
    steps = 16,
    rows = 6,
    ticks_per_beat = TICKS_PER_BEAT,
    ticks_per_step = 2,
}

local page = Page:create({
    name = page_name,
    --
    seq = seq,
})

local function generate_perlin_seq()
    local density = params:get(ID_SEQ_DENSITY)
    local x_seed = params:get(ID_SEQ_PERLIN_X)

    local sequence = sequence_util.read_perlin_seq(SEQ_TRACKS, SEQ_STEPS, x_seed, density)
    for i, v in ipairs(sequence) do
        params:set(ID_SEQ_STEP[v.voice][v.step], v.value)
    end
end

local function e2(d)
    misc_util.adjust_param(d, ID_SEQ_PERLIN_X, controlspec_perlin.quantum)
end

local function e3(d)
    misc_util.adjust_param(d, ID_SEQ_DENSITY, controlspec_perlin_density.quantum)
end

local function get_step_envelope(enable_mod, velocity)
    local max_time = params:get(ID_ENVELOPES_TIME)
    local max_shape = params:get(ID_ENVELOPES_SHAPE)
    -- return attack, decay
    return sequence_util.get_step_envelope(max_time, max_shape, enable_mod, velocity)
end

function page:evaluate_step(x, y)
    -- 0 <= x <= 15
    -- 1 <= y <= 6
    local enable_mod = ENVELOPE_MOD_OPTIONS[params:get(ID_ENVELOPES_MOD)]
    local velocity = params:get(ID_SEQ_STEP[y][x + 1]) -- using x+1 for 1-based table indexing
    local on = velocity > 0
    local attack, decay = get_step_envelope(enable_mod, velocity)
    if on then
        -- using modulo check to prevent triggering every 1/16 when step size is larger
        local voice_env_level = engine_lib.get_id("voice_env_level", y)
        local voice_lpg_freq = engine_lib.get_id("voice_lpg_freq", y)
        local voice_attack = engine_lib.get_id("voice_attack", y)
        local voice_decay = engine_lib.get_id("voice_decay", y)
        params:set(voice_env_level, velocity)
        if enable_mod == "LPG" then
            -- applies envelope to a lowpass filter
            params:set(voice_lpg_freq, misc_util.linexp(0, 1, 80, 20000, velocity, 1))
        end
        if enable_mod ~= "OFF" then
            -- if modulation enabled, update voice attack and decay according to step velocity
            params:set(voice_env_level, velocity)
            params:set(voice_attack, attack)
            params:set(voice_decay, decay)
        end
        engine_lib.voice_trigger(y)
    end
end

function page:on_step(step)
    self.graphic.current_step = step
    page_control.current_step = step
    -- evaluate current step, send commands to supercollider accordingly
    for y = 1, SEQ_TRACKS do
        self:evaluate_step(step, y)
    end
end

local function on_tick(tick, beat)
    page_control.current_beat = beat
end

local function adjust_step_size()
    local p = ID_SEQ_SPEED
    local v = params:get(p)
    local new = util.wrap(v + 1, 1, #sequence_util.sequence_speeds)
    params:set(p, new)
end

function page:run_sequencer()
    while true do
        -- updates playback range of each voice prior to trigger
        self.seq:advance()
        clock.sync(1 / self.seq.ticks_per_beat)
    end
end

function page:stop()
    clock.transport.stop()
    self.seq:reset()
    self.graphic.is_playing = false
    self:disable_env_polls()
end

function page:start()
    clock.transport.start()
    self.graphic.is_playing = true
    self:enable_env_polls()
end

function page:toggle_transport()
    if self.seq.transport_on then self:stop() else self:start() end
end

function clock.transport.start()
    page.seq.transport_on = true
    main_seq_clock_id = clock.run(function() page:run_sequencer() end)
end

function clock.transport.stop()
    page.seq.transport_on = false
    if main_seq_clock_id ~= nil then
        clock.cancel(main_seq_clock_id)
    end
end

function page:is_running()
    return self.seq.transport_on
end

function page:render()
    window:render()
    self:render_graphic()
    self:render_footer()
end

function page:render_graphic()
    if redraw_sequence then
        -- condition prevents updating perlin values more often than the screen refreshes.
        generate_perlin_seq()
        redraw_sequence = false
    end

    for i = 1, 6 do
        env_polls[i]:update()
    end

    self.graphic.num_steps = self.seq.steps
    self.graphic:render()
end


function page:render_footer()
    self.footer.button_text.k2.value = self.seq.transport_on and "ON" or "OFF"
    self.footer.button_text.k3.value = sequence_util.sequence_speeds[params:get(ID_SEQ_SPEED)]

    page.footer.button_text.e2.value = params:get(ID_SEQ_PERLIN_X)
    page.footer.button_text.e3.value = params:get(ID_SEQ_DENSITY)
    page.footer:render()
end


function page:update_grid_step(x, y, v)
    self.graphic.sequences[y][x] = v
end


local function toggle_redraw()
    redraw_sequence = true
end

function page:action_sequence_speed(v)
    -- convert table index of human-readable options to value for clock.sync
    -- calls global function defined on sequencer page
    local step_div = sequence_util.convert_sequence_speed[v]
    self.seq:set_ticks_per_step(step_div)
end

function page:add_params()
    params:set_action(ID_SEQ_PERLIN_X, toggle_redraw)
    params:set_action(ID_SEQ_PERLIN_Y, toggle_redraw)
    params:set_action(ID_SEQ_PERLIN_Z, toggle_redraw)

    -- TODO: if just density changes, shouldn't recalculate perlin noise
    params:set_action(ID_SEQ_DENSITY, toggle_redraw)
    params:set_action(ID_SEQ_SPEED, function(v) self:action_sequence_speed(v) end)
    for y = 1, SEQ_TRACKS do
        for x = 1, SEQ_STEPS do
            params:set_action(ID_SEQ_STEP[y][x], function(v) self:update_grid_step(x, y, v) end)
        end
    end
end

function page:initialize()
    page.k2_off = function() self:toggle_transport() end
    page.k3_off = adjust_step_size
    page.e2 = e2
    page.e3 = e3
    seq.on_step = function(step) page:on_step(step) end
    seq.on_tick = on_tick

    self:add_params()

    for i = 1, 6 do
        env_polls[i].callback = function(v) self.graphic.voice_env[i] = v end
    end

    self.graphic = SequencerGraphic:new()


    page.footer = Footer:new({
        button_text = {
            k2 = { name = "PLAY", value = "" },
            k3 = { name = "DIV", value = "" },
            e2 = { name = "SEED", value = "" },
            e3 = { name = "DENS", value = "" },
        },
        font_face = FOOTER_FONT,
    })
    -- resets sequencer and sets transport_on variable
    self:stop()

    -- provide starting grid (may be empty depending on default density param value)
    generate_perlin_seq()
end

function page:enable_env_polls()
    for i = 1, 6 do
        env_polls[i].callback = function(v) self.graphic.voice_env[i] = amp_to_log(v)
        end
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
    window.title = "SEQUENCER"
end

function page:exit()
    self:disable_env_polls()
end

return page
