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

local ID_SEQ_PERLIN_X = "sequencer_perlin_x"
local ID_SEQ_PERLIN_Y = "sequencer_perlin_y"
local ID_SEQ_PERLIN_Z = "sequencer_perlin_z"
local ID_SEQ_EVOLVE = "sequencer_evolve"
local PERLIN_ZOOM = 4/3 ---4 / 3 -- empirically tuned

local DIM_X = "X"
local DIM_Y = "Y"
local DIM_Z = "Z"
local SEQ_DIMENSIONS = { DIM_X, DIM_Y, DIM_Z }
local ID_SEQ_DIMENSIONS = { ID_SEQ_PERLIN_X, ID_SEQ_PERLIN_Y, ID_SEQ_PERLIN_Z }
local SEQ_EVOLVE_TABLE = {"OFF", "SLOW", "MED", "FAST"}
local SEQ_EVOLVE_RATES = {1024*12, 1024*8, 1024*4}
local current_dimension = 1

local ID_SEQ_PERLIN_DENSITY = "sequencer_perlin_density"
local MAX_STEPS = sequence_util.max_steps

local transport_on = true
local holding_step = false

-- todo: add in bits.lua? otherwise dependent on order of pages loaded

local SEQ_PARAM_IDS = {}

local main_seq_clock_id
local current_step = 1
local current_global_step = 1 -- holds values of 1 to MAX_STEPS, even if sequence length is shorter

local sequence_steps = 16
local step_divider = 1 -- 1 means 1 step = 1 1/16th note

local voice_pos = {} -- playhead positions of softcut voices
local perlin_lfo

local controlspec_perlin = controlspec.def {
    min = 0,       -- the minimum value
    max = 100,    -- the maximum value
    warp = 'lin',  -- a shaping option for the raw value
    step = .01,    -- output value quantization
    default = 0,   -- default value
    units = '',    -- displayed on PARAMS UI
    quantum = .1, -- each delta will change raw value by this much
    wrap = true    -- wrap around on overflow (true) or clamp (false)
}

local controlspec_perlin_density = controlspec.def {
    min = 0,       -- the minimum value
    max = 1,       -- the maximum value
    warp = 'lin',  -- a shaping option for the raw value
    step = .001,    -- output value quantization
    default = 0.35, -- default value
    units = '',    -- displayed on PARAMS UI
    quantum = .01, -- each delta will change raw value by this much
    wrap = false   -- wrap around on overflow (true) or clamp (false)
}

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
            local n = perlin:noise(perlin_x, perlin_y, perlin_z) -- -1 to 1
            local v = (1 + n) / 2                                -- 0 to 1
            -- adding density before rounding down gives control over number of active sequence stepps
            params:set(SEQ_PARAM_IDS[voice][step], math.floor(v + density))
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

local function cycle_dimension()
    current_dimension = util.wrap(current_dimension + 1, 1, #SEQ_DIMENSIONS)
end


local page = Page:create({
    name = page_name,
    e2 = e2,
    e3 = e3,
    k2_off = toggle_evolve,
    k3_off = cycle_dimension,
})

function set_step_divider(v)
    step_divider = v
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

local function main_sequencer_callback()
    -- advance
    while true do
        if not holding_step then
            current_global_step = util.wrap(current_global_step + 1, 1, MAX_STEPS)
            -- num of sequence steps is static, always 16
            -- if 1/16:
            --- current_step = current_global_step % 16
            --- if 1/8:
            --- current_step = (current_global_step / 2) % 16
            --- if 1/4:
            --- current_step = (current_global_step / 4) % 16
            --- etc, so to support 1 bar per step, you need 16*16 = 256 global steps; or 1024 to support 4 bars per step
            current_step = util.wrap(math.ceil(current_global_step / step_divider), 1, sequence_steps)
        end
        grid_graphic.current_step = current_step
        local x = current_step -- x pos of sequencer, i.e. current step
        for y = 1, ROWS do
            local on = params:get(SEQ_PARAM_IDS[y][x])
            if on == 1 then
                voice_position_to_start(y)
                softcut.play(y, 1)
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

    for voice = 1, 6 do
        softcut.query_position(voice)
    end
    page.footer.button_text.k2.value = SEQ_EVOLVE_TABLE[params:get(ID_SEQ_EVOLVE)]
    page.footer.button_text.k3.value = SEQ_DIMENSIONS[current_dimension]
    page.footer.button_text.e2.name = SEQ_DIMENSIONS[current_dimension]
    page.footer.button_text.e3.name = "DENS"
    page.footer.button_text.e2.value = params:get(ID_SEQ_DIMENSIONS[current_dimension])
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

local function add_params()
    params:add_separator("SEQUENCER", page_name)

    params:add_control(ID_SEQ_PERLIN_X, "perlin x", controlspec_perlin)
    params:set_action(ID_SEQ_PERLIN_X, generate_perlin_seq)

    params:add_control(ID_SEQ_PERLIN_Y, "perlin y", controlspec_perlin)
    params:set_action(ID_SEQ_PERLIN_Y, generate_perlin_seq)

    params:add_control(ID_SEQ_PERLIN_Z, "perlin z", controlspec_perlin)
    params:set_action(ID_SEQ_PERLIN_Z, generate_perlin_seq)

    params:add_control(ID_SEQ_PERLIN_DENSITY, "perlin density", controlspec_perlin_density)
    params:set_action(ID_SEQ_PERLIN_DENSITY, generate_perlin_seq)

    params:add_option(ID_SEQ_EVOLVE, "perlin evolve", SEQ_EVOLVE_TABLE, 1)
    params:set_action(ID_SEQ_EVOLVE, action_evolve)

    -- add 96 params for sequence step status
    for y = 1, 6 do
        SEQ_PARAM_IDS[y] = {}
        for x = 1, 16 do
            SEQ_PARAM_IDS[y][x] = "sequencer_step_" .. y .. "_" .. x
            params:add_binary(SEQ_PARAM_IDS[y][x], SEQ_PARAM_IDS[y][x], "toggle", 0)
            params:hide(SEQ_PARAM_IDS[y][x])
        end
    end
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
        grid_graphic.voice_pos_percentage[voice] = normalized_pos / slice_length
    else                   -- backwards
        -- e.g. slice length = 5.0 sec
        --- position = 32.0 - 37.0 seec
        --- position = 36.0 sec, but going backwards;
        --- so position is 36.0 - 32.0 = 4.0 (normalized_pos);
        --- then slice_length - normalized_pos (5.0-4.0) = 1.0 gives the relative position
        grid_graphic.voice_pos_percentage[voice] = (slice_length - normalized_pos) / slice_length
    end
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
                name = "TRAVL",
                value = "",
            },
            e2 = {
                name = "X",
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
