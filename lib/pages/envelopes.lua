local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
-- local EnvGraphic = include("bits/lib/graphics/EnvGraphic")
local misc_util = include("bits/lib/util/misc")

local page_name = "ENVELOPES"
local window
local ENVELOPES_GRAPHIC



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

local function adjust_attack(d)
    local new_val = params:get(ID_ENVELOPES_ATTACK) + d * controlspec_env_attack.quantum
    params:set(ID_ENVELOPES_ATTACK, new_val, false)
end

local function adjust_decay(d)
    local new_val = params:get(ID_ENVELOPES_DECAY) + d * controlspec_env_decay.quantum
    params:set(ID_ENVELOPES_DECAY, new_val, false)
end

local function toggle_curve()
    local p = ID_ENVELOPES_CURVE
    local curr = params:get(p)
    params:set(p, util.wrap(curr+1, 1, #ENVELOPE_CURVES))
end

local function toggle_enable()
    local p = ID_ENVELOPES_ENABLE
    params:set(p, 1 - params:get(p))
end

local page = Page:create({
    name = page_name,
    e2 = adjust_attack,
    e3 = adjust_decay,
    k2_off = toggle_enable,
    k3_off = toggle_curve,
})

local function action_attack(v)
    for i=0,5 do
        engine.attack(i,v)
    end
end

local function action_decay(v)
    for i=0,5 do
        engine.decay(i,v)
    end
end

local function action_enable(v)
    for i=0,5 do
        engine.enable_env(i, v)
    end
end

local function action_filter_env(v)
    for i=0,5 do
        engine.filter_env(i,v)
    end
end
local function action_curve(idx)
    for voice=0,5 do
        engine.env_curve(voice, ENVELOPE_CURVES[idx])
    end
end
local function add_params()
    params:set_action(ID_ENVELOPES_ATTACK, action_attack)
    params:set_action(ID_ENVELOPES_DECAY, action_decay)
    params:set_action(ID_ENVELOPES_FILTER_ENV, action_filter_env)
    params:set_action(ID_ENVELOPES_CURVE, action_curve)
    params:set_action(ID_ENVELOPES_ENABLE, action_enable)
end

function page:render()
    window:render()
    local attack = params:get(ID_ENVELOPES_ATTACK)
    local decay = params:get(ID_ENVELOPES_DECAY)
    local curve = ENVELOPE_NAMES[params:get(ID_ENVELOPES_CURVE)]
    local enabled = params:get(ID_ENVELOPES_ENABLE) == 1 and "ON" or "OFF"
    -- ENVELOPES_GRAPHIC:render()
    page.footer.button_text.k2.value = enabled
    page.footer.button_text.k3.value = curve
    page.footer.button_text.e2.value = misc_util.trim(tostring(attack), 5)
    page.footer.button_text.e3.value = misc_util.trim(tostring(decay), 5)
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
    -- ENVELOPES_GRAPHIC = EnvGraphic:new()
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "ENABLE",
                value = "",
            },
            k3 = {
                name = "CURVE",
                value = "",
            },
            e2 = {
                name = "ATTACK",
                value = "",
            },
            e3 = {
                name = "DECAY",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })
end

return page
