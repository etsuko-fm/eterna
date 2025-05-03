local Page = include("bits/lib/pages/Page")
local Window = include("bits/lib/graphics/Window")
local state_util = include("bits/lib/util/state")
local GridGraphic = include("bits/lib/graphics/Grid")
local Footer = include("bits/lib/graphics/Footer")
local misc_util = include("bits/lib/util/misc")
local lfo_util = include("bits/lib/util/lfo")

local page_name = "Slice"
local window
local grid_graphic
local DEFAULT_PERIOD = 6


local function update_segment_lengths(state)
    for i = 1, 6 do
        if state.loop_sections[i][2] - state.loop_sections[i][1] > state.max_sample_length then
            -- no need to protect for empty buffer, as it's shortening it only
            state.loop_sections[i][2] = state.loop_sections[i][1] + state.max_sample_length
            softcut.loop_end(i, state.loop_sections[i][2])
        end
    end
    state.events['event_randomize_softcut'] = true
end


local function update_grid(state)
    grid_graphic.start_active = state.pages.slice.seek.start
    grid_graphic.end_active = state.pages.slice.seek.start + state.pages.slice.seek.width

    local current_length = math.min(state.sample_length, state.max_sample_length)
    state.pages.slice.enabled_section[1] = ((state.pages.slice.seek.start - 1) / 128) * current_length
    state.pages.slice.enabled_section[2] = math.min(state.pages.slice.enabled_section[1] + (state.pages.slice.seek.width / 128 * current_length),
        state.max_sample_length)

    update_segment_lengths(state)
end

local function seek(state, d)
    local max_start = 129 - state.pages.slice.seek.width
    state_util.adjust_param(state.pages.slice.seek, 'start', d, 1, 1, max_start)
    update_grid(state)
end

local function adjust_width(state, d)
    state_util.adjust_param(state.pages.slice.seek, 'width', d, 1, 1, 129 - state.pages.slice.seek.start)
    local max_start = 129 - state.pages.slice.seek.width
    state.pages.slice.lfo:set('max', max_start)
    update_grid(state)
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
    state.pages.slice.lfo:set('phase', state.pages.slice.seek.start / 128)
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
        seek(state, d)
    end
end


local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = e2,
    e3 = adjust_width,
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
        page.footer.button_text.e2.name = "PERIOD"
        page.footer.button_text.e2.value = misc_util.trim(tostring(state.pages.slice.lfo:get('period')), 5)
    else
        -- When LFO is disabled, E2 controls scan position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "START"
        page.footer.button_text.e2.value = misc_util.trim(tostring(state.pages.slice.seek.start), 5)
    end

    page.footer.button_text.k3.value = string.upper(state.pages.slice.lfo:get("shape"))
    page.footer.button_text.e3.value = state.pages.slice.seek.width

    page.footer:render()
end

function page:initialize(state)
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
    grid_graphic = GridGraphic:new()
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
                name = "SEEK",
                value = state.pages.slice.seek.start,
            },
            e3 = {
                name = "WIDTH",
                value = state.pages.slice.seek.width,
            },
        },
        font_face = state.footer_font,
    })

    -- lfo
    state.pages.slice.lfo = _lfos:add {
        shape = 'up',
        min = 1,
        max = 129 - state.pages.slice.seek.width,
        depth = 1.0, -- 0.0 to 1.0
        mode = 'clocked',
        period = DEFAULT_PERIOD,
        phase = 0,
        ppqn = 24,
        action = function(scaled, raw)
            -- print(scaled)
            state.pages.slice.seek.start = math.floor(scaled + 0.5)
            update_grid(state)
        end
    }
    state.pages.slice.lfo:set('reset_target', 'mid: rising')
end

return page
