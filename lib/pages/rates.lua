local PitchGraph = include("symbiosis/lib/graphics/PitchGraph")
local page_name = "Playback"
local page

local function calculate_rates()
    -- recalculate playback rates, taking into account quantize, spread, center, direction
    for i = 0, 5 do
        -- map 6 values as equally spread angles on a (virtual) circle, by using radians (fraction * 2PI)
        local radians = i / 6 * math.pi * 2

        -- this extra factor increases the range; values beyond 2PI are effectively treated as `% 2PI` by sin(),
        -- because sin() is a periodic function with a period of 2PI
        -- this extension affects the way the playback rates are spread over the six voices
        local extend = 2 --2.67 -- manually tuned, 2.7 is also nice

        -- here pitch is still a linear value, representing steps on the slider
        local pitch = math.sin(radians * extend) * params:get(ID_RATES_SPREAD)

        -- double to increase range, we'll use half the range for reverse playback (-4 < pitch < 0) and half for forward (0 < pitch < 4)
        pitch = pitch + params:get(ID_RATES_CENTER)

        -- quantize to integers; between -2 and 2, because 2^[-2|-1|0|1|2] gives quantized rates from 0.25 to 4
        pitch = math.floor(pitch + 0.5)

        -- these correspond to the octaves;
        -- 1 = normal, 1/2 = -12, -1/4 = -24, -1/8 = -36
        local rate
        if RANGE_TABLE[params:get(ID_RATES_RANGE)] == THREE_OCTAVES then
            rate = util.clamp(2 ^ pitch, .5, 2)
        else
            rate = util.clamp(2 ^ pitch, .25, 4)
        end

        local voice = i + 1
        if params:get(get_voice_dir_param_id(voice)) == 2 then -- todo: lookuptable 2>rev, 1>fwd
            rate = -rate
        end
        engine.rate(voice-1, rate)
        -- graph is linear while rate is exponential 
        page.pitch_graph.voice_pos[i] = -math.log(math.abs(rate), 2)
    end
end

local function update_playback_dir(new_val)
    -- update graphics
    if PLAYBACK_TABLE[new_val] == FWD then
        -- all forward
        for voice = 1, 6 do
            page.pitch_graph.voice_dir[voice] = FWD
            params:set(get_voice_dir_param_id(voice), 1)
        end
    elseif PLAYBACK_TABLE[new_val] == REV then
        -- all reverse
        for voice = 1, 6 do
            page.pitch_graph.voice_dir[voice] = REV
            params:set(get_voice_dir_param_id(voice), 2)
        end
    else
        -- alternate forward/reverse
        for voice = 1, 5, 2 do
            page.pitch_graph.voice_dir[voice] = FWD
            params:set(get_voice_dir_param_id(voice), 1)
        end
        for voice = 2, 6, 2 do
            page.pitch_graph.voice_dir[voice] = REV
            params:set(get_voice_dir_param_id(voice), 2)
        end
    end
    calculate_rates()
end

local function add_params()
    params:set_action(ID_RATES_RANGE, action_range)
    params:set_action(ID_RATES_CENTER, calculate_rates)
    params:set_action(ID_RATES_SPREAD, calculate_rates)
    params:set_action(ID_RATES_DIRECTION, update_playback_dir)
end

function action_range(v)
    if RANGE_TABLE[v] == THREE_OCTAVES then
        controlspec_rates_center.minval = -1
        controlspec_rates_center.maxval = 1
    else
        controlspec_rates_center.minval = -2
        controlspec_rates_center.maxval = 2
    end
    calculate_rates()
end

local function cycle_direction()
    local new = util.wrap(params:get(ID_RATES_DIRECTION) + 1, 1, 3)
    params:set(ID_RATES_DIRECTION, new)
end


local function toggle_range()
    local old = params:get(ID_RATES_RANGE)
    local new = util.wrap(old + 1, 1, #RANGE_TABLE)
    params:set(ID_RATES_RANGE, new)
end

local function adjust_center(d)
    params:set(ID_RATES_CENTER, params:get(ID_RATES_CENTER) + d * controlspec_rates_center.quantum, false)
    page.pitch_graph.center = params:get(ID_RATES_CENTER) * -2 -- todo: why *-2?
end

local function adjust_spread(d)
    local p = ID_RATES_SPREAD
    params:set(p, params:get(p) + d * controlspec_rates_spread.quantum)
end

page = Page:create({
    name = page_name,
    e2 = adjust_center,
    e3 = adjust_spread,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = cycle_direction,
    k3_on = nil,
    k3_off = toggle_range,
})

function page:render()
    page.window:render()
    page.footer.button_text.k2.value = PLAYBACK_TABLE[params:get(ID_RATES_DIRECTION)]
    page.footer.button_text.k3.value = RANGE_TABLE[params:get(ID_RATES_RANGE)]

    page.footer.button_text.e2.value = misc_util.trim(tostring(
        params:get(ID_RATES_CENTER)
    ), 5)

    page.footer.button_text.e3.value = misc_util.trim(tostring(
        params:get(ID_RATES_SPREAD)
    ), 5)

    page.pitch_graph:render()
    page.footer:render()
end

function page:initialize()
    add_params()
    page.window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "PLAYBACK RATES",
        font_face = TITLE_FONT,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })

    page.pitch_graph = PitchGraph:new()
    update_playback_dir(1)
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "DIR",
                value = "BI",
            },
            k3 = {
                name = "RANGE",
                value = "3 OCT",
            },
            e2 = {
                name = "CNTR",
                value = "0 OCT",
            },
            e3 = {
                name = "SPRD",
                value = "",
            },
        },
        font_face = FOOTER_FONT
    })
end

return page
