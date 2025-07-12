local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local ControlGraphic = include("bits/lib/graphics/ControlGraphic")
local sequence_util = include("bits/lib/util/sequence")
local misc_util = include("bits/lib/util/misc")

local page_name = "SEQUENCE CONTROL"
local window
local control_graphic

local PARAM_ID_SEQUENCE_SPEED = "sequencer_speed"

local function adjust_bpm(d)
    params:set("clock_tempo", clock.get_tempo() + d)
end

local function adjust_step_size(d)
    local p = PARAM_ID_SEQUENCE_SPEED
    local v = params:get(p)
    local new = util.clamp(v + d, 1, #sequence_util.sequence_speeds)
    params:set(p, new)
end

local page = Page:create({
    name = page_name,
    e2 = adjust_bpm,
    e3 = adjust_step_size,
    k2_off = toggle_transport,
    k3_on = toggle_hold_step,
})

local function action_sequence_speed(v)
    -- convert table index of human-readable options to value for clock.sync
    -- calls global function defined on sequencer page
    set_sequence_speed(sequence_util.convert_sequence_speed[v])
end

local function add_params()
    params:add_separator("SEQUENCE_CONTROL", page_name)
    params:add_option(PARAM_ID_SEQUENCE_SPEED, "sequence speed", sequence_util.sequence_speeds, sequence_util.default_speed_idx)
    params:set_action(PARAM_ID_SEQUENCE_SPEED, action_sequence_speed)
end

function page:render()
    window:render()
    local tempo_trimmed = misc_util.trim(tostring(clock.get_tempo()), 5)
    page.footer.button_text.e2.value = tempo_trimmed
    page.footer.button_text.k2.value = report_transport() and "ON" or "OFF"
    page.footer.button_text.k3.value = report_hold() and "ON" or "OFF"
    page.footer.button_text.e3.value = sequence_util.sequence_speeds[params:get(PARAM_ID_SEQUENCE_SPEED)]
    control_graphic.bpm = tempo_trimmed
    control_graphic.current_step = report_current_step()
    control_graphic.current_quarter = report_current_quarter_note()
    control_graphic:render()
    page.footer:render()
end

function page:initialize()
    add_params()
    window = Window:new({
        x = 0,
        y = 0,
        w = 128,
        h = 64,
        title = page_name,
        font_face = TITLE_FONT,
        brightness = 15,
        border = false,
        selected = true,
        horizontal_separations = 0,
        vertical_separations = 0,
    })
    -- graphics
    control_graphic = ControlGraphic:new()
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "PLAY",
                value = "",
            },
            k3 = {
                name = "HOLD",
                value = "",
            },
            e2 = {
                name = "BPM",
                value = "",
            },
            e3 = {
                name = "STEP",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })
end

return page
