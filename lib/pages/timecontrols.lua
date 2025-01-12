local Page = include("bits/lib/pages/Page")
local page_name = "TimeControls"
local max_length_dirty = false


local function adjust_param(state, param, d, mult, min, max)
    local k = (10 ^ math.log(state[param], 10)) / 100
    local fraction = d * k
    if min == nil then min = 0 end
    if max == nil then max = 128 end
    if state[param] + fraction < min then
        state[param] = min
    elseif state[param] + fraction > max then
        state[param] = max
    else
        state[param] = state[param] + fraction
    end
end

local function adjust_size(state, d)
    adjust_param(state, 'max_sample_length', d, 0.001, 0.01, 10)
    max_length_dirty = true
end

local function adjust_fade(state, d)
    adjust_param(state, 'fade_time', d, 0.1)
end


local page = Page:create({
    name = page_name,
    e1 = nil,
    e2 = adjust_size,
    e3 = adjust_fade,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = nil,
    k3_on = nil,
    k3_off = nil,
})

local function update_segment_lengths(state)
    if max_length_dirty == false then return end
    print('updating segments')
    for i = 1, 6 do
        if state.loop_ends[i] - state.loop_starts[i] > state.max_sample_length then
            -- no need to protect for empty buffer, as it's shortening it only
            state.loop_ends[i] = state.loop_starts[i] + state.max_sample_length
            softcut.loop_end(i, state.loop_ends[i])
        end
    end
    print('new length of [1]:' .. state.loop_ends[1] - state.loop_starts[1])
    max_length_dirty = false
end

function page:render(state)
    screen.clear()
    screen.level(15)
    screen.font_size(8)
    screen.move(128 / 8 * 2, 64 / 8 * 3)
    screen.text("max slice")
    screen.move(128 / 8 * 2, 64 / 8 * 5)
    screen.font_size(8)
    screen.text(string.format("%.0f", state.max_sample_length * 1000))

    screen.font_size(8)
    screen.move(128 / 8 * 6, 64 / 8 * 3)
    screen.text_right("fade")
    screen.move(128 / 8 * 6, 64 / 8 * 5)
    screen.font_size(8)
    screen.text_right(string.format("%.1f", state.fade_time))

    screen.update()
    -- if math.random() > .95 then print('rendering time controls') end

    -- update softcut; no need to do it more often than FPS
    for i = 1, 6 do
        softcut.fade_time(i, state.fade_time)
    end

    -- update segments in case max slice length was shortened
    update_segment_lengths(state)
end

function page:initialize(state)
    -- empty
end

return page
