local page_name = "ECHO"
local EchoGraphic = include(from_root("lib/graphics/EchoGraphic"))
local echo_graphic

local ID_ECHO_WET = engine_lib.get_id("echo_wet")
local ID_ECHO_STYLE = engine_lib.get_id("echo_style")
local ID_ECHO_FEEDBACK = engine_lib.get_id("echo_feedback")

local function adjust_wet(d)
    engine_lib.echo_wet(d, true)
end

local function adjust_feedback(d)
    engine_lib.echo_feedback(d, true)
end

local function cycle_time()
    misc_util.cycle_param(ID_ECHO_TIME, ECHO_TIME_AMOUNTS)
end

local function cycle_style()
    misc_util.cycle_param(ID_ECHO_STYLE, engine_lib.echo_styles)
end

local page = Page:create({
    name = page_name,
    e2 = adjust_feedback,
    e3 = adjust_wet,
    k2_off = cycle_style,
    k3_off = cycle_time,
})

function recalculate_echo_time(bpm, time_fraction)
    -- global, because also used for tempo change handler
    if not time_fraction then
        time_fraction = ECHO_TIME_AMOUNTS[params:get(ID_ECHO_TIME)]
    end
    local duration = (60 / bpm) * time_fraction
    params:set(engine_lib.get_id("echo_time"), duration)
end

local function action_echo_time(v)
    local time_fraction = ECHO_TIME_AMOUNTS[v]
    recalculate_echo_time(clock.get_tempo(), time_fraction)
end

local function add_params()
    params:set_action(ID_ECHO_TIME, action_echo_time)
end

function page:render()
    local time = ECHO_TIME_NAMES[params:get(ID_ECHO_TIME)]
    local wet = params:get(ID_ECHO_WET)
    local feedback = params:get(ID_ECHO_FEEDBACK)
    local style = engine_lib.echo_styles[params:get(ID_ECHO_STYLE)]
    echo_graphic.time = params:get(ID_ECHO_TIME)
    echo_graphic.feedback = params:get(ID_ECHO_FEEDBACK) -- 1 to 4
    echo_graphic.wet = params:get(ID_ECHO_WET)
    echo_graphic:render()
    page.footer.button_text.k2.value = style
    page.footer.button_text.k3.value = time
    page.footer.button_text.e2.value = feedback
    page.footer.button_text.e3.value = wet
    page.footer:render()
    self.window:render()
end

function page:initialize()
    add_params()
    self.window = Window:new({ title = page_name, font_face = TITLE_FONT })

    echo_graphic = EchoGraphic:new()

    -- graphics
    page.footer = Footer:new({
        button_text = {
            k2 = {
                name = "STYLE",
                value = "",
            },
            k3 = {
                name = "TIME",
                value = "",
            },
            e2 = {
                name = "FEEDB",
                value = "",
            },
            e3 = {
                name = "MIX",
                value = "",
            },
        },
        font_face = FOOTER_FONT,
    })
end

return page
