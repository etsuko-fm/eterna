local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local GridGraphic = include("bits/lib/graphics/Grid")
local Footer = include("bits/lib/graphics/Footer")
local perlin = include("bits/lib/ext/perlin")
local sequence_util = include("bits/lib/util/sequence")
local page_name = "SEQUENCER"
local window
local grid_graphic
local ROWS = 6
local COLUMNS = 16

local PERLIN_ZOOM = 4/3 ---4 / 3 -- empirically tuned

local ID_SEQ_DIMENSIONS = { ID_SEQ_PERLIN_X, ID_SEQ_PERLIN_Y, ID_SEQ_PERLIN_Z }
local SEQ_EVOLVE_RATES = {1024*12, 1024*8, 1024*4} -- in quarter notes, but fuzzy concept due to how perlin computes
local current_dimension = 1

local LOOP_TABLE_TO_SOFTCUT = {1, 0}


local MAX_STEPS = sequence_util.max_steps

local transport_on = true
local holding_step = false


-- todo: add in bits.lua? otherwise dependent on order of pages loaded


local main_seq_clock_id
local current_step = 1
local current_global_step = 1 -- holds values of 1 to MAX_STEPS, even if sequence length is shorter

local sequence_steps = 16
local step_divider = 1 -- 1 means 1 step = 1 1/16th note
local cue_step_divider = nil

local voice_pos = {} -- playhead positions of softcut voices
local voice_pos_percentage = {}
local perlin_lfo

-- softcut VCA system concept:
-- set_master_volume(voice, x)
-- use level_slew_time to create envelopes

local function generate_perlin_seq()
    -- print("regen - ", math.random())
    -- need as many values as there are rows and columns
    local density = params:get(ID_SEQ_PERLIN_DENSITY)
    local x_seed = params:get(ID_SEQ_PERLIN_X)
    local y_seed = params:get(ID_SEQ_PERLIN_Y)
    local z_seed = params:get(ID_SEQ_PERLIN_Z)

    for voice = 1, ROWS do
        for step = 1, COLUMNS do
            local perlin_x = step * PERLIN_ZOOM + x_seed
            local perlin_y = voice * PERLIN_ZOOM + y_seed
            local perlin_z = z_seed
            local v = perlin:noise(perlin_x, perlin_y, perlin_z) -- -1 to 1
            if math.abs(v) > density then
                -- if value is .81/-.81 and density is .8, value is filtered out; 
                -- generalized, then 20% of the values is filtered out. 
                -- so higher density, is more values in sequence.
                v = 0.0 -- 0.0 is only value not interpreted as an active step
            end
            params:set(SEQ_PARAM_IDS[voice][step], v)
        end
    end
end

local function e2(d)
    -- works for x, y, and z
    local p = ID_SEQ_DIMENSIONS[current_dimension]
    local new = params:get(p) + controlspec_perlin.quantum * d
    params:set(p, new, false)
end

local function e3(d)
    local new = params:get(ID_SEQ_PERLIN_DENSITY) + controlspec_perlin_density.quantum * d
    params:set(ID_SEQ_PERLIN_DENSITY, new, false)
end

local function update_grid_state()
    for y = 1, ROWS do
        for x = 1, COLUMNS do
            grid_graphic.sequences[y][x] = params:get(SEQ_PARAM_IDS[y][x])
        end
    end
end

local function toggle_evolve()
    local p = ID_SEQ_EVOLVE
    local new = util.wrap(params:get(p) + 1, 1, #SEQ_EVOLVE_TABLE)
    params:set(p, new)
end

local function toggle_playback_style()
    local p = ID_SEQ_PB_STYLE
    local new = util.wrap(params:get(p) + 1, 1, #LOOP_TABLE)
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
    cue_step_divider = v
end

function voice_position_to_start(voice)
    if params:get(get_voice_dir_param_id(voice)) == 1 then
        -- play forward
        -- query position
        softcut.position(voice, params:get(get_slice_start_param_id(voice)))
    else
        -- play reverse, start at end
        softcut.position(voice, params:get(get_slice_end_param_id(voice)))
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
    softcut.position(voice, abs_pos)
end

local hold_step = nil
local function main_sequencer_callback()
    -- advance
    while true do
        if cue_step_divider then
            print("step division cued to "..cue_step_divider)
            print(current_global_step)
            -- wait until the current_global_step aligns with the new step_size
            if current_global_step % cue_step_divider == 0 then
                -- align the current global step with the new step divider, to prevent jumping
                current_global_step = current_step * cue_step_divider
                step_divider = cue_step_divider
                cue_step_divider = nil
                print("switched!")
            end
        end
        current_global_step = util.wrap(current_global_step + 1, 1, MAX_STEPS)

        if not holding_step then
            if hold_step then
                -- means resumed this frame
                -- current_global_step ticked on meanwhile; but we don't want to jump frames
                -- except for any offset introduced
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
        grid_graphic.current_step = current_step
        local x = current_step -- x pos of sequencer, i.e. current step
        for y = 1, ROWS do
            -- todo: implement a check if it already fired for this step
            local perlin_val = params:get(SEQ_PARAM_IDS[y][x])
            local a = math.abs(perlin_val)
            local on = a > 0.0

            if on and current_global_step % step_divider == 0 then
                voice_position_to_phase(y, a)
                softcut.play(y, 1)
                -- if perlin_val < 0 then
                --     softcut.post_filter_bp(y, a)
                --     softcut.post_filter_br(y, 0)
                -- else
                --     softcut.post_filter_bp(y, 0)
                --     softcut.post_filter_br(y, a)
                -- end
                -- softcut.post_filter_dry(y, 1-a)
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
    update_grid_state() -- typically not needed, only when pset is loaded
    grid_graphic:render()
    if selected_sample then
        for voice = 1, 6 do
            softcut.query_position(voice)
        end
    end
    page.footer.button_text.k2.value = SEQ_EVOLVE_TABLE[params:get(ID_SEQ_EVOLVE)]
    page.footer.button_text.k3.value = LOOP_TABLE[params:get(ID_SEQ_PB_STYLE)]
    page.footer.button_text.e3.name = "DENS"
    page.footer.button_text.e2.value = params:get(ID_SEQ_PERLIN_X)
    page.footer.button_text.e3.value = params:get(ID_SEQ_PERLIN_DENSITY)

    page.footer:render()
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
        softcut.loop(voice, LOOP_TABLE_TO_SOFTCUT[v])
    end
end

local function add_params()
    params:set_action(ID_SEQ_PERLIN_X, generate_perlin_seq)
    params:set_action(ID_SEQ_PERLIN_Y, generate_perlin_seq)
    params:set_action(ID_SEQ_PERLIN_Z, generate_perlin_seq)
    params:set_action(ID_SEQ_PERLIN_DENSITY, generate_perlin_seq)
    params:set_action(ID_SEQ_EVOLVE, action_evolve)
    params:set_action(ID_SEQ_PB_STYLE, action_playback_style)
end

local function report_softcut(voice, pos)
    -- if playhead moved since last report, assume track reached endpoint
    grid_graphic.is_playing[voice] = voice_pos[voice] ~= nil and voice_pos[voice] ~= pos

    voice_pos[voice] = pos
    local voice_dir = params:get(get_voice_dir_param_id(voice))

    -- todo : should be able to use SLICE_PARAM_IDS from sampling page, saves string concat
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

function page:initialize()
    -- allows value to be modified by other pages
    page.sequence_speed = sequence_util.convert_sequence_speed[sequence_util.default_speed_idx]
    add_params()
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
            params:set(ID_SEQ_PERLIN_Z, controlspec_perlin:map(scaled))
        end
    }

end

return page
