local Page = include("bits/lib/pages/Page")
local Window = include("bits/lib/graphics/Window")
local PitchGraph = include("bits/lib/graphics/PitchGraph")
local page_name = "Pitch"
local debug = include("bits/lib/util/debug")
local state_util = include("bits/lib/util/state")
local misc_util = include("bits/lib/util/misc")
local page

local function calculate_rates(state)
    for i = 0, 5 do
        local radians = i / 6 * math.pi * 2 * 2.67 -- manually tuned, 2.7 is also nice

        -- here pitch is not a meaningful value yet; it's _some_ ratio of the normal playback pitch, with 0 = original pitch
        local pitch = math.sin(radians) * state.pages.pitch.rate_spread

        -- double to increase range, we'll use half the range for reverse playback (-4 < pitch < 0) and half for forward (0 < pitch < 4)
        pitch = pitch * 2
        pitch = pitch + state.pages.pitch.rate_center

        if state.pages.pitch.quantize then
            -- quantize to integers between -2 and 2,because 2^[-2|-1|0|1|2] gives quantized rates from 0.25 to 4
            pitch = math.floor(pitch + 0.5)
        end

        rate = util.clamp(2 ^ pitch, 1/8, 8)

        
        if page.pitch_graph.voice_dir[i] == PLAYBACK_DIRECTION[2] then
            -- reverse playback
            rate = -rate
        end
        state.rates[i + 1] = rate
        -- graph is linear while rate is exponential 
        page.pitch_graph.voice_pos[i] = -math.log(math.abs(rate), 2)
    end
    for i = 1, 6 do
        softcut.rate(i, state.rates[i])
    end
end

local function update_playback_dir(state)
    if state.pages.pitch.direction == PLAYBACK_DIRECTION[1] then
        print(PLAYBACK_DIRECTION[1])
        for i = 1,6 do
            page.pitch_graph.voice_dir[i] = PLAYBACK_DIRECTION[1]
        end
    elseif state.pages.pitch.direction == PLAYBACK_DIRECTION[2] then
        print(PLAYBACK_DIRECTION[2])
        for i = 1,6 do
            page.pitch_graph.voice_dir[i] = PLAYBACK_DIRECTION[2]
        end
    else
        print(PLAYBACK_DIRECTION[3])
        for i = 1,5,2 do
            page.pitch_graph.voice_dir[i] = PLAYBACK_DIRECTION[1]
        end
        for i = 2,6,2 do
            page.pitch_graph.voice_dir[i] = PLAYBACK_DIRECTION[2]
        end
    end
    calculate_rates(state)
end

local function cycle_direction(state)
    local current = state.pages.pitch.direction

    -- Find index of current value
    local next_index = 1
    for i, v in ipairs(PLAYBACK_DIRECTION) do
        if v == current then
            next_index = i + 1
            break
        end
    end

    -- Wrap around if we're past the last index
    if next_index > #PLAYBACK_DIRECTION then
        next_index = 1
    end
    state.pages.pitch.direction = PLAYBACK_DIRECTION[next_index]
    update_playback_dir(state)

end


local function toggle_quantize(state)
    state.pages.pitch.quantize = not state.pages.pitch.quantize
    state.pages.pitch.rate_center = math.floor(state.pages.pitch.rate_center + 0.5)
    calculate_rates(state)
end


local function adjust_center(state, d)
    local step = state.pages.pitch.quantize and 1 or 1/50
    state_util.adjust_param(state.pages.pitch, 'rate_center', d*step, 1, -3, 3, false)
    calculate_rates(state)
    page.pitch_graph.center = state.pages.pitch.rate_center * -2
end

local function adjust_spread(state, d)
    state_util.adjust_param(state.pages.pitch, 'rate_spread', d / 5, 1, 0, 2, false)
    calculate_rates(state)
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
    k3_off = toggle_quantize,
})

function page:render(state)
    page.window:render()
    page.footer.button_text.k2.value = state.pages.pitch.direction
    page.footer.button_text.k3.value = state.pages.pitch.quantize and "ON" or "OFF"
    page.footer.button_text.e2.value = misc_util.trim(tostring(state.pages.pitch.rate_center), 5)
    page.footer.button_text.e3.value = misc_util.trim(tostring(state.pages.pitch.rate_spread), 5)

    page.pitch_graph:render()
    page.footer:render()
end

function page:initialize(state)
    page.window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "PITCH",
        font_face = state.title_font,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })

    page.pitch_graph = PitchGraph:new()
    update_playback_dir(state)
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "DIR",
                value = "BI",
            },
            k3 = {
                name = "QUANT",
                value = "12", -- [N] SEMITONES, OCTAVES, FREE
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
        font_face = state.footer_font
    })
end

return page
