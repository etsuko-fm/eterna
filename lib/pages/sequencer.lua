local SequencerGraphic = include(from_root("lib/graphics/SequencerGraphic"))
local Sequencer = include(from_root("lib/Sequencer"))
local page_name = "SEQUENCER"
local PERLIN_ZOOM = 3.3 -- empirically tuned; really low values (<1) make it more tetrisy
local main_seq_clock_id
local redraw_perlin = false
local redraw_grid_velocity = false
local TICKS_PER_BEAT = 8 -- quarter note divided by 8, so 1/32nd [call ticks_per_beat?]

local seq = Sequencer.new {
    steps = NUM_STEPS,
    rows = NUM_TRACKS,
    ticks_per_beat = TICKS_PER_BEAT,
    ticks_per_step = 2,
}

local page = Page:create({
    name = page_name,
    --
    seq = seq,
})

local RANDOM_SEED = 383762
local pending_sequence = false

local function generate_perlin()
    -- updates sequence step params based on current perlin noise config
    local density = params:get(ID_SEQ_DENSITY)
    local x_seed = params:get(ID_SEQ_PERLIN_X)
    local y_seed = params:get(ID_SEQ_PERLIN_Y)
    local z_seed = params:get(ID_SEQ_PERLIN_Z)

    local sequence = sequence_util.generate_perlin(NUM_TRACKS, NUM_STEPS, x_seed, y_seed, z_seed, density,
        PERLIN_ZOOM)
    for i, v in ipairs(sequence) do
        params:set(STEPS[v.voice][v.step], v.value)
    end
end

function page:display_active_sequence()
    -- triggering their action updates grid and sequence graphic
    for track = 1, NUM_TRACKS do
        for step = 1, NUM_STEPS do
            params:lookup_param(STEPS[track][step]):bang()
        end
    end
end

local function e2(d)
    local source = params:string(ID_SEQ_SOURCE)
    if source == SOURCE_PERLIN then
        misc_util.adjust_param(d, ID_SEQ_PERLIN_X, controlspec_perlin.quantum)
        pending_sequence = false
    elseif source == SOURCE_GRID then
        misc_util.adjust_param(d, ID_SEQ_VEL_CENTER, controlspec_vel_center.quantum)
    end
end

local function e3(d)
    local source = params:string(ID_SEQ_SOURCE)
    if source == SOURCE_PERLIN then
        misc_util.adjust_param(d, ID_SEQ_DENSITY, controlspec_perlin_density.quantum)
        pending_sequence = false
    elseif source == SOURCE_GRID then
        misc_util.adjust_param(d, ID_SEQ_VEL_SPREAD, controlspec_vel_spread.quantum)
    end
end

local function get_step_envelope(enable_mod, velocity)
    local max_time = params:get(ID_ENVELOPES_TIME)
    local max_shape = params:get(ID_ENVELOPES_SHAPE)
    -- return attack, decay
    return sequence_util.get_step_envelope(max_time, max_shape, enable_mod, velocity)
end

function page:generate_random_velocity(x, y, center, spread)
    -- Calculate the range based on center and spread
    local half_range = spread / 2
    local min_val = center - half_range
    local max_val = center + half_range

    -- Generate random value in range around center
    local velocity = min_val + math.random() * (max_val - min_val)

    -- Clamp to [0.01, 1] range; so that all active steps will remain active
    velocity = util.clamp(velocity, 0.01, 1)
    -- only update steps that are already active
    return velocity
end

local seeds = {}

for i = 1, NUM_STEPS do
    -- TODO: make param
    seeds[i] = RANDOM_SEED + i
end

local function generate_random_velocities(center, spread)
    for x = 1, NUM_STEPS do
        math.randomseed(seeds[x])
        for y = 1, NUM_TRACKS do
            local velocity = page:generate_random_velocity(x, y, center, spread)
            if params:get(STEPS[y][x]) ~= 0 then
                -- set the value; this will trigger an action that updates grid/norns display
                params:set(STEPS[y][x], velocity)
            end
        end
    end
end

function page:evaluate_step(x, y)
    -- 0 <= x <= 15
    -- 1 <= y <= 6
    local enable_mod = params:string(ID_ENVELOPES_MOD)
    local source = params:string(ID_SEQ_SOURCE)
    local velocity = params:get(STEPS[y][x + 1]) -- using x+1 for 1-based table indexing
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

        -- generate new velocity for step after evaluating
        if source == SOURCE_GRID then
            -- TODO step should really be either 0 or 1 based everywhere
            local center = params:get(ID_SEQ_VEL_CENTER)
            local spread = params:get(ID_SEQ_VEL_SPREAD)
            local velocity = self:generate_random_velocity(x + 1, y, center, spread)
            params:set(STEPS[y][x + 1], velocity)
        end
    end
end

function page:on_step(step)
    self.graphic:set("current_step", step)
    grid_conn:set_current_step(step)
    page_control.current_step = step
    -- evaluate current step, send commands to supercollider accordingly
    for track = 1, NUM_TRACKS do
        self:evaluate_step(step, track)
    end
end

local function cycle_source(v)
    if grid_conn.active then
        misc_util.cycle_param(ID_SEQ_SOURCE, SEQUENCER_SOURCES, 1)
    end
end

function page:run_sequencer()
    while true do
        -- updates playback range of each voice prior to trigger
        self.seq:advance()
        clock.sync(1 / self.seq.ticks_per_beat)
    end
end

function page:toggle_transport()
    if self.seq.transport_on then
        clock.transport.stop()
    else
        clock.transport.start()
    end
end

function clock.transport.start()
    if not page.seq.transport_on then
        page.seq.transport_on = true
        main_seq_clock_id = clock.run(function() page:run_sequencer() end)
        page.graphic:set("is_playing", true)
        grid_conn:set_transport(true)
        if page.active then page:enable_env_polls() end
    end
end

function clock.transport.stop()
    if page.seq.transport_on then
        page.seq.transport_on = false
        if main_seq_clock_id ~= nil then
            clock.cancel(main_seq_clock_id)
            page.seq:reset()
            page.graphic:set("is_playing", false)
            grid_conn:set_transport(false)
            -- todo: with midi it's possible to start/stop while on any page;
            -- in such case the env polls of the correct page should be disabled.
            -- possible solution is to move clock.transport definitions to eterna.lua,
            -- and implement controlling behaviour from there.
            -- for now, the page.active check below works, but if clock.transport.start is called while
            -- on the slices or playback rate page, env continues to be polled
            if page.active then page:disable_env_polls() end
        end
    end
end

function page:is_running()
    return self.seq.transport_on
end

function page:update_graphics_state()
    self.graphic:set("num_steps", self.seq.steps)
    local source = params:string(ID_SEQ_SOURCE)
    self.footer:set_value('k2', self.seq.transport_on and "ON" or "OFF")
    self.footer:set_value("k3", source)
    if source == SOURCE_PERLIN then
        self.footer:set_name('e2', "SEED")
        self.footer:set_name('e3', "DENS")
        local perlin_txt = params:get(ID_SEQ_PERLIN_X)
        local density_txt = params:get(ID_SEQ_DENSITY)
        if pending_sequence then
            perlin_txt = "*"
            density_txt = "*"
        end
        self.footer:set_value('e2', perlin_txt)
        self.footer:set_value('e3', density_txt)
    elseif source == SOURCE_GRID then
        self.footer:set_name('e2', "V CNTR")
        self.footer:set_name('e3', "V SPRD")
        self.footer:set_value('e2', params:get(ID_SEQ_VEL_CENTER))
        self.footer:set_value('e3', params:get(ID_SEQ_VEL_SPREAD))
    end

    -- prevent updating velocities more often than the screen refreshes, as it costs quite some cpu
    -- when done on every encoder-change.
    if redraw_perlin and source == SOURCE_PERLIN then
        redraw_perlin = false
        generate_perlin()
    elseif redraw_grid_velocity and source == SOURCE_GRID then
        redraw_grid_velocity = false
        generate_random_velocities(params:get(ID_SEQ_VEL_CENTER), params:get(ID_SEQ_VEL_SPREAD))
    end

    for i = 1, 6 do
        env_polls[i]:update()
    end
end

function page:update_cell(step, voice, v)
    self.graphic:set_cell(voice, step, v)
    if grid_conn.active then
        grid_conn:set_cell(step, voice, v * 15)
    end
end

function page:toggle_redraw_perlin()
    redraw_perlin = true
end

function toggle_redraw_grid_velocity()
    redraw_grid_velocity = true
end

function page:action_sequence_speed(v)
    -- convert table index of human-readable options to value for clock.sync
    -- calls global function defined on sequencer page
    local step_div = sequence_util.convert_sequence_speed[v]
    self.seq:set_ticks_per_step(step_div)
end

local function action_step_edit(self, x, y)
    -- retruns a closure so the x/y params can be injected
    return function(v)
        self:update_cell(x, y, v)
    end
end

local function action_source(src)
    -- copy perlin noise sequence to grid sequence
    if params:string(ID_SEQ_SOURCE) == SOURCE_PERLIN then
        -- don't switch to perlin yet, use this var to show asterisk *
        -- TOOD: should not trigger on startup
        pending_sequence = true
    end
end

function page:add_params()
    params:set_action(ID_SEQ_PERLIN_X, function(v) self:toggle_redraw_perlin() end)
    params:set_action(ID_SEQ_PERLIN_Y, function(v) self:toggle_redraw_perlin() end)
    params:set_action(ID_SEQ_PERLIN_Z, function(v) self:toggle_redraw_perlin() end)
    params:set_action(ID_SEQ_VEL_CENTER, toggle_redraw_grid_velocity)
    params:set_action(ID_SEQ_VEL_SPREAD, toggle_redraw_grid_velocity)
    params:set_action(ID_SEQ_DENSITY, function(v) self:toggle_redraw_perlin() end)
    params:set_action(ID_SEQ_SPEED, function(v) self:action_sequence_speed(v) end)
    params:set_action(ID_SEQ_SOURCE, action_source)

    for y = 1, NUM_TRACKS do
        for x = 1, NUM_STEPS do
            params:set_action(STEPS[y][x], action_step_edit(self, x, y))
        end
    end
end

function page:initialize()
    page.k2_off = function() self:toggle_transport() end
    page.k3_off = cycle_source
    page.e2 = e2
    page.e3 = e3
    seq.on_step = function(step) page:on_step(step) end

    self:add_params()

    for i = 1, 6 do
        env_polls[i].callback = function(v) self.graphic:set_table("voice_env", i, v) end
    end

    self.graphic = SequencerGraphic:new()
    self:display_active_sequence()


    page.footer = Footer:new({
        button_text = {
            k2 = { name = "PLAY", value = "" },
            k3 = { name = "MODE", value = "" },
            e2 = { name = "SEED", value = "" },
            e3 = { name = "DENS", value = "" },
        },
        font_face = FOOTER_FONT,
    })
    -- resets sequencer and sets transport_on variable
    clock.transport.stop()

    -- provide starting grid (may be empty depending on default density param value)
    generate_perlin()
end

function page:enable_env_polls()
    for i = 1, 6 do
        env_polls[i].callback = function(v)
            self.graphic:set_table("voice_env", i, amp_to_log(v))
        end
    end
end

function page:disable_env_polls()
    for i = 1, 6 do
        env_polls[i].callback = nil
        self.graphic:set_table("voice_env", 0) -- todo: think not needed anymore
    end
end

function page:enter()
    self:enable_env_polls()
    header.title = "SEQUENCER"
    self.active = true
end

function page:exit()
    self:disable_env_polls()
    self.active = false
end

return page
