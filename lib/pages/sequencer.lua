local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local GridGraphic = include("bits/lib/graphics/Grid")
local Footer = include("bits/lib/graphics/Footer")
local perlin = include("bits/lib/ext/perlin")
local page_name = "SEQUENCER"
local window
local grid_graphic
local ROWS = 6
local COLUMNS = 16

local PARAM_ID_PERLIN_X = "sequencer_perlin_x"
local PARAM_ID_PERLIN_Y = "sequencer_perlin_y"
local PARAM_ID_PERLIN_Z = "sequencer_perlin_z"
local PARAM_ID_PERLIN_ZOOM = "sequencer_perlin_zoom"

local DIM_X = "X"
local DIM_Y = "Y"
local DIM_Z = "Z"
local ZOOM = "ZOOM"
local DIMENSIONS = {DIM_X, DIM_Y, DIM_Z, ZOOM}
local PARAM_ID_DIMENSIONS = {PARAM_ID_PERLIN_X, PARAM_ID_PERLIN_Y, PARAM_ID_PERLIN_Z, PARAM_ID_PERLIN_ZOOM}

local current_dimension = 1

local PARAM_ID_PERLIN_DENSITY = "sequencer_perlin_density"

local PARAM_ID_SEQUENCE_SPEED = "sequencer_speed"
local SEQ_PARAM_IDS = {}

local clock_id
local current_step = 1
local is_playing = {false,false,false,false,false,false} -- whether a softcut voice is playing
local voice_pos = {} -- playhead positions of softcut voices
local voice_pos_percentage = {}

local sequence_speeds = {"1/32", "1/16", "1/8", "1/4", "1/2", "1", "2", "4", "8"}
local DEFAULT_SEQUENCE_SPEED_IDX = 2
local convert_sequence_speed = {
     -- all fractions of 1/4th notes
    1/8,
    1/4,
    1/2,
    1,
    2,
    4,
    8,
    16,
    32,
}
local sequence_speed = convert_sequence_speed[DEFAULT_SEQUENCE_SPEED_IDX]

local controlspec_perlin = controlspec.def {
    min = 0,       -- the minimum value
    max = 9999,      -- the maximum value
    warp = 'lin',  -- a shaping option for the raw value
    step = .01,    -- output value quantization
    default = 0,   -- default value
    units = '',    -- displayed on PARAMS UI
    quantum = .05, -- each delta will change raw value by this much
    wrap = false   -- wrap around on overflow (true) or clamp (false)
}

local controlspec_perlin_density = controlspec.def {
    min = 0,       -- the minimum value
    max = 1,      -- the maximum value
    warp = 'lin',  -- a shaping option for the raw value
    step = .01,    -- output value quantization
    default = 0.4,   -- default value
    units = '',    -- displayed on PARAMS UI
    quantum = .01, -- each delta will change raw value by this much
    wrap = false   -- wrap around on overflow (true) or clamp (false)
}

local function generate_perlin_seq()
    -- need as many values as there are rows and columns
    local zoom = params:get(PARAM_ID_PERLIN_ZOOM)
    local density = params:get(PARAM_ID_PERLIN_DENSITY)
    local x_seed = params:get(PARAM_ID_PERLIN_X)
    local y_seed = params:get(PARAM_ID_PERLIN_Y)
    local z_seed = params:get(PARAM_ID_PERLIN_Z)
    for voice=1, ROWS do
        for step=1,COLUMNS do
            local perlin_x = step * zoom + x_seed
            local perlin_y = voice * zoom + y_seed
            local perlin_z = z_seed
            local n = perlin:noise(perlin_x, perlin_y, perlin_z) -- -1 to 1
            local v = (1 + n)/2 -- 0 to 1
            -- adding density before rounding down gives control over number of active sequence stepps
            params:set(SEQ_PARAM_IDS[voice][step], math.floor(v+density))
        end
    end
end

local function e2(d)
    -- works for x, y, and z
    local p = PARAM_ID_DIMENSIONS[current_dimension]
    local new = params:get(p) + controlspec_perlin.quantum * d
    params:set(p, new, false)
end

local function e3(d)
    local new = params:get(PARAM_ID_PERLIN_DENSITY) + controlspec_perlin_density.quantum * d
    params:set(PARAM_ID_PERLIN_DENSITY, new, false)
end

local function update_grid_state()
    for y=1,ROWS do
        for x=1,COLUMNS do
            grid_graphic.sequences[y][x] = params:get(SEQ_PARAM_IDS[y][x])
        end
    end
end

function pulse()
    -- advance 
    while true do
        current_step = util.wrap(current_step + 1,1,16)
        local x = current_step -- x pos of sequencer, i.e. current step
        for y = 1, ROWS do
            local on = params:get(SEQ_PARAM_IDS[y][x])
            if on == 1 then

                if params:get(get_voice_dir_param_id(y)) == 1 then
                    -- play forward
                    -- query position
                    softcut.position(y, params:get(get_slice_start_param_id(y)))
                else
                    -- play reverse, start at end
                    softcut.position(y, params:get(get_slice_end_param_id(y)))
                end
                softcut.play(y, 1)
            else
                -- softcut.play(y, 0)
            end
        end
        clock.sync(sequence_speed)
    end
end

function clock.transport.start()
    print("restart")
    clock_id = clock.run(pulse)
end

function clock.transport.stop()
    print("cancel")
    clock.cancel(clock_id)
end

local function toggle_perlin()
    generate_perlin_seq()
end

local function cycle_dimension()
    current_dimension = util.wrap(current_dimension+1, 1, #DIMENSIONS)
end


local page = Page:create({
    name = page_name,
    e2 = e2,
    e3 = e3,
    k2_off = toggle_perlin,
    k3_off = cycle_dimension,
})

local function action_sequence_speed(v)
    -- convert table index of human-readable options to value for clock.sync
    sequence_speed = convert_sequence_speed[v]
end

local function track_indicator(voice)
    local brightness = 1 + math.floor((1 - voice_pos_percentage[voice]) * 14)
    screen.level(brightness)
    screen.rect(96, 16 + (4*(voice-1)), 1,3)
    screen.fill()
end

function page:render()
    window:render()
    update_grid_state() -- typically not needed, only when pset is loaded
    grid_graphic:render()

    for voice = 1,6 do
        if is_playing[voice] then
            track_indicator(voice)
        end
    end
    for voice = 1,6 do
        softcut.query_position(voice)
    end
    page.footer.button_text.k3.value = DIMENSIONS[current_dimension]
    page.footer.button_text.e2.name = DIMENSIONS[current_dimension]
    page.footer.button_text.e3.name = "DENS"
    page.footer.button_text.e2.value = params:get(PARAM_ID_DIMENSIONS[current_dimension])
    page.footer.button_text.e3.value = params:get(PARAM_ID_PERLIN_DENSITY)


    -- todo: move to graphic class
    screen.level(15)
    screen.rect(28 + (current_step * 4), 27, 3, 1)
    screen.fill()
    page.footer:render()
end

local function add_params()
    params:add_separator("SEQUENCER", page_name)

    params:add_control(PARAM_ID_PERLIN_X, "perlin x", controlspec_perlin)
    params:set_action(PARAM_ID_PERLIN_X, generate_perlin_seq)

    params:add_control(PARAM_ID_PERLIN_Y, "perlin y", controlspec_perlin)
    params:set_action(PARAM_ID_PERLIN_Y, generate_perlin_seq)

    params:add_control(PARAM_ID_PERLIN_Z, "perlin z", controlspec_perlin)
    params:set_action(PARAM_ID_PERLIN_Z, generate_perlin_seq)

    params:add_control(PARAM_ID_PERLIN_ZOOM, "perlin zoom", controlspec_perlin)
    params:set_action(PARAM_ID_PERLIN_ZOOM, generate_perlin_seq)
    params:set(PARAM_ID_PERLIN_ZOOM, 1/3, true)

    params:add_control(PARAM_ID_PERLIN_DENSITY, "perlin density", controlspec_perlin_density)
    params:set_action(PARAM_ID_PERLIN_DENSITY, generate_perlin_seq)

    params:add_option(PARAM_ID_SEQUENCE_SPEED, "sequence speed", sequence_speeds, DEFAULT_SEQUENCE_SPEED_IDX)
    params:set_action(PARAM_ID_SEQUENCE_SPEED, action_sequence_speed)

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
    is_playing[voice] = voice_pos[voice] ~= nil and voice_pos[voice] ~= pos

    voice_pos[voice] = pos
    local voice_dir = params:get(get_voice_dir_param_id(voice))

    -- todo : should be able to use SLICE_PARAM_IDS from sampling page, saves string concat
    local slice_start = params:get(get_slice_start_param_id(voice))
    local slice_end = params:get(get_slice_end_param_id(voice))
    local slice_length = slice_end - slice_start

    local normalized_pos = pos - slice_start
    if voice_dir == 1 then -- forward, todo: use table
        voice_pos_percentage[voice] = normalized_pos / slice_length
    else -- backwards
        -- e.g. slice length = 5.0 sec
        --- position = 32.0 - 37.0 seec
        --- position = 36.0 sec, but going backwards;
        --- so position is 36.0 - 32.0 = 4.0 (normalized_pos);
        --- then slice_length - normalized_pos (5.0-4.0) = 1.0 gives the relative position
        voice_pos_percentage[voice] = (slice_length - normalized_pos) / slice_length
    end
end

function page:initialize()
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
                name = "GEN",
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
    clock_id = clock.run(pulse)

    -- for softcut updates
    softcut.event_position(report_softcut)
end

return page
