local Page = include("bits/lib/pages/Page")
local page_name = "ScanLfo"
local Window = include("bits/lib/graphics/Window")
local Slider = include("bits/lib/graphics/Slider")
local GaussianBars = include("bits/lib/graphics/GaussianBars")
local gaussian = include("bits/lib/util/gaussian")
local state_util = include("bits/lib/util/state")

local bars
local footer
local window

local function map_sigma(state, v)
    return util.linlin(state.sigma_min, state.sigma_max, 0, 1, v)
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

local function e3(state, d)
    adjust_sigma(state, d)
    footer.active_knob = "e3"
end


local function toggle_lfo(state)
    footer.active_knob = "k2"
    print(state.scan_lfo:get("enabled"))
    if state.scan_lfo:get("enabled") == 1 then
        state.scan_lfo:stop()
    else
        state.scan_lfo:start()
        state.scan_lfo:set('phase', state.scan_val)
    end
end

local function toggle_sync(state)
    state.scan_lfo_sync = not state.scan_lfo_sync
    local new_mode
    if state.scan_lfo_sync then new_mode = "clocked" else new_mode = "free" end
    state.scan_lfo:set('mode', new_mode)
    print('Scan LFO set to ' .. new_mode)
end

local function adjust_lfo_rate(state, d)
    local k = (10 ^ math.log(state.scan_lfo:get('period'), 10)) / 50
    local min = 0.2
    local max = 256

    new_val = state.scan_lfo:get('period') + (d * k)
    if new_val < min then
        new_val = min
    end
    if new_val > max then
        new_val = max
    end
    state.scan_lfo:set('period', new_val)
    state.scan_lfo_period = new_val
    footer.active_knob = "e2"
end

local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = adjust_lfo_rate,
    e3 = e3,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = toggle_lfo,
    k3_on = nil,
    k3_off = toggle_sync,
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
    footer.e2 = string.format("%.2f", state.scan_lfo_period)
    if state.scan_lfo:get("enabled") == 1 then
        footer.k2 = "OFF"
    else
        footer.k2 = "ON"
    end
    footer:render()
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
    bars.levels = state.levels

    footer = Footer:new({ e3 = "Y", k3 = "SYNC", font_face = state.default_font })
    -- lfo
    state.scan_lfo = _lfos:add {
        shape = 'up',
        min = 0,
        max = 1,
        depth = 1,
        mode = 'free',
        period = state.scan_lfo_period,
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
    state.scan_lfo:set('reset_target', 'mid: rising')
end

return page
