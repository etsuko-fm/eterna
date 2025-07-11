local Page = include("bits/lib/Page")
local Window = include("bits/lib/graphics/Window")
local ControlGraphic = include("bits/lib/graphics/ControlGraphic")
local sequence_util = include("bits/lib/util/sequence")

local page_name = "SEQUENCE CONTROL"
local window
local control_graphic

local function adjust_bpm()
end

local function adjust_step_size()
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
    page.sequence_speed = sequence_util.convert_sequence_speed[v]
end

local function add_params()
    params:add_separator("SEQUENCE_CONTROL", page_name)

    params:add_option(PARAM_ID_SEQUENCE_SPEED, "sequence speed", sequence_util.sequence_speeds, sequence_util.default_speed_idx)
    params:set_action(PARAM_ID_SEQUENCE_SPEED, action_sequence_speed)

end

function page:render()
    window:render()
    page.footer.button_text.e2.value = clock.get_tempo()
    page.footer.button_text.k2.value = report_transport() and "ON" or "OFF"
    control_graphic.bpm = clock.get_tempo()
    control_graphic.current_step = report_current_step()
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
