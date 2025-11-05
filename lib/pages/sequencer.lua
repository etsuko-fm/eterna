local SequencerGraphic = include("symbiosis/lib/graphics/SequencerGraphic")
local Sequencer = include("symbiosis/lib/Sequencer")
local page_name = "SEQUENCER"
local PERLIN_ZOOM = 10 / 3 ---4 / 3 -- empirically tuned
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
    local density = params:get(ID_SEQ_PERLIN_DENSITY)
    local x_seed = params:get(ID_SEQ_PERLIN_X)
    local y_seed = params:get(ID_SEQ_PERLIN_Y)
    local z_seed = params:get(ID_SEQ_PERLIN_Z)

    local sequence = sequence_util.generate_perlin_seq(SEQ_ROWS, SEQ_COLUMNS, x_seed, y_seed, z_seed, density,
        PERLIN_ZOOM)
    for i, v in ipairs(sequence) do
        params:set(ID_SEQ_STEP[v.voice][v.step], v.value)
    end
end

local function e2(d)
    -- works for x, y, and z
    local p = ID_SEQ_PERLIN_X
    local new = params:get(p) + controlspec_perlin.quantum * d
    params:set(p, new, false)
end

local function e3(d)
    local new = params:get(ID_SEQ_PERLIN_DENSITY) + controlspec_perlin_density.quantum * d
    params:set(ID_SEQ_PERLIN_DENSITY, new, false)
end


local function update_slices()
    if UPDATE_SLICES then
        for voice = 1, 6 do
            local voice_loop_start = sym.get_id("voice_loop_start", voice)
            local voice_loop_end = sym.get_id("voice_loop_end", voice)
            params:set(voice_loop_start, params:get(ID_SLICES_SECTIONS[voice].loop_start))
            params:set(voice_loop_end, params:get(ID_SLICES_SECTIONS[voice].loop_end))
        end
        UPDATE_SLICES = false
    end
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
        local voice_env_level = sym.get_id("voice_env_level", y)
        local voice_lpg_freq = sym.get_id("voice_lpg_freq", y)
        local voice_attack = sym.get_id("voice_attack", y)
        local voice_decay = sym.get_id("voice_decay", y)
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
        sym.voice_trigger(y)
    end
end

function page:on_step(step)
    self.graphic.current_step = step
    page_control.current_step = step
    -- evaluate current step, send commands to supercollider accordingly
    for y = 1, SEQ_ROWS do
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
        update_slices()
        self.seq:advance()
        clock.sync(1 / self.seq.ticks_per_beat)
    end
end

function page:stop()
    clock.transport.stop()
    self.seq:reset()
    self.graphic.is_playing = false
end

function page:start()
    clock.transport.start()
    self.graphic.is_playing = true
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

function page:render()
    self.window:render()
    if redraw_sequence then
        -- condition prevents updating perlin values more often than the screen refreshes.
        generate_perlin_seq()
        redraw_sequence = false
    end

    for i = 1, 6 do
        env_polls[i]:update()
    end

    self.footer.button_text.k2.value = self.seq.transport_on and "ON" or "OFF"
    self.footer.button_text.k3.value = sequence_util.sequence_speeds[params:get(ID_SEQ_SPEED)]
    self.graphic.num_steps = self.seq.steps
    self.graphic:render()
    page.footer.button_text.e2.value = params:get(ID_SEQ_PERLIN_X)
    page.footer.button_text.e3.value = params:get(ID_SEQ_PERLIN_DENSITY)
    page.footer:render()
    grid_device:refresh()
end

function page:update_grid_step(x, y, v)
    self.graphic.sequences[y][x] = v
    if v > 0 then
        grid_device:led(x, y, 4 + math.floor(math.abs(v) * 8))
    else
        grid_device:led(x, y, 0)
    end
end

grid.key = function(x, y, z)
    -- if SEQUENCE_STYLE_TABLE[params:get(ID_SEQ_STYLE)] == SEQ_GRID then
    --     -- would sequence from grid
    -- end
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
    params:set_action(ID_SEQ_PERLIN_DENSITY, toggle_redraw)
    params:set_action(ID_SEQ_SPEED, function(v) self:action_sequence_speed(v) end)
    for y = 1, SEQ_ROWS do
        for x = 1, SEQ_COLUMNS do
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

    self.window = Window:new({ title = "SEQUENCER", font_face = TITLE_FONT })
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

    -- provide starting grid (may be empty depending on initial density param)
    generate_perlin_seq()
end

function page:enter()
    for i = 1, 6 do
        env_polls[i].callback = function(v) self.graphic.voice_env[i] = amp_to_log(v) end
    end
end


return page
