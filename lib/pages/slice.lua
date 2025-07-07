local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local state_util = include("bits/lib/util/state")
local GridGraphic = include("bits/lib/graphics/Grid")
local Footer = include("bits/lib/graphics/Footer")
local misc_util = include("bits/lib/util/misc")
local lfo_util = include("bits/lib/util/lfo")
local perlin = include("bits/lib/ext/perlin")
local page_name = "SLICE"
local window
local grid_graphic
local DEFAULT_PERIOD = 6
local ROWS = 6
local COLUMNS = 16
local MAX_SLICES = COLUMNS

local PARAM_ID_LFO_ENABLED = "slice_lfo_enabled"
local PARAM_ID_LFO_SHAPE = "slice_lfo_shape"
local PARAM_ID_LFO_RATE = "slice_lfo_rate"
local PARAM_ID_POS = "slice_pos"
local PARAM_ID_LENGTH = "slice_length"

local POSITION_MIN = 0
local POSITION_MAX = 1 -- represents a scan position that in turn sets all 6 playheads

local LENGTH_MIN = 1
local LENGTH_MAX = COLUMNS

local LFO_SHAPES = { "sine", "up", "down", "random" }

local controlspec_pos = controlspec.def {
    min = POSITION_MIN, -- the minimum value
    max = POSITION_MAX, -- the maximum value
    warp = 'lin',       -- a shaping option for the raw value
    step = .01,        -- output value quantization
    default = 0,      -- default value
    units = '',         -- displayed on PARAMS UI
    quantum = .01,     -- each delta will change raw value by this much
    wrap = false         -- wrap around on overflow (true) or clamp (false)
}

local controlspec_length = controlspec.def {
    min = LENGTH_MIN, -- the minimum value
    max = LENGTH_MAX, -- the maximum value
    warp = 'lin',    -- a shaping option for the raw value
    step = 1,     -- output value quantization
    default = 1,   -- default value
    units = '',      -- displayed on PARAMS UI
    quantum = 1,  -- each delta will change raw value by this much
    wrap = false     -- wrap around on overflow (true) or clamp (false)
}
local function update_row(idx, start_idx, end_idx)
    -- update grid graphic to reflect update state by user or lfo
    grid_graphic.voices[idx].start_active = start_idx
    grid_graphic.voices[idx].end_active = end_idx
end

function update_enabled_section(state)
    -- determine current length of sample; either the full sample, or the enabled section of a sample that's longer 
    -- than the allowed length (as set by state.max_sample_length)
    local current_length = math.min(state.sample_length, state.max_sample_length)

    -- this needs to be refactored, this should be done x6

    -- enabled section is per-voice now
    -- state.pages.slice.enabled_section[1] = ((state.pages.slice.seek.start - 1) / MAX_SLICES) * current_length
    -- state.pages.slice.enabled_section[2] = math.min(
    --     state.pages.slice.enabled_section[1] + (state.pages.slice.seek.width / MAX_SLICES * current_length),
    --     state.max_sample_length)

    --todo: not sure if still needed after randomization change
    -- local enabled_section_length = state.pages.slice.enabled_section[2] - state.pages.slice.enabled_section[1]
    -- if enabled_section_length > state.max_sample_length then
    --     state.pages.slice.enabled_section[2] = state.pages.slice.enabled_section[1] + state.max_sample_length
    -- end
    update_softcut(state)
end

local function update_rows()
    local p = 1 + perlin:noise(params:get(PARAM_ID_POS)) / 2 -- normalize perlin noise from 0 to 1
    local pixel_pos = math.floor(p * (COLUMNS-1))

    for i = 1,6 do
        -- local offset = (i-1) * params:get(PARAM_ID_POS)
        local p2 = .5 -- 1 + perlin:noise(params:get(PARAM_ID_LENGTH)/COLUMNS, 1/i) / 2
        update_row(i, pixel_pos, pixel_pos + (p2 * COLUMNS))
    end
end

local function action_length(v)
    -- update_enabled_section(state)
    -- reset_softcut_positions(state)
    update_rows()
end

local function action_pos(v)
    update_rows()
end

local function action_lfo_enable(v)

end

local function action_lfo_rate(v)
end


local function action_lfo_shape(v)
end


local function adjust_pos(state, d)
--     -- upper limit of start of slice depends on the length of the slice
--     local max_start = (MAX_SLICES + 1) - params:get(PARAM_ID_LENGTH)
--     local cur_pos = params:get(PARAM_ID_POS)
--     -- params:set(PARAM_ID_POS, )
--     state_util.adjust_param(state.pages.slice.seek, 'start', d, 1, 1, max_start)
--     update_enabled_section(state)
--     reset_softcut_positions(state)
--     for i = 1,6 do
--         update_row(i)
--     end
end

local function adjust_length(state, d)
    -- state_util.adjust_param(state.pages.slice.seek, 'width', d, 1, 1, (MAX_SLICES + 1) - state.pages.slice.seek.start)
    -- local max_start = (MAX_SLICES + 1) - state.pages.slice.seek.width
    -- state.pages.slice.lfo:set('max', max_start)

    -- if d < 0 then
    --     reset_softcut_positions(state)
    -- end
    params:set(PARAM_ID_LENGTH, params:get(PARAM_ID_LENGTH) + d * controlspec_length.quantum)
    -- update_enabled_section(state)
    -- for i=1,6 do
    --     update_row(state)
    -- end
end

local function toggle_shape(state)
    local shapes = { "sine", "up", "down", "random" }
    lfo_util.toggle_shape(state.pages.slice.lfo, shapes)
end


local function toggle_lfo(state)
    if state.pages.slice.lfo:get("enabled") == 1 then
        state.pages.slice.lfo:stop()
    else
        state.pages.slice.lfo:start()
    end
    -- todo: re-add set phase
    -- state.pages.slice.lfo:set('phase', state.pages.slice.seek.start / 128)
end


local function adjust_lfo_rate(state, d)
    local k = (10 ^ math.log(state.pages.slice.lfo:get('period'), 10)) / 50
    local min = 0.2
    local max = 256

    local new_val = state.pages.slice.lfo:get('period') + (d * k)
    if new_val < min then
        new_val = min
    end
    if new_val > max then
        new_val = max
    end
    state.pages.slice.lfo:set('period', new_val)
end

local function e2(state, d)
    if state.pages.slice.lfo:get("enabled") == 1 then
        adjust_lfo_rate(state, d)
    else
        params:set(PARAM_ID_POS, params:get(PARAM_ID_POS) + d * controlspec_pos.quantum)
    end
end


local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = e2,
    e3 = adjust_length,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = toggle_lfo,
    k3_on = nil,
    k3_off = toggle_shape,
})

function page:render(state)
    window:render()
    grid_graphic:render()

    if state.pages.slice.lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        page.footer.button_text.k2.value = "ON"
        page.footer.button_text.e2.name = "RATE"
        page.footer.button_text.e2.value = misc_util.trim(tostring(state.pages.slice.lfo:get('period')), 5)
    else
        -- When LFO is disabled, E2 controls position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "POS"
        page.footer.button_text.e2.value = misc_util.trim(tostring(params:get(PARAM_ID_POS)), 5)
    end

    page.footer.button_text.k3.value = string.upper(state.pages.slice.lfo:get("shape"))
    page.footer.button_text.e3.value = params:get(PARAM_ID_LENGTH)

    page.footer:render()
end

local function add_params(state)
    params:add_separator("SLICE", page_name)
    params:add_binary(PARAM_ID_LFO_ENABLED, "LFO enabled", "toggle", 0)
    params:add_option(PARAM_ID_LFO_SHAPE, "LFO shape", LFO_SHAPES, 1)
    local default_rate_index = 20
    local default_rate = lfo_util.lfo_period_values[default_rate_index]
    params:add_option(PARAM_ID_LFO_RATE, "LFO rate", lfo_util.lfo_period_labels, default_rate)
    params:add_control(PARAM_ID_POS, "position", controlspec_pos)
    params:set_action(PARAM_ID_POS, action_pos)

    params:add_control(PARAM_ID_LENGTH, "length", controlspec_length)
    params:set_action(PARAM_ID_LENGTH, action_length)
end

function page:initialize(state)
    local a = perlin:noise(0.1, 1.0)
    local b = perlin:noise(0.1, 3.0)
    print('perlin noise a', a)
    print('perlin noise b', b)
    add_params(state)
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "SLICE",
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
                name = "LFO",
                value = "",
            },
            k3 = {
                name = "SHAPE",
                value = "",
            },
            e2 = {
                name = "POS",
                value = state.pages.slice.seek.start,
            },
            e3 = {
                name = "LEN",
                value = state.pages.slice.seek.width,
            },
        },
        font_face = state.footer_font,
    })

    -- lfo
    state.pages.slice.lfo = _lfos:add {
        shape = 'up',
        min = POSITION_MIN,
        max = POSITION_MAX,
        depth = 1.0, -- 0.0 to 1.0
        mode = 'clocked',
        period = DEFAULT_PERIOD,
        phase = 0,
        ppqn = 24,
        action = function(scaled, raw)
            params:set(PARAM_ID_POS, controlspec_pos:map(scaled), false)
            update_rows()
            -- update_enabled_section(state)
        end
    }
    state.pages.slice.lfo:set('reset_target', 'mid: rising')
end

return page
