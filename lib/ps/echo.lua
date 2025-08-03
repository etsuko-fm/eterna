---
--- ECHO params
---
local page_id = "echo_"

ID_ECHO_STYLE = page_id .. "style"
ID_ECHO_TIME = page_id .. "time"
ID_ECHO_DRYWET = page_id .. "drywet"
ID_ECHO_FILTER_ENV = page_id .. "filter_env"
ID_ECHO_FEEDBACK = page_id .. "curve"

ECHO_FEEDBACK_AMOUNTS = { 0.3, 0.6, 0.85, 0.92 }
ECHO_FEEDBACK_NAMES = { "LOW", "MID", "HIGH", "MAX" }
ECHO_TIME_AMOUNTS = { 0.125, 0.1875, 0.25, 0.375, 0.5, 0.75, 1, 1.5, 2 }
ECHO_TIME_NAMES = { "1/32", "1/32D", "1/16", "1/16D", "1/8", "1/8D", "1/4", "1/4D", "1/2" }

local ECHO_DRYWET_MIN = 0
local ECHO_DRYWET_MAX = 1

controlspec_echo_drywet = controlspec.def {
    min = ECHO_DRYWET_MIN,
    max = ECHO_DRYWET_MAX,
    warp = 'lin',
    step = 0.01,
    default = 0.2,
    units = '',
    quantum = 0.01,
    wrap = false
}

params:add_separator("ECHO", "ECHO")
-- params:add_option(ID_ECHO_STYLE, "style", "toggle", 1)
params:add_option(ID_ECHO_TIME, "time", ECHO_TIME_NAMES)
params:add_control(ID_ECHO_DRYWET, "drywet", controlspec_echo_drywet)
params:add_option(ID_ECHO_FEEDBACK, "curve", ECHO_FEEDBACK_NAMES)
