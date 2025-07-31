---
--- PLAYBACK RATES
---

-- Helpers

function get_voice_dir_param_id(i)
  -- get voice directions; also used for other pages, hence global
  return "rates_v" .. i .. "_dir"
end

--- ControlSpecs

RATES_CENTER_MIN = -2
RATES_CENTER_MAX = 2
RATES_CENTER_QUANTUM = 1

RATES_SPREAD_MIN = -2
RATES_SPREAD_MAX = 2
RATES_SPREAD_MIN_QNT = -2
RATES_SPREAD_MAX_QNT = 2
RATES_SPREAD_QUANTUM = 1
RATES_SPREAD_QUANTUM = 1

controlspec_rates_center = controlspec.def {
    min = RATES_CENTER_MIN,
    max = RATES_CENTER_MAX,
    warp = 'lin',
    step = 1,
    default = -1,
    units = '',
    quantum = RATES_CENTER_QUANTUM,
    wrap = false
}

controlspec_rates_spread = controlspec.def {
    min = RATES_SPREAD_MIN_QNT,
    max = RATES_SPREAD_MAX_QNT,
    warp = 'lin',
    step = 1,
    default = 1,
    units = '',
    quantum = RATES_SPREAD_QUANTUM,
    wrap = false
}

--- Params

ID_RATES_DIRECTION = "rates_direction"
ID_RATES_RANGE = "rates_range"
ID_RATES_CENTER = "rates_center"
ID_RATES_SPREAD = "rates_spread"

FWD = "FWD"
REV = "REV"
FWD_REV = "BI"
PLAYBACK_TABLE = { FWD, REV, FWD_REV }

THREE_OCTAVES = "3 OCT"
FIVE_OCTAVES = "5 OCT"
RANGE_TABLE = { THREE_OCTAVES, FIVE_OCTAVES }
RANGE_DEFAULT = 2 -- 5 octaves by default

params:add_separator("PLAYBACK_RATES", "PLAYBACK RATES")
params:add_option(ID_RATES_RANGE, 'range', RANGE_TABLE, RANGE_DEFAULT)
params:add_control(ID_RATES_CENTER, "center", controlspec_rates_center)
params:add_control(ID_RATES_SPREAD, "spread", controlspec_rates_spread)
params:add_option(ID_RATES_DIRECTION, "direction", PLAYBACK_TABLE, 1)

for voice = 1, 6 do
    -- add params for playback direction per voice
    local param_id = get_voice_dir_param_id(voice)
    params:add_option(param_id, param_id, PLAYBACK_TABLE, 1)
    params:hide(param_id)
end