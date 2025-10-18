local page_name = "ECHO"
local window
local EchoGraphic = include("symbiosis/lib/graphics/EchoGraphic")
local echo_graphic

local function adjust_wet(d)
    local p = ID_ECHO_DRYWET
    local new_val = params:get_raw(p) + d * controlspec_echo_drywet.quantum
    params:set_raw(p, new_val)
end

local function adjust_feedback(d)
    local p = ID_ECHO_FEEDBACK
    local new_val = params:get_raw(p) + d * controlspec_echo_feedback.quantum
    params:set(p, new_val)
end

local function cycle_time()
    local p = ID_ECHO_TIME
    local new_val = util.wrap(params:get(p) + 1, 1, #ECHO_TIME_AMOUNTS)
    params:set(p, new_val)
end

local function cycle_style()
    local p = ID_ECHO_STYLE
    local new_val = util.wrap(params:get(p) + 1, 1, #ECHO_STYLES)
    params:set(p, new_val)
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
    print('new echo duration: '.. duration)
    engine.echo_time(duration)
end

local function action_echo_time(v)
    local time_fraction = ECHO_TIME_AMOUNTS[v]
    recalculate_echo_time(clock.get_tempo(), time_fraction)
end


local function action_echo_style(v)
    engine.echo_style(ECHO_STYLES[v])
    print('set echo to ' .. ECHO_STYLES[v])
end

local function add_params()
    params:set_action(ID_ECHO_DRYWET, function(v) engine.echo_wet(v) end)
    params:set_action(ID_ECHO_STYLE, action_echo_style)
    params:set_action(ID_ECHO_FEEDBACK, function(v) engine.echo_feedback(v) end)
    params:set_action(ID_ECHO_TIME, action_echo_time)
end

function page:render()
    -- screen.move(64, 32)
    -- screen.text_center("ECHO")
    local time = ECHO_TIME_NAMES[params:get(ID_ECHO_TIME)]
    local wet = params:get(ID_ECHO_DRYWET)
    local feedback = params:get(ID_ECHO_FEEDBACK)
    local style = ECHO_STYLES[params:get(ID_ECHO_STYLE)]
    echo_graphic.time = params:get(ID_ECHO_TIME)
    echo_graphic.feedback = params:get(ID_ECHO_FEEDBACK) -- 1 to 4
    echo_graphic.wet = params:get(ID_ECHO_DRYWET)
    echo_graphic:render()
    page.footer.button_text.k2.value = style
    page.footer.button_text.k3.value = time
    page.footer.button_text.e2.value = feedback
    page.footer.button_text.e3.value = wet
    page.footer:render()
    window:render()
end

function page:initialize()
    add_params()
    window = Window:new({ title = page_name, font_face = TITLE_FONT })

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
