---
--- ECHO params
---
local page_id = "echo_"

ID_ECHO_TIME = page_id .. "time"
ECHO_TIME_AMOUNTS = { 0.125, 0.1875, 0.25, 0.375, 0.5, 0.75, 1, 1.5, 2 }
ECHO_TIME_NAMES = { "1/32", "1/32D", "1/16", "1/16D", "1/8", "1/8D", "1/4", "1/4D", "1/2" }

params:add_separator("ECHO", "ECHO")
params:add_option(ID_ECHO_TIME, "time", ECHO_TIME_NAMES, 4)
