local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local GridGraphic = include("bits/lib/graphics/Grid")
local Footer = include("bits/lib/graphics/Footer")
local misc_util = include("bits/lib/util/misc")
local perlin = include("bits/lib/ext/perlin")
local page_name = "SEQUENCER"
local window
local grid_graphic
local ROWS = 6
local COLUMNS = 16

local PARAM_ID_NAV_X = "sequencer_nav_x"
local PARAM_ID_NAV_Y = "sequencer_nav_y"

local PARAM_ID_PERLIN_X = "sequencer_perlin_x"
local PARAM_ID_PERLIN_DENSITY = "sequencer_perlin_density"

local MANUAL = "MANUAL"
local PERLIN = "PERLIN"
local current_edit_mode = MANUAL

local SEQ_PARAM_IDS = {}

local clock_id
local current_step = 1
local is_playing = {false,false,false,false,false,false} -- whether a softcut voice is playing
local voice_pos = {} -- playhead positions of softcut voices
local voice_pos_percentage = {}

local controlspec_nav_x = controlspec.def {
    min = 1,       -- the minimum value
    max = COLUMNS, -- the maximum value
    warp = 'lin',  -- a shaping option for the raw value
    step = 1,      -- output value quantization
    default = 1,   -- default value
    units = '',    -- displayed on PARAMS UI
    quantum = 1.0, -- each delta will change raw value by this much
    wrap = false   -- wrap around on overflow (true) or clamp (false)
}

local controlspec_nav_y = controlspec.def {
    min = 1,      -- the minimum value
    max = ROWS,   -- the maximum value
    warp = 'lin', -- a shaping option for the raw value
    step = 1,     -- output value quantization
    default = 0,  -- default value
    units = '',   -- displayed on PARAMS UI
    quantum = 1,  -- each delta will change raw value by this much
    wrap = false  -- wrap around on overflow (true) or clamp (false)
}

local controlspec_perlin = controlspec.def {
    min = 0,       -- the minimum value
    max = 10,      -- the maximum value
    warp = 'lin',  -- a shaping option for the raw value
    step = .01,    -- output value quantization
    default = 0,   -- default value
    units = '',    -- displayed on PARAMS UI
    quantum = .01, -- each delta will change raw value by this much
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
    local step = 1/3
    local seed =  params:get(PARAM_ID_PERLIN_X)
    local density = params:get(PARAM_ID_PERLIN_DENSITY)
    for y=1, ROWS do
        for x=1,COLUMNS do
            -- result[y][x] = perlin:noise(x*step + seedx, y*step + seedy)
            local v = (1 + perlin:noise(x*step +seed, y*step + seed))/2
            params:set(SEQ_PARAM_IDS[y][x], math.floor(v+density))
        end
    end
end

local function action_perlin_x(v)
    generate_perlin_seq()
end

local function action_perlin_density(v)
    generate_perlin_seq()
end

local function action_nav_x(v)
    grid_graphic.cursor.x = v
end

local function action_nav_y(v)
    grid_graphic.cursor.y = v
end

local function e2(d)
    if current_edit_mode == MANUAL then
        local new = params:get(PARAM_ID_NAV_X) + controlspec_nav_x.quantum * d
        params:set(PARAM_ID_NAV_X, new, false)
    else
        local new = params:get(PARAM_ID_PERLIN_X) + controlspec_perlin.quantum * d
        params:set(PARAM_ID_PERLIN_X, new, false)
    end
end

local function e3(d)
    if current_edit_mode == MANUAL then
        local new = params:get(PARAM_ID_NAV_Y) + controlspec_nav_y.quantum * d
        params:set(PARAM_ID_NAV_Y, new, false)
    else
        local new = params:get(PARAM_ID_PERLIN_DENSITY) + controlspec_perlin_density.quantum * d
        params:set(PARAM_ID_PERLIN_DENSITY, new, false)
    end
end

local function toggle_step()
    local x = params:get(PARAM_ID_NAV_X)
    local y = params:get(PARAM_ID_NAV_Y)
    local curr = params:get(SEQ_PARAM_IDS[y][x])
    local new = 1 - curr
    params:set(SEQ_PARAM_IDS[y][x], new)
    grid_graphic.sequences[y][x] = new
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
                    -- query position, todo: param id is defined on sampling page
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
        clock.sync(1/4)
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
    if current_edit_mode == MANUAL then
        current_edit_mode = PERLIN
        generate_perlin_seq()
    else
        current_edit_mode = MANUAL
    end
end


local page = Page:create({
    name = page_name,
    e2 = e2,
    e3 = e3,
    k2_off = toggle_step,
    k3_off = toggle_perlin,
})


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
    if current_edit_mode == MANUAL then
        page.footer.button_text.k3.name = "MANUA"
        page.footer.button_text.e2.name = "STEP"
        page.footer.button_text.e3.name = "VOICE"
        page.footer.button_text.e2.value = params:get(PARAM_ID_NAV_X)
        page.footer.button_text.e3.value = params:get(PARAM_ID_NAV_Y)
    else
        page.footer.button_text.k3.name = "GEN"
        page.footer.button_text.e2.name = "SCROL"
        page.footer.button_text.e3.name = "DENS"
        page.footer.button_text.e2.value = params:get(PARAM_ID_PERLIN_X)
        page.footer.button_text.e3.value = params:get(PARAM_ID_PERLIN_DENSITY)
    end

    screen.level(15)
    screen.rect(28 + (current_step * 4) ,24, 3, 1)
    screen.fill()
    page.footer:render()
end

local function add_params()
    params:add_separator("SEQUENCER", page_name)
    params:add_control(PARAM_ID_NAV_X, "nav_x", controlspec_nav_x)
    params:set_action(PARAM_ID_NAV_X, action_nav_x)

    params:add_control(PARAM_ID_NAV_Y, "nav_y", controlspec_nav_y)
    params:set_action(PARAM_ID_NAV_Y, action_nav_y)

    params:add_control(PARAM_ID_PERLIN_X, "perlin x", controlspec_perlin)
    params:set_action(PARAM_ID_PERLIN_X, action_perlin_x)

    params:add_control(PARAM_ID_PERLIN_DENSITY, "perlin density", controlspec_perlin_density)
    params:set_action(PARAM_ID_PERLIN_DENSITY, action_perlin_density)

    for y = 1, 6 do
        SEQ_PARAM_IDS[y] = {}
        for x = 1, 16 do
            SEQ_PARAM_IDS[y][x] = "sequencer_step_" .. y .. "_" .. x
            params:add_binary(SEQ_PARAM_IDS[y][x], SEQ_PARAM_IDS[y][x], "toggle", 0)
            params:hide(SEQ_PARAM_IDS[y][x])
        end
    end

    params:hide(PARAM_ID_NAV_X)
    params:hide(PARAM_ID_NAV_Y)
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
                name = "TOGGL",
                value = "",
            },
            k3 = {
                name = "PERLN",
                value = "",
            },
            e2 = {
                name = "X",
                value = "",
            },
            e3 = {
                name = "DENSITY",
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
