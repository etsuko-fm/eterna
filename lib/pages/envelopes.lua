local EnvGraphic = include("bits/lib/graphics/EnvGraphic")

local page_name = "ENVELOPES"
local window
local envelope_graphic

-- local function calculate_env_positions()
--     local DECAY = params:get(ID_ENVELOPES_DECAY)
--     local ATTACK = params:get(ID_ENVELOPES_ATTACK)
--     for i = 0, 5 do
--         local voice = i + 1
--         local angle = (DECAY + i / 6) * (math.pi * 2) -- Divide the range of radians into 6 equal parts, add offset
--         local pan =  ATTACK * math.cos(angle)
--         engine.pan(i, pan)
--     end
-- end

local function adjust_shape(d)
    local p = ID_ENVELOPES_SHAPE
    local new_val = params:get_raw(p) + d * controlspec_env_shape.quantum
    params:set_raw(p, new_val)
end

local function adjust_time(d)
    local p = ID_ENVELOPES_TIME
    local new_val = params:get_raw(p) + d * controlspec_env_time.quantum
    params:set_raw(p, new_val)
end

local function toggle_curve()
    local p = ID_ENVELOPES_CURVE
    local curr = params:get(p)
    params:set(p, util.wrap(curr + 1, 1, #ENVELOPE_CURVES))
end

local function toggle_mod()
    local p = ID_ENVELOPES_MOD
    params:set(p, 1 - params:get(p))
end

local page = Page:create({
    name = page_name,
    e2 = adjust_time,
    e3 = adjust_shape,
    k2_off = toggle_mod,
    k3_off = toggle_curve,
})

function get_attack(time, shape)
    return time * shape
end

function get_decay(time, shape)
    return time * (1-shape)
end

local function recalculate_time(time, shape)
    if params:get(ID_ENVELOPES_MOD) == 0 then
        -- only modify env if global mod is off
        local attack = get_attack(time, shape)
        local decay = get_decay(time, shape)
        for i = 0, 5 do
            engine.attack(i, attack)
            engine.decay(i, decay)
        end
    end
end

local function action_time(time)
    local shape = params:get(ID_ENVELOPES_SHAPE)
    recalculate_time(time, shape)
end


local function action_mod(v)
    local shape = params:get(ID_ENVELOPES_SHAPE)
    local time = params:get(ID_ENVELOPES_TIME)
    recalculate_time(time, shape)
end

local function action_shape(shape)
    local time = params:get(ID_ENVELOPES_TIME)
    recalculate_time(time, shape)
    -- for i = 0, 5 do
    --     engine.filter_env(i, v)
    -- end
end
local function action_curve(idx)
    for voice = 0, 5 do
        engine.env_curve(voice, ENVELOPE_CURVES[idx])
    end
end
local function add_params()
    params:set_action(ID_ENVELOPES_TIME, action_time)
    params:set_action(ID_ENVELOPES_SHAPE, action_shape)
    params:set_action(ID_ENVELOPES_CURVE, action_curve)
    params:set_action(ID_ENVELOPES_MOD, action_mod)
end

function page:render()
    window:render()

    local time = params:get(ID_ENVELOPES_TIME)
    local shape = params:get(ID_ENVELOPES_SHAPE)
    local curve = ENVELOPE_NAMES[params:get(ID_ENVELOPES_CURVE)]
    local mod = params:get(ID_ENVELOPES_MOD) == 1 and "ON" or "OFF"

    envelope_graphic.time = util.explin(ENV_TIME_MIN, ENV_TIME_MAX, 0, 1, time)
    envelope_graphic.shape = shape
    envelope_graphic.curve = curve

    envelope_graphic:render()
    page.footer.button_text.k2.value = mod
    page.footer.button_text.k3.value = curve
    page.footer.button_text.e2.value = misc_util.trim(tostring(time), 5)
    page.footer.button_text.e3.value = misc_util.trim(tostring(shape), 5)
    page.footer:render()
end


function page:initialize()
    add_params()
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = "ENVELOPES",
        font_face = TITLE_FONT,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })


    -- graphics
    envelope_graphic = EnvGraphic:new()
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "MOD",
                value = "",
            },
            k3 = {
                name = "CURVE",
                value = "",
            },
            e2 = {
                name = "TIME",
                value = "",
            },
            e3 = {
                name = "SHAPE",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })
end

return page
