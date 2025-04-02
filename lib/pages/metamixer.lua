local Page = include("bits/lib/pages/Page")
local page_name = "ScanLfo"
local Window = include("bits/lib/graphics/Window")
local Slider = include("bits/lib/graphics/Slider")
local GaussianBars = include("bits/lib/graphics/GaussianBars")
local gaussian = include("bits/lib/util/gaussian")
local state_util = include("bits/lib/util/state")
local misc_util = include("bits/lib/util/misc")
local bars
local window

local function map_sigma(state, v)
    return util.explin(state.sigma_min, state.sigma_max, 0, 1, v)
end

local function adjust_sigma(state, d)
    local k = (10 ^ math.log(state.sigma, 10)) / 25
    state_util.adjust_param(state, 'sigma', d, k, state.sigma_min, state.sigma_max, false)
    update_vslider_val(state)
    state.levels = gaussian.calculate_gaussian_levels(state.scan_val, state.sigma)
    for i = 1, 6 do
        softcut.level(i, state.levels[i])
    end
end

local function toggle_shape(state)
    shapes = {"sine", "up", "down", "square", "random"}
    local shape = state.metamixer_lfo:get('shape')
    local new_shape = "sine"
    if shape == "sine" then
        new_shape = "up"
    elseif shape == "up" then
        new_shape = "down"
    elseif shape == "down" then
        new_shape = "random"
    end
    state.metamixer_lfo:set('shape', new_shape)
end


local function toggle_lfo(state)
    if state.metamixer_lfo:get("enabled") == 1 then
        state.metamixer_lfo:stop()
    else
        state.metamixer_lfo:start()
    end
    state.metamixer_lfo:set('phase', state.scan_val)
end


local function adjust_lfo_rate(state, d)
    local k = (10 ^ math.log(state.metamixer_lfo:get('period'), 10)) / 50
    local min = 0.2
    local max = 256

    new_val = state.metamixer_lfo:get('period') + (d * k)
    if new_val < min then
        new_val = min
    end
    if new_val > max then
        new_val = max
    end
    state.metamixer_lfo:set('period', new_val)
    state.metamixer_lfo_period = new_val
end

local function gaussian_scan(state, d)
    state_util.adjust_param(state, 'scan_val', d, 1 / 60, 0, 1, true)
    h_slider.val = state.scan_val
    state.levels = gaussian.calculate_gaussian_levels(state.scan_val, state.sigma)
    for i = 1, 6 do
        softcut.level(i, state.levels[i])
    end
end


local function e2(state, d)
    if state.metamixer_lfo:get("enabled") == 1 then
        adjust_lfo_rate(state, d)
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

function update_vslider_val(state)
    v_slider.val = util.explin(state.sigma_min, state.sigma_max, 0, 1, state.sigma)
end

function page:render(state)
    -- todo: this should be a graphic component, the entire thing belongs together
    h_slider.val = state.scan_val
    update_vslider_val(state)
    state.levels = gaussian.calculate_gaussian_levels(state.scan_val, state.sigma)
    bars.levels = state.levels
    screen.clear()
    bars:render()
    h_slider:render()
    v_slider:render()

    window:render()
    if state.metamixer_lfo:get("enabled") == 1 then
        -- When LFO is disabled, E2 controls LFO rate
        page.footer.button_text.k2.value = "ON"
        page.footer.button_text.e2.name = "SPEED"
        page.footer.button_text.e2.value = misc_util.trim(tostring(state.metamixer_lfo:get('period')), 5)    
    else
        -- When LFO is disabled, E2 controls scan position
        page.footer.button_text.k2.value = "OFF"
        page.footer.button_text.e2.name = "POS"
        page.footer.button_text.e2.value = misc_util.trim(tostring(state.scan_val), 5)
    end
    page.footer.button_text.k3.value = string.upper(state.metamixer_lfo:get("shape"))
    page.footer.button_text.e3.value = misc_util.trim(tostring(map_sigma(state, state.sigma)), 5)

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
    bars = GaussianBars:new({
        x = state.graph_x,
        y = state.graph_y,
        bar_width = state.bar_width,
        max_bar_height = state.bar_height,
        num_bars = state.num_bars,
        brightness = 15,
    })
    h_slider = Slider:new({
        direction = 'HORIZONTAL',
        x = state.graph_x,
        y = state.graph_y + 3,
        w = state.graph_width,
        h = 3,
        dash_size = 1,
        dash_fill = 5,
        val = state.scan_val,
    })
    v_slider = Slider:new({
        direction = 'VERTICAL',
        x = state.graph_x + state.graph_width + 3,
        y = state.graph_y - state.bar_height,
        w = 3,
        h = state.bar_height,
        dash_size = 1,
        val = map_sigma(state, state.sigma),
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
    state.metamixer_lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'free',
        period = state.metamixer_lfo_period,
        phase = 0,
        action = function(scaled, raw)
            state.scan_val = scaled
            bars.scan_val = scaled
            state.levels = gaussian.calculate_gaussian_levels(state.scan_val, state.sigma)
            for i = 1, 6 do
                softcut.level(i, state.levels[i])
            end
        end
    }
    state.metamixer_lfo:set('reset_target', 'mid: rising')
end

return page
