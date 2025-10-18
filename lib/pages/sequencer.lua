local GridGraphic = include("symbiosis/lib/graphics/Grid")
local page_name = "SEQUENCER"
local window
local grid_graphic
local PERLIN_ZOOM = 10 / 3 ---4 / 3 -- empirically tuned
-- todo: add in bits.lua? otherwise dependent on order of pages loaded

local main_seq_clock_id
local redraw_sequence = false
local PLAY = "PLAY"
local STOP = "STOP"
local AWAIT_RESUME = "AWAIT_RESUME"
local HOLD = "HOLD"
local RESOLUTION = 16 -- 1/16th of a quarter note
-- todo: page creation could now actually be done from root module, to ensure all state params are available to all pages before page:init()
local page = Page:create({
    name = page_name,
    --
    playback = nil,          -- PLAY/STOP/AWAIT_RESUME/HOLD
    current_master_step = 0, -- always runs, even if playback == HOLD
    current_step = 0,        -- reflects actual step played back by sequencer
    current_substep = 0,     -- holds values of 1 to MAX_STEPS, even if sequence length is shorter
    cued_step_divider = nil,
    substeps_per_step = nil,   -- 4 1/64ths in a 1/16th note
    current_beat = 0,
    step_divider = 4,        -- TODO: Should be set by add_params action
    transport_on = true, -- TODO should be set by params
    sequence_steps = SEQ_COLUMNS,
    beat_div = RESOLUTION
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
        for voice = 0, 5 do
            engine.loop_start(voice, params:get(ID_SLICES_SECTIONS[voice + 1].loop_start))
            engine.loop_end(voice, params:get(ID_SLICES_SECTIONS[voice + 1].loop_end))
        end
        UPDATE_SLICES = false
    end
end

function page:update_step_divider()
    if self.cued_step_divider then
        -- wait until the current_substep aligns with the new step_size
        if self.current_substep % self.cued_step_divider == 0 then
            -- align the current global step with the new step divider, to prevent jumping
            self.current_substep = self.current_step * self.cued_step_divider
            self.step_divider = self.cued_step_divider
            self.cued_step_divider = nil
        end
    end
end

local function get_step_envelope(enable_mod, velocity)
    local max_time = params:get(ID_ENVELOPES_TIME)
    local max_shape = params:get(ID_ENVELOPES_SHAPE)
    -- return attack, decay
    return sequence_util.get_step_envelope(max_time, max_shape, enable_mod, velocity)
end


function page:evaluate_step(x, y)
    local sc_voice_id = y - 1                        -- for 0-based supercollider arrays
    local enable_mod = ENVELOPE_MOD_OPTIONS[params:get(ID_ENVELOPES_MOD)]
    local velocity = params:get(ID_SEQ_STEP[y][x + 1]) -- using x+1 for 1-based table indexing
    local on = velocity > 0
    local attack, decay = get_step_envelope(enable_mod, velocity)
    if on then
        -- using modulo check to prevent triggering every 1/16 when step size is larger
        grid_graphic.current_step = self.current_step
        engine.env_level(sc_voice_id, velocity)
        if enable_mod == "LPG" then
            -- applies envelope to a lowpass filter
            engine.lpg_freq(sc_voice_id, misc_util.linexp(0, 1, 80, 20000, velocity, 1))
        elseif enable_mod ~= "OFF" then
            engine.attack(sc_voice_id, attack)
            engine.decay(sc_voice_id, decay)
        end
        engine.trigger(sc_voice_id)
    end
end

function page:reset_counter()
    self.current_master_step = 0
    self.current_step = 0
end

function page:run_sequencer()
    while true do
        local beat_div = self.beat_div
        -- updates playback range of each voice prior to trigger
        update_slices()
        -- self:update_step_divider()

        if self.cued_step_divider then
            -- execute on first beat
            if self.current_substep == 0 then
                print("step div change executed: from " .. self.step_divider .. " to " .. self.cued_step_divider .. " on master step " .. self.current_master_step)
                self.step_divider = self.cued_step_divider
                self.cued_step_divider = nil
                self.substeps_per_step = self.step_divider
                self:reset_counter()
                print("new substeps per step: "..self.substeps_per_step)
            end
        end

        -- substep can always go on in a 1/64th speed with no recalcaultions upon step division change
        self.current_substep = (self.current_substep + 1) % (self.beat_div * 4) -- keep track of upto 4 quarter notes
        self.current_beat = math.floor(self.current_substep / self.beat_div)

        if self.current_substep % self.step_divider == 0 then
            -- master step is updated regardless of playback state
            self.current_master_step = (self.current_master_step + 1) % beat_div
            -- next step in sequence should be triggered
            if self.playback == HOLD then
                -- ?
            elseif self.playback == AWAIT_RESUME then
                print('waiting correct step to resume')
                -- wait until current step is equal to the master step
                if self.current_master_step == self.current_step then
                    -- on next iteration, playback will be picked up again
                    self.playback = PLAY
                end
            else
                self.current_step = (self.current_step + 1) % self.sequence_steps
                grid_graphic.current_step = self.current_step
            end
            for y = 1, SEQ_ROWS do
                self:evaluate_step(self.current_step, y)
            end
        end
        clock.sync(1 / beat_div) -- sync on 1/16th of a beat, so each 1/64th note
    end
end

function page:toggle_transport()
    if self.transport_on then
        clock.transport.stop()
        self.playback = STOP
        self.current_substep = 0
        self.current_step = 0
        self.current_beat = 0
        grid_graphic.is_playing = false
    else
        clock.transport.start()
        self.playback = PLAY
        grid_graphic.is_playing = true
    end
end

function page:toggle_hold_step()
    if self.playback ~= HOLD then
        self.playback = HOLD
    else
        -- wait with resuming until the sequencer is at the current step again
        if page.transport_on then
            self.playback = AWAIT_RESUME
        else
            self.playback = STOP
        end
    end
end

function clock.transport.start()
    print("start transport")
    page.transport_on = true
    main_seq_clock_id = clock.run(function() page:run_sequencer() end)
    if page.playback == STOP then
        page.playback = PLAY
    end
end

function clock.transport.stop()
    print("stop transport")
    page.transport_on = false
    clock.cancel(main_seq_clock_id)
    if page.playback == PLAY then
        page.playback = STOP
    end

    current_step = 1
end

function page:render()
    window:render()
    if redraw_sequence then
        -- condition prevents updating perlin values more often than the screen refreshes.
        generate_perlin_seq()
        redraw_sequence = false
    end

    for i = 1, 6 do
        env_polls[i]:update()
    end

    grid_graphic:render()
    screen.level(15)
    screen.move(16, 32)
    screen.text_center(self.current_substep)

    page.footer.button_text.e2.value = params:get(ID_SEQ_PERLIN_X)
    page.footer.button_text.e3.value = params:get(ID_SEQ_PERLIN_DENSITY)
    page.footer:render()
    grid_device:refresh()
end

local function update_grid_step(x, y, v)
    grid_graphic.sequences[y][x] = v
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

local function add_params()
    params:set_action(ID_SEQ_PERLIN_X, toggle_redraw)
    params:set_action(ID_SEQ_PERLIN_Y, toggle_redraw)
    params:set_action(ID_SEQ_PERLIN_Z, toggle_redraw)
    params:set_action(ID_SEQ_PERLIN_DENSITY, toggle_redraw)
    for y = 1, SEQ_ROWS do
        for x = 1, SEQ_COLUMNS do
            params:set_action(ID_SEQ_STEP[y][x], function(v) update_grid_step(x, y, v) end)
        end
    end
end

function page:initialize()
    page.e2 = e2
    page.e3 = e3
    -- allows value to be modified by other pages
    page.sequence_speed = sequence_util.convert_sequence_speed[sequence_util.default_speed_idx]
    add_params()
    self.substeps_per_step = self.beat_div / self.step_divider

    for i = 1, 6 do
        env_polls[i].callback = function(v) grid_graphic.voice_env[i] = v end
    end

    window = Window:new({ title = "SEQUENCER", font_face = TITLE_FONT })
    grid_graphic = GridGraphic:new()
    -- graphics
    page.footer = Footer:new({
        button_text = {
            k2 = { name = "", value = "" },
            k3 = { name = "", value = "" },
            e2 = { name = "SEED", value = "" },
            e3 = { name = "DENS", value = "" },
        },
        font_face = FOOTER_FONT,
    })

    -- start sequencer
    main_seq_clock_id = clock.run(function() page:run_sequencer() end)
    generate_perlin_seq()
end

return page
