local GridGraphic = include("symbiosis/lib/graphics/Grid")
local perlin = include("symbiosis/lib/ext/perlin")
local page_name = "SEQUENCER"
local window
local grid_graphic
local PERLIN_ZOOM = 10/3                          ---4 / 3 -- empirically tuned
local SEQ_EVOLVE_RATES = { 2 ^ 15, 2 ^ 14, 2 ^ 13 } -- in quarter notes, but fuzzy concept due to how perlin computes
local SEQUENCE_STYLE_TABLE_TO_SOFTCUT = { 1, 0 }
local MAX_STEPS = sequence_util.max_steps

local transport_on = true
local holding_step = false

-- todo: add in bits.lua? otherwise dependent on order of pages loaded

local main_seq_clock_id
local current_step = 1
local current_global_step = 1 -- holds values of 1 to MAX_STEPS, even if sequence length is shorter
local sequence_steps = SEQ_COLUMNS
local step_divider = 1 -- 1 means 1 step = 1 1/16th note
local cue_step_divider = nil
local perlin_lfo
local redraw_sequence = false

local function generate_perlin_seq()
    local velocities = {}

    local density = params:get(ID_SEQ_PERLIN_DENSITY)
    local x_seed = params:get(ID_SEQ_PERLIN_X)
    local y_seed = params:get(ID_SEQ_PERLIN_Y)
    local z_seed = params:get(ID_SEQ_PERLIN_Z)

    for voice = 1, SEQ_ROWS do
        local perlin_y = voice * PERLIN_ZOOM + y_seed
        for step = 1, SEQ_COLUMNS do
            local perlin_x = step * PERLIN_ZOOM + x_seed
            local pnoise = perlin:noise(perlin_x, perlin_y, z_seed)
            local velocity = util.linlin(-1, 1, 0, 1, pnoise)
            table.insert(velocities, {value=velocity, voice=voice, step=step})
            params:set(ID_SEQ_STEP[voice][step], velocity)
        end
    end

    table.sort(velocities, function(a, b) return a.value > b.value end)
    local keep_count = math.floor(density * #velocities)
    for i, v in ipairs(velocities) do
        local keep = i <= keep_count
        params:set(ID_SEQ_STEP[v.voice][v.step], keep and v.value or 0)
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

local page = Page:create({
    name = page_name,
    e2 = e2,
    e3 = e3,
    k2_off = nil,
    k3_off = nil,
})

function set_cue_step_divider(v)
    -- cue up a change in sequence step length
    cue_step_divider = v
end

function get_cue_step_divider()
    return cue_step_divider
end

function voice_position_to_start(voice)
    if params:get(get_voice_dir_param_id(voice)) == 1 then
        -- play forward
        -- query position
        engine.position(voice, params:get(get_slice_start_param_id(voice)))
    else
        -- play reverse, start at end
        engine.position(voice, params:get(get_slice_end_param_id(voice)))
    end
end

function voice_position_to_phase(voice, phase)
    -- get slice length
    local slice_start = params:get(get_slice_start_param_id(voice))
    local slice_end = params:get(get_slice_end_param_id(voice))
    local slice_length = slice_end - slice_start

    -- move softcut position to provided phase
    local rel_pos = phase * slice_length
    local abs_pos = slice_start + rel_pos
    engine.position(voice, abs_pos)
end

local hold_step = nil

local function update_slices()
    if UPDATE_SLICES then
        for voice = 0, 5 do
            engine.loop_start(voice, params:get(ID_SLICES_SECTIONS[voice + 1].loop_start))
            engine.loop_end(voice, params:get(ID_SLICES_SECTIONS[voice + 1].loop_end))
        end
        UPDATE_SLICES = false
    end
end

local function update_step_divider()
    if cue_step_divider then
        -- wait until the current_global_step aligns with the new step_size
        if current_global_step % cue_step_divider == 0 then
            -- align the current global step with the new step divider, to prevent jumping
            current_global_step = current_step * cue_step_divider
            step_divider = cue_step_divider
            cue_step_divider = nil
        end
    end
end

local function set_current_step()
    -- hold step feature, UI available on seq-ctrl page
    if not holding_step then
        if hold_step then
            -- means step was held, but resumed this step
            -- current_global_step ticked on meanwhile; but we don't want to jump to another step;
            -- shold always go on neatly to the n+1 sequence step
            print("resumed at " .. current_global_step)
            current_global_step = current_step * step_divider + (current_step - hold_step)
            hold_step = nil
        end
        current_step = util.wrap(math.ceil(current_global_step / step_divider), 1, sequence_steps)
    else
        if hold_step == nil then
            print("Frozen at " .. current_step)
            hold_step = current_step
        end
    end
end

local function calculate_envelope(enable_mod, step_val)
        local max_time = params:get(ID_ENVELOPES_TIME)
    local max_shape = params:get(ID_ENVELOPES_SHAPE)

    local mod_amt
    if enable_mod ~= "OFF" then
        -- use half of sequencer val for modulation
        mod_amt = 0.5 + step_val / 2
    else
        mod_amt = 1
    end

    -- modulate time and shape
    local time = max_time * mod_amt
    local shape = max_shape * mod_amt
    local attack = get_attack(time, shape)
    local decay = get_decay(time, shape)

    return attack, decay
end


local function evaluate_step(x, y, is_step_change)
    local voice = y - 1 -- for 0-based supercollider arrays
    local enable_mod = ENVELOPE_MOD_OPTIONS[params:get(ID_ENVELOPES_MOD)]
    local perlin_val = params:get(ID_SEQ_STEP[y][x])
    local a = math.abs(perlin_val)
    local on = a > 0.0
    local attack, decay = calculate_envelope(enable_mod, a)
    if on then
        -- using modulo check to prevent triggering every 1/16 when step size is larger
        if is_step_change then
            grid_graphic.current_step = current_step
            engine.env_level(voice, a)
            engine.trigger(voice)
            if enable_mod == "LPG" then
                -- applies envelope to a lowpass filter
                engine.lpg_freq(voice, misc_util.linexp(0, 1, 80, 20000, a, 1))
            end
            if enable_mod ~= "OFF" then
                engine.attack(voice, attack)
                engine.decay(voice, decay)
            end
        end
    end
end

local function run_sequencer()
    -- runs every 1/16th note of current clock bpm (based on a 4/4 time signature); e.g. every 125ms for 120bpm
    while true do
        update_slices()
        update_step_divider()
        current_global_step = util.wrap(current_global_step + 1, 1, MAX_STEPS)
        set_current_step()
        -- grid_graphic.current_step = current_step
        local x = current_step -- x pos of sequencer, i.e. current step

        -- true when switching from previous step to the current step
        local is_step_change = current_global_step % step_divider == 0

        if is_step_change then
            grid_graphic.current_step = current_step
        end

        for y = 1, SEQ_ROWS do
            evaluate_step(x, y, is_step_change)
        end
        clock.sync(1 / 4)
    end
end

function toggle_transport()
    if transport_on then
        clock.transport.stop()
        grid_graphic.is_playing = false
        current_global_step = 1
        current_step = 1
    else
        clock.transport.start()
        grid_graphic.is_playing = true
    end
end

function report_transport()
    return transport_on
end

function report_hold()
    return holding_step
end

function report_current_global_step()
    return current_global_step
end

function report_current_step()
    return current_step
end

function toggle_hold_step()
    if holding_step then
        holding_step = false
        print('releasing')
    else
        holding_step = true
        print('holding')
    end
end

function clock.transport.start()
    print("start transport")
    transport_on = true
    main_seq_clock_id = clock.run(run_sequencer)
end

function clock.transport.stop()
    print("stop transport")
    transport_on = false
    clock.cancel(main_seq_clock_id)
    for voice = 1, 6 do
        -- stop softcut voices
        softcut.play(voice, 0)
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
    main_seq_clock_id = clock.run(run_sequencer)
    -- for softcut updates
    -- softcut.event_position(report_softcut)

    perlin_lfo = _lfos:add {
        shape = 'tri',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'clocked',
        period = SEQ_EVOLVE_RATES[1],
        phase = 0,
        action = function(scaled, raw)
            params:set(ID_SEQ_PERLIN_Y, controlspec_perlin:map(scaled))
        end
    }
    perlin_lfo:set('reset_target', 'mid: rising')
    generate_perlin_seq()
end

return page
