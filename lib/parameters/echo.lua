---
--- ECHO params
---
local page_id = "echo_"

ID_ECHO_STYLE = page_id .. "style"
ID_ECHO_TIME = page_id .. "time"
-- ID_ECHO_DRYWET = page_id .. "drywet"
ID_ECHO_FILTER_ENV = page_id .. "filter_env"
ID_ECHO_FEEDBACK = page_id .. "curve"
ECHO_TIME_AMOUNTS = { 0.125, 0.1875, 0.25, 0.375, 0.5, 0.75, 1, 1.5, 2 }
ECHO_TIME_NAMES = { "1/32", "1/32D", "1/16", "1/16D", "1/8", "1/8D", "1/4", "1/4D", "1/2" }
ECHO_STYLES = { "CLEAR", "DUST", "MIST" }

-- controlspec_echo_drywet = controlspec.def {
--     min = 0,
--     max = 1,
--     warp = 'lin',
--     step = 0.01,
--     default = 0.2,
--     units = '',
--     quantum = 0.02,
--     wrap = false
-- }

controlspec_echo_feedback = controlspec.def {
    min = 0,
    max = 1,
    warp = 'lin',
    step = 0.01,
    default = 0.6,
    units = '',
    quantum = 0.02,
    wrap = false
}

params:add_separator("ECHO", "ECHO")
params:add_option(ID_ECHO_STYLE, "style", ECHO_STYLES)
params:add_option(ID_ECHO_TIME, "time", ECHO_TIME_NAMES, 4)
-- params:add_control(ID_ECHO_DRYWET, "drywet", controlspec_echo_drywet)
params:add_control(ID_ECHO_FEEDBACK, "feedback", controlspec_echo_feedback)
