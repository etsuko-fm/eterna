local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local PanningGraphic = include("bits/lib/graphics/PanningGraphic")
local state_util = include("bits/lib/util/state")
local misc_util = include("bits/lib/util/misc")
local lfo_util = include("bits/lib/util/lfo")

local page_name = "PANNING"
local window

local panning_graphic

-- width of the panning bars
local PANNING_RANGE_PIXELS = 32

local PARAM_ID_LFO_ENABLED = "panning_lfo_enabled"
local PARAM_ID_LFO_SHAPE = "panning_lfo_shape"
local LFO_SHAPES = { "sine", "up", "down", "random" }

local function calculate_pan_positions(state)
    for i = 0, 5 do
        local angle = (i / 6) * (math.pi * 2) + state.pages.panning.twist -- Divide full circle into 6 parts
        state.pages.panning.pan_positions[i + 1] = state.pages.panning.spread / PANNING_RANGE_PIXELS * math.cos(angle)
    end
    for i = 1, 6 do
        softcut.pan(i, state.pages.panning.pan_positions[i])
    end
end

local function adjust_spread(state, d)
    state_util.adjust_param(state.pages.panning, 'spread', d, 1, 1, PANNING_RANGE_PIXELS, false)
    calculate_pan_positions(state)
end

local function adjust_twist(state, d)
    state_util.adjust_param(state.pages.panning, 'twist', d / 10, 1, 0, math.pi * 2, true)
    calculate_pan_positions(state)
end


local function toggle_lfo(state)
    params:set(PARAM_ID_LFO_ENABLED, 1 - state.pages.panning.lfo:get("enabled"), false)
end

local function toggle_shape(state)
    local index = params:get(PARAM_ID_LFO_SHAPE)
    local next_index = (index % #LFO_SHAPES) + 1
    params:set(PARAM_ID_LFO_SHAPE, next_index, false)
end


local function e2(state, d)
    if state.pages.panning.lfo:get("enabled") == 1 then
        lfo_util.adjust_lfo_rate_quant(d, state.pages.panning.lfo)
    else
        adjust_twist(state, d)
    end
end

local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = e2,
    e3 = adjust_spread,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = toggle_lfo,
    k3_on = nil,
    k3_off = toggle_shape,
})

function page:render(state)
    window:render()
    panning_graphic.w = state.pages.panning.spread
    panning_graphic.twist = state.pages.panning.twist
    panning_graphic:render()
    if state.pages.panning.lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        page.footer.button_text.k2.value = "ON"
        page.footer.button_text.e2.name = "RATE"
        page.footer.button_text.e2.value = misc_util.trim(tostring(state.pages.panning.lfo:get('period')), 5)
    else
        -- When LFO is disabled, E2 controls pan position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "TWIST"
        page.footer.button_text.e2.value = misc_util.trim(tostring(state.pages.panning.twist), 5)
    end
    page.footer.button_text.e3.value = misc_util.trim(tostring(state.pages.panning.spread), 5)
    page.footer.button_text.k3.value = string.upper(state.pages.panning.lfo:get("shape"))
    page.footer:render()
end

local function add_params(state)
    params:add_separator("PANNING", page_name)
    params:add_binary(PARAM_ID_LFO_ENABLED, "LFO enabled", "toggle", 0)
    params:set_action(PARAM_ID_LFO_ENABLED,
        function()
            if state.pages.panning.lfo:get("enabled") == 1 then
                state.pages.panning.lfo:stop()
            else
                state.pages.panning.lfo:start()
            end
        end
    )

    params:add_option(PARAM_ID_LFO_SHAPE, "LFO shape", LFO_SHAPES, 1)
    params:set_action(PARAM_ID_LFO_SHAPE, function() state.pages.panning.lfo:set('shape', params:string(PARAM_ID_LFO_SHAPE)) end)

end

function page:initialize(state)
    add_params(state)
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "STEREO FIELD",
        font_face = state.title_font,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    -- graphics
    panning_graphic = PanningGraphic:new({
        w = state.pages.panning.spread,
    })
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
                name = "TWIST",
                value = "",
            },
            e3 = {
                name = "WIDTH",
                value = "",
            },
        },
        font_face = state.footer_font,
    })
    -- lfo
    state.pages.panning.lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'free',
        period = state.pages.panning.default_lfo_period,
        phase = 0,
        action = function(scaled, raw)
            state.pages.panning.twist = scaled * math.pi * 2
            panning_graphic.twist = state.pages.panning.twist
            calculate_pan_positions(state)
        end
    }
    state.pages.panning.lfo:set('reset_target', 'mid: rising')
end

return page
