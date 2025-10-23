---
--- SEQUENCE CONTROL
---

local page_id = "control_"

ID_SEQUENCE_SPEED = page_id .. "sequencer_speed"
params:add_option(ID_SEQUENCE_SPEED, "sequence speed", sequence_util.sequence_speeds, sequence_util.default_speed_idx)
params:add_separator("SEQUENCE_CONTROL", "CONTROL")
