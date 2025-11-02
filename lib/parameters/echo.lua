---
--- ECHO params
---
local page_id = "echo_"

ID_ECHO_TIME = page_id .. "time"
ECHO_TIME_AMOUNTS = { 0.0625, 0.125, 0.1875, 0.25, 0.375, 0.5, 0.625, 0.75, 1, 1.25 }
ECHO_TIME_NAMES = {"1/64", "1/32", "1/32D", "1/16", "1/16D", "1/8", "5/32", "1/8D", "1/4", "5/16" }

params:add_separator("ECHO", "ECHO")
params:add_option(ID_ECHO_TIME, "time", ECHO_TIME_NAMES, 4)
