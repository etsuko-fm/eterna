local Page = include("bits/lib/pages/Page")
local page_name = "ScanLfo"
local Window = include("bits/lib/graphics/Window")
local Slider = include("bits/lib/graphics/Slider")
local MetaMixerGraphic = include("bits/lib/graphics/MetaMixerGraphic")
local gaussian = include("bits/lib/util/gaussian")
local state_util = include("bits/lib/util/state")
local misc_util = include("bits/lib/util/misc")
local lfo_util = include("bits/lib/util/lfo")
local bars
local window

local graph_x = 36 -- (128 - graph_width) / 2
local graph_y = 40

local function map_sigma(state, v)
    return util.explin(state.pages.metamixer.sigma_min, state.pages.metamixer.sigma_max, 0, 1, v)
end

local function adjust_sigma(state, d)
    local k = (10 ^ math.log(state.pages.metamixer.sigma, 10)) / 25
    state_util.adjust_param(state.pages.metamixer, 'sigma', d, k, state.pages.metamixer.sigma_min, state.pages.metamixer.sigma_max, false)
    state.levels = gaussian.calculate_gaussian_levels(state.pages.metamixer.scan_val, state.pages.metamixer.sigma)
    for i = 1, 6 do
        softcut.level(i, state.levels[i])
    end
end

local function toggle_shape(state)
    local shapes = { "sine", "up", "down", "random" }
    lfo_util.toggle_shape(state.pages.metamixer.lfo, shapes)
end

local function toggle_lfo(state)
    if state.pages.metamixer.lfo:get("enabled") == 1 then
        state.pages.metamixer.lfo:stop()
    else
        state.pages.metamixer.lfo:start()
    end
    state.pages.metamixer.lfo:set('phase', state.pages.metamixer.scan_val)
end

local function gaussian_scan(state, d)
    state_util.adjust_param(state.pages.metamixer, 'scan_val', d, 1 / 60, 0, 1, true)
    -- h_slider.val = state.scan_val
    state.levels = gaussian.calculate_gaussian_levels(state.pages.metamixer.scan_val, state.pages.metamixer.sigma)
    for i = 1, 6 do
        softcut.level(i, state.levels[i])
    end
end


local function e2(state, d)
    if state.pages.metamixer.lfo:get("enabled") == 1 then
        lfo_util.adjust_lfo_rate_quant(d, state.pages.metamixer.lfo)
    else
        gaussian_scan(state, d)
    end
end


local function e3(state, d)
    adjust_sigma(state, d)
end


local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = e2,
    e3 = e3,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = toggle_lfo,
    k3_on = nil,
    k3_off = toggle_shape,
})

function page:render(state)
    -- todo: this should be a graphic component, the entire thing belongs together
    state.levels = gaussian.calculate_gaussian_levels(state.pages.metamixer.scan_val, state.pages.metamixer.sigma)
    bars.levels = state.levels
    screen.clear()
    bars:render()

    window:render()
    if state.pages.metamixer.lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        page.footer.button_text.k2.value = "ON"
        page.footer.button_text.e2.name = "SPEED"
        page.footer.button_text.e2.value = misc_util.trim(tostring(state.pages.metamixer.lfo:get('period')), 5)
    else
        -- When LFO is disabled, E2 controls scan position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "POS"
        page.footer.button_text.e2.value = misc_util.trim(tostring(state.pages.metamixer.scan_val), 5)
    end
    page.footer.button_text.k3.value = string.upper(state.pages.metamixer.lfo:get("shape"))
    page.footer.button_text.e3.value = misc_util.trim(tostring(map_sigma(state, state.pages.metamixer.sigma)), 5)

    page.footer:render()
end

function page:initialize(state)
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "META MIXER",
        font_face = state.title_font,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    -- graphics
    bars = MetaMixerGraphic:new({
        x = graph_x,
        y = graph_y,
        bar_width = 6,
        max_bar_height = 24,
        num_bars = 6,
        brightness = 15,
    })

    -- initialize softcut levels according to mixer levels
    adjust_sigma(state, 0)
    bars.levels = state.levels

    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "LFO",
                value = "",
            },
            k3 = {
                name = "SHAPE",
                value = "Sine",
            },
            e2 = {
                name = "POS",
                value = "",
            },
            e3 = {
                name = "AMP",
                value = "",
            },
        },
        font_face = state.footer_font,
    })

    -- lfo
    state.pages.metamixer.lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'free',
        period = state.pages.metamixer.lfo_period,
        phase = 0,
        action = function(scaled, raw)
            state.pages.metamixer.scan_val = scaled
            bars.scan_val = scaled
            state.levels = gaussian.calculate_gaussian_levels(state.pages.metamixer.scan_val, state.pages.metamixer.sigma)
            for i = 1, 6 do
                softcut.level(i, state.levels[i])
            end
        end
    }
    state.pages.metamixer.lfo:set('reset_target', 'mid: rising')
end

return page
