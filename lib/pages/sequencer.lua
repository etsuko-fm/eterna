local GridGraphic = include("symbiosis/lib/graphics/Grid")
local page_name = "SEQUENCER"
local window
local grid_graphic
local PERLIN_ZOOM = 10 / 3 ---4 / 3 -- empirically tuned
local MAX_STEPS = sequence_util.max_steps

-- todo: add in bits.lua? otherwise dependent on order of pages loaded

local main_seq_clock_id
local sequence_steps = SEQ_COLUMNS
local redraw_sequence = false

local page = Page:create({
    name = page_name,
    --
    hold = false,
    resume_from = nil,
    current_step = 1,
    current_substep = 1, -- holds values of 1 to MAX_STEPS, even if sequence length is shorter
    cue_step_divider = nil,
    step_divider = 1,
    transport_on = true,
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
    if self.cue_step_divider then
        -- wait until the current_substep aligns with the new step_size
        if self.current_substep % self.cue_step_divider == 0 then
            -- align the current global step with the new step divider, to prevent jumping
            self.current_substep = self.current_step * self.cue_step_divider
            self.step_divider = self.cue_step_divider
            self.cue_step_divider = nil
        end
    end
end

function page:set_current_step()
    -- hold step feature, UI available on seq-ctrl page
    if self.hold then
        if self.resume_from == nil then
            print("Frozen at " .. self.current_step)
            self.resume_from = self.current_step
        end
    else
        if self.resume_from then
            -- means step was held, but resumed this step
            -- current_substep ticked on meanwhile; but we don't want to jump to another step;
            -- should always go on neatly to the n+1 sequence step
            print("resumed at " .. self.current_substep)
            -- TODO: should be a function reset_substep?
            self.current_substep = self.current_step * self.step_divider + (self.current_step - self.resume_from)
            self.resume_from = nil
        end
        self.current_step = util.wrap(math.ceil(self.current_substep / self.step_divider), 1, sequence_steps)
    end
end

local function get_step_envelope(enable_mod, velocity)
    local max_time = params:get(ID_ENVELOPES_TIME)
    local max_shape = params:get(ID_ENVELOPES_SHAPE)
    return sequence_util.get_step_envelope(max_time, max_shape, enable_mod, velocity)
end


function page:evaluate_step(x, y)
    local sc_voice_id = y - 1 -- for 0-based supercollider arrays
    local enable_mod = ENVELOPE_MOD_OPTIONS[params:get(ID_ENVELOPES_MOD)]
    local velocity = params:get(ID_SEQ_STEP[y][x])
    local on = velocity > 0
    local attack, decay = get_step_envelope(enable_mod, velocity)
    if on then
        -- using modulo check to prevent triggering every 1/16 when step size is larger
        grid_graphic.current_step = self.current_step
        engine.env_level(sc_voice_id, velocity)
        if enable_mod == "LPG" then
            -- applies envelope to a lowpass filter
            engine.lpg_freq(sc_voice_id, misc_util.linexp(0, 1, 80, 20000, velocity, 1))
        end
        if enable_mod ~= "OFF" then
            engine.attack(sc_voice_id, attack)
            engine.decay(sc_voice_id, decay)
        end
        engine.trigger(sc_voice_id)
    end
end

function page:run_sequencer()
    -- runs every 1/16th note of current clock bpm (based on a 4/4 time signature); e.g. every 125ms for 120bpm
    while true do
        -- updates playback range of each sample prior to trigger
        update_slices()
        self:update_step_divider()
        self.current_substep = util.wrap(self.current_substep + 1, 1, MAX_STEPS)
        self:set_current_step()
        local x = self.current_step -- x pos of sequencer, i.e. current step

        -- true when switching from previous step to the current step
        local next = self.current_substep % self.step_divider == 0

        if next then
            grid_graphic.current_step = self.current_step
            for y = 1, SEQ_ROWS do
                self:evaluate_step(x, y)
            end
        end
        clock.sync(1 / 16) -- sync on 1/16th of a beat, so each 1/64th note
    end
end

function page:toggle_transport()
    if self.transport_on then
        clock.transport.stop()
        grid_graphic.is_playing = false
        self.current_substep = 1
        self.current_step = 1
    else
        clock.transport.start()
        grid_graphic.is_playing = true
    end
end

function page:toggle_hold_step()
    self.hold = not self.hold
end

function clock.transport.start()
    print("start transport")
    page.transport_on = true
    main_seq_clock_id = clock.run(function() page:run_sequencer() end)
end

function clock.transport.stop()
    print("stop transport")
    page.transport_on = false
    clock.cancel(main_seq_clock_id)
    current_step = 1
end

function page:render()
    window:render()
    if redraw_sequence then
        -- condition prevents updating perlin values more often than the screen refreshes.
        generate_perlin_seq()
        redraw_sequence = false
    end

    env1poll:update()
    env2poll:update()
    env3poll:update()
    env4poll:update()
    env5poll:update()
    env6poll:update()

    grid_graphic:render()

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

local function env_callback(voice, val)
    grid_graphic.voice_env[voice] = val
end

function page:initialize()
    page.e2 = e2
    page.e3 = e3
    -- allows value to be modified by other pages
    page.sequence_speed = sequence_util.convert_sequence_speed[sequence_util.default_speed_idx]
    add_params()

    env1poll.callback = function(v) env_callback(1, v) end
    env2poll.callback = function(v) env_callback(2, v) end
    env3poll.callback = function(v) env_callback(3, v) end
    env4poll.callback = function(v) env_callback(4, v) end
    env5poll.callback = function(v) env_callback(5, v) end
    env6poll.callback = function(v) env_callback(6, v) end

    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "SEQUENCER",
        font_face = TITLE_FONT,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    grid_graphic = GridGraphic:new()
    -- graphics
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "",
                value = "",
            },
            k3 = {
                name = "",
                value = "",
            },
            e2 = {
                name = "SEED",
                value = "",
            },
            e3 = {
                name = "DENS",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })

    -- start sequencer
    main_seq_clock_id = clock.run(function() page:run_sequencer() end)
    generate_perlin_seq()
end

return page
