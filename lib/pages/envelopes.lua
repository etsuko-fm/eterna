local EnvGraphic = include("symbiosis/lib/graphics/EnvGraphic")

local page_name = "ENVELOPES"
local envelope_graphic

local function adjust_shape(d)
    misc_util.adjust_param(d, ID_ENVELOPES_SHAPE, controlspec_env_shape)
end

local function adjust_time(d)
    misc_util.adjust_param(d, ID_ENVELOPES_TIME, controlspec_env_time)
end

local function toggle_curve()
    misc_util.cycle_param(ID_ENVELOPES_CURVE, ENVELOPE_CURVES)
end

local function toggle_mod()
    local p = ID_ENVELOPES_MOD
    local curr = params:get(p)
    params:set(p, util.wrap(curr + 1, 1, #ENVELOPE_MOD_OPTIONS))
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
    if ENVELOPE_MOD_OPTIONS[params:get(ID_ENVELOPES_MOD)] == "OFF" then
        -- only modify envelopes if env modulation is off; otherwise delegated to sequencer
        local attack = get_attack(time, shape)
        local decay = get_decay(time, shape)
        sym.each_voice_attack(attack)
        sym.each_voice_decay(decay)
    end
end

local function action_time(time)
    local shape = params:get(ID_ENVELOPES_SHAPE)
    recalculate_time(time, shape)
end


local function action_mod(v)
    local shape = params:get(ID_ENVELOPES_SHAPE)
    local time = params:get(ID_ENVELOPES_TIME)
    local val = ENVELOPE_MOD_OPTIONS[v] == "LPG" and 1 or 0
    sym.each_voice_enable_lpg(val)
    recalculate_time(time, shape)
end

local function action_shape(shape)
    local time = params:get(ID_ENVELOPES_TIME)
    recalculate_time(time, shape)
end

local function action_curve(idx)
    sym.each_voice_env_curve(ENVELOPE_CURVES[idx])
end

local function add_params()
    params:set_action(ID_ENVELOPES_TIME, action_time)
    params:set_action(ID_ENVELOPES_SHAPE, action_shape)
    params:set_action(ID_ENVELOPES_CURVE, action_curve)
    params:set_action(ID_ENVELOPES_MOD, action_mod)
end

function page:render()
    self.window:render()

    local time = params:get(ID_ENVELOPES_TIME)
    local shape = params:get(ID_ENVELOPES_SHAPE)
    local curve = ENVELOPE_NAMES[params:get(ID_ENVELOPES_CURVE)]
    local mod = params:get(ID_ENVELOPES_MOD)

    envelope_graphic.time = misc_util.explin(ENV_TIME_MIN, ENV_TIME_MAX, 0.001, 1, time, 4)
    envelope_graphic.shape = shape
    envelope_graphic.curve = curve
    envelope_graphic.mod = ENVELOPE_MOD_OPTIONS[mod] ~= "OFF" and 0.5 or 0

    envelope_graphic:render()
    page.footer.button_text.k2.value = ENVELOPE_MOD_OPTIONS[mod]
    page.footer.button_text.k3.value = curve
    page.footer.button_text.e2.value = misc_util.trim(tostring(time), 5)
    page.footer.button_text.e3.value = misc_util.trim(tostring(shape), 5)
    page.footer:render()
end


function page:initialize()
    add_params()
    self.window = Window:new({ title = page_name, font_face = TITLE_FONT })

    -- graphics
    envelope_graphic = EnvGraphic:new()
    page.footer = Footer:new({
        button_text = {
            k2 = { name = "MOD", value = "" },
            k3 = { name = "CURVE", value = "" },
            e2 = { name = "TIME", value = "" },
            e3 = { name = "SHAPE", value = "" },
        },
        font_face = FOOTER_FONT,
    })
end

return page
