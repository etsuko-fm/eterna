local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local state_util = include("bits/lib/util/state")
local GridGraphic = include("bits/lib/graphics/Grid")
local Footer = include("bits/lib/graphics/Footer")
local misc_util = include("bits/lib/util/misc")
local perlin = include("bits/lib/ext/perlin")
local page_name = "SEQUENCER"
local window
local grid_graphic
local DEFAULT_PERIOD = 6
local ROWS = 6
local COLUMNS = 16
local MAX_SLICES = COLUMNS

local PARAM_ID_NAV_X = "sequencer_nav_x"
local PARAM_ID_NAV_Y = "sequencer_nav_y"

local POSITION_MIN = 0
local POSITION_MAX = 1 -- represents a scan position that in turn sets all 6 playheads

local SEQ_PARAM_IDS = {}

local clock_id
local current_step = 1

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

local function action_perlin_x(v)
end

local function action_perlin_y(v)
end

local function action_nav_x(v)
    grid_graphic.cursor.x = v
end

local function action_nav_y(v)
    grid_graphic.cursor.y = v
end

local function e2(state, d)
    local new = params:get(PARAM_ID_NAV_X) + controlspec_nav_x.quantum * d
    params:set(PARAM_ID_NAV_X, new, false)
end

local function e3(state, d)
    local new = params:get(PARAM_ID_NAV_Y) + controlspec_nav_y.quantum * d
    params:set(PARAM_ID_NAV_Y, new, false)
end

local function toggle_step(state)
    local x = params:get(PARAM_ID_NAV_X)
    local y = params:get(PARAM_ID_NAV_Y)
    local curr = params:get(SEQ_PARAM_IDS[y][x])
    local new = 1 - curr
    params:set(SEQ_PARAM_IDS[y][x], new)
    grid_graphic.sequences[y][x] = new
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
                    local param_str_start = "sampling_" .. y .. "start"
                    softcut.position(y, params:get(param_str_start))
                else
                    -- play reverse, start at end
                    local param_str_end = "sampling_" .. y .. "end"
                    softcut.position(y, params:get(param_str_end))
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

local function toggle_perlin(state)
end


local page = Page:create({
    name = page_name,
    e2 = e2,
    e3 = e3,
    k2_off = toggle_step,
    k3_off = toggle_perlin,
})

function page:render(state)
    window:render()
    grid_graphic:render()
    page.footer.button_text.e2.value = params:get(PARAM_ID_NAV_X)
    page.footer.button_text.e3.value = params:get(PARAM_ID_NAV_Y)
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

function page:initialize(state)
    add_params()
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "SEQUENCER",
        font_face = state.title_font,
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
                name = "Y",
                value = "",
            },
        },
        font_face = state.footer_font,
    })

    -- start sequencer
    clock_id = clock.run(pulse)
end

return page
