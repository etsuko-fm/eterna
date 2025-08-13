local GridGraphic = include("bits/lib/graphics/Grid")
local perlin = include("bits/lib/ext/perlin")
local page_name = "SEQUENCER"
local window
local grid_graphic
local PERLIN_ZOOM = 5/3 ---4 / 3 -- empirically tuned
local SEQ_EVOLVE_RATES = {2^15, 2^14, 2^13} -- in quarter notes, but fuzzy concept due to how perlin computes
local SEQUENCE_STYLE_TABLE_TO_SOFTCUT = {1, 0}
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

local voice_pos = {} -- playhead positions of softcut voices
voice_pos_percentage = {}
local perlin_lfo
local redraw_sequence = false

local function generate_perlin_seq()
    -- print("regen - ", math.random())
    -- need as many values as there are rows and columns
    local density = params:get(ID_SEQ_PERLIN_DENSITY)
    local x_seed = params:get(ID_SEQ_PERLIN_X)
    local y_seed = params:get(ID_SEQ_PERLIN_Y)
    local z_seed = params:get(ID_SEQ_PERLIN_Z)

    for voice = 1, SEQ_ROWS do
        for step = 1, SEQ_COLUMNS do
            local perlin_x = step * PERLIN_ZOOM + x_seed
            local perlin_y = voice * PERLIN_ZOOM + y_seed
            local pnoise = perlin:noise(perlin_x, perlin_y, z_seed)
            local v = util.clamp(util.linlin(-1, 1, -0.3, 1.3, pnoise), 0.01, 1)

            if density == 0 then v = 0
            else
                -- base density map on a different seed of x/y/z, so that
                -- not only low or high values are filtered out
                local density_seed = 11.0
                -- map to larger range than [0:1], then clamp, because perlin noise leans to the center of the range
                local mask = util.clamp(util.linlin(-1,1,-0.3,1.3, perlin:noise(perlin_x + density_seed, perlin_y + density_seed, z_seed)), 0, 1)
                if mask >= density and (mask ~= 1.0 and density ~= 1.0) then
                    v = 0.0 -- 0.0 is only value not interpreted as an active step    
                end
            end
            params:set(ID_SEQ_STEP[voice][step], v)
        end
    end
end

-- local min_val = math.huge
-- local max_val = -math.huge
-- for x = 0, 1000, 0.01 do
--     local n = perlin:noise(x, math.random()*10, math.random()*10)
--     if n < min_val then min_val = n end
--     if n > max_val then max_val = n end
-- end
-- print("Min:", min_val, "Max:", max_val)

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

local function toggle_evolve()
    local p = ID_SEQ_EVOLVE
    local new = util.wrap(params:get(p) + 1, 1, #SEQ_EVOLVE_TABLE)
    params:set(p, new)
end

local function toggle_playback_style()
    local p = ID_SEQ_STYLE
    local new = util.wrap(params:get(p) + 1, 1, #SEQUENCE_STYLE_TABLE)
    params:set(p, new)
end

local page = Page:create({
    name = page_name,
    e2 = e2,
    e3 = e3,
    k2_off = toggle_evolve,
    k3_off = toggle_playback_style,
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
local function main_sequencer_callback()
    -- runs every 1/16th note of current clock bpm (based on a 4/4 time signature); e.g. every 125ms for 120bpm
    while true do
        if UPDATE_SLICES then
            for voice=0,5 do
                engine.loop_start(voice, params:get(ID_SAMPLING_SLICE_SECTIONS[voice+1].loop_start))
                engine.loop_end(voice, params:get(ID_SAMPLING_SLICE_SECTIONS[voice+1].loop_end))
            end
            UPDATE_SLICES = false
        end
        if cue_step_divider then
            -- wait until the current_global_step aligns with the new step_size
            if current_global_step % cue_step_divider == 0 then
                -- align the current global step with the new step divider, to prevent jumping
                current_global_step = current_step * cue_step_divider
                step_divider = cue_step_divider
                cue_step_divider = nil
            end
        end
        current_global_step = util.wrap(current_global_step + 1, 1, MAX_STEPS)

        -- hold step feature, UI available on seq-ctrl page
        if not holding_step then
            if hold_step then
                -- means step was held, but resumed this step
                -- current_global_step ticked on meanwhile; but we don't want to jump to another step; 
                -- shold always go on neatly to the n+1 sequence step
                print("resumed at "..current_global_step)
                current_global_step = current_step * step_divider + (current_step - hold_step )
                hold_step = nil
            end
            current_step = util.wrap(math.ceil(current_global_step / step_divider), 1, sequence_steps)
        else
            if hold_step == nil then
                print("Frozen at "..current_step)
                hold_step = current_step
            end
        end
        -- grid_graphic.current_step = current_step
        local x = current_step -- x pos of sequencer, i.e. current step

        -- true when switching from previous step to the current step
        local is_step_change = current_global_step % step_divider == 0

        if is_step_change then
            grid_graphic.current_step = current_step
        end

        for y = 1, SEQ_ROWS do
            -- todo: implement a check if it already fired for this step
            local perlin_val = params:get(ID_SEQ_STEP[y][x])
            local a = math.abs(perlin_val)
            local on = a > 0.0
            -- engine.env_level(y, a) -- always set env/gate level based on perlin val
            if on then
                -- using modulo check to prevent triggering every 1/16 when step size is larger
                if is_step_change then
                    grid_graphic.current_step = current_step
                    engine.trigger(y-1)
                    -- engine.filter_env(y-1, 800)
                    -- modulate attack and decay based on perlin value
                    local atk = math.max(params:get(ID_ENVELOPES_ATTACK) * a, 0.01)
                    local dec = params:get(ID_ENVELOPES_DECAY) * a
                    engine.attack(y-1, atk)
                    engine.decay(y-1, dec)
                    -- voice_position_to_phase(y, a) -- this was the phase sequencer, maybe not relevant anymore
                end
            elseif SEQUENCE_STYLE_TABLE[params:get(ID_SEQ_STYLE)] == SEQ_GATE then
                -- engine.stop(y-1)
            end
        end
        clock.sync(1/4)
    end
end

function toggle_transport()
    if transport_on then
        clock.transport.stop()
    else
        clock.transport.start()
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
    main_seq_clock_id = clock.run(main_sequencer_callback)
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

    amp1poll:update()
    amp2poll:update()
    amp3poll:update()
    amp4poll:update()
    amp5poll:update()
    amp6poll:update()

    grid_graphic:render()

    page.footer.button_text.k2.value = SEQ_EVOLVE_TABLE[params:get(ID_SEQ_EVOLVE)]
    page.footer.button_text.k3.value = SEQUENCE_STYLE_TABLE[params:get(ID_SEQ_STYLE)]
    page.footer.button_text.e2.value = params:get(ID_SEQ_PERLIN_X)
    page.footer.button_text.e3.value = params:get(ID_SEQ_PERLIN_DENSITY)
    page.footer:render()
    grid_device:refresh()
end

local function action_evolve(v)
    -- min one to disregard 
    if v > 1 then
        perlin_lfo:set('period', SEQ_EVOLVE_RATES[v-1])
        if perlin_lfo:get("enabled") == 0 then
            perlin_lfo:start()
        end
    elseif perlin_lfo:get("enabled") == 1 then
        perlin_lfo:stop()
    end
end

local function action_playback_style(v)
    for voice=1,6 do
        softcut.loop(voice, SEQUENCE_STYLE_TABLE_TO_SOFTCUT[v])
    end
end

local function update_grid_step(x,y,v)
    grid_graphic.sequences[y][x] = v
    if v > 0 then
        grid_device:led(x, y, 4 + math.floor(math.abs(v)*8))
    else
        grid_device:led(x, y, 0)
    end

end

grid.key = function(x,y,z)
    if SEQUENCE_STYLE_TABLE[params:get(ID_SEQ_STYLE)] == SEQ_GRID then
        -- would sequence from grid
    end
end


local function toggle_redraw()
    redraw_sequence = true
end

local function add_params()
    params:set_action(ID_SEQ_PERLIN_X, toggle_redraw)
    params:set_action(ID_SEQ_PERLIN_Y, toggle_redraw)
    params:set_action(ID_SEQ_PERLIN_Z, toggle_redraw)
    params:set_action(ID_SEQ_PERLIN_DENSITY, toggle_redraw)
    params:set_action(ID_SEQ_EVOLVE, action_evolve)
    params:set_action(ID_SEQ_STYLE, action_playback_style)
    for y = 1, SEQ_ROWS do
        for x = 1, SEQ_COLUMNS do
            params:set_action(ID_SEQ_STEP[y][x], function(v) update_grid_step(x,y,v) end)
        end
    end
end

local function report_softcut(voice, pos)
    -- if playhead moved since last report, assume track reached endpoint
    grid_graphic.is_playing[voice] = voice_pos[voice] ~= nil and voice_pos[voice] ~= pos

    voice_pos[voice] = pos
    local voice_dir = params:get(get_voice_dir_param_id(voice))
    -- todo : should be able to use ID_SAMPLING_SLICE_SECTIONS from sampling page, saves string concat
    local slice_start = params:get(get_slice_start_param_id(voice))
    local slice_end = params:get(get_slice_end_param_id(voice))
    local slice_length = slice_end - slice_start

    local normalized_pos = pos - slice_start
    if voice_dir == 1 then -- forward, todo: use table
        voice_pos_percentage[voice] = normalized_pos / slice_length
    else                   -- backwards
        -- e.g. slice length = 5.0 sec
        --- position = 32.0 - 37.0 seec
        --- position = 36.0 sec, but going backwards;
        --- so position is 36.0 - 32.0 = 4.0 (normalized_pos);
        --- then slice_length - normalized_pos (5.0-4.0) = 1.0 gives the relative position
        voice_pos_percentage[voice] = (slice_length - normalized_pos) / slice_length
    end
    grid_graphic.voice_pos_percentage[voice] = voice_pos_percentage[voice]
end

local function amp_callback(voice, val)
    grid_graphic.voice_amp[voice] = val
end


function page:initialize()
    -- allows value to be modified by other pages
    page.sequence_speed = sequence_util.convert_sequence_speed[sequence_util.default_speed_idx]
    add_params()
    amp1poll.callback = function(v) amp_callback(1, v) end
    amp2poll.callback = function(v) amp_callback(2, v) end
    amp3poll.callback = function(v) amp_callback(3, v) end
    amp4poll.callback = function(v) amp_callback(4, v) end
    amp5poll.callback = function(v) amp_callback(5, v) end
    amp6poll.callback = function(v) amp_callback(6, v) end

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
    grid_graphic = GridGraphic:new({
        rows = ROWS,
        columns = COLUMNS,
    })
    -- graphics
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "EVOLV",
                value = "",
            },
            k3 = {
                name = "STYLE",
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
    main_seq_clock_id = clock.run(main_sequencer_callback)
    -- for softcut updates
    softcut.event_position(report_softcut)

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

end

return page
