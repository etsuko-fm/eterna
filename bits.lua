-- bits: 6-voice sample player
-- 1.0.0 @etsuko.fm
-- E1: scroll pages
--
-- Other controls, see footer:
-- | K2 | K3 | E2 | E3 |

_lfos = require 'lfo'
MusicUtil = require "musicutil"

local audio_util = include("bits/lib/util/audio_util")
local page_levels = include("bits/lib/pages/levels")
local page_sampling = include("bits/lib/pages/sampling")
local page_panning = include("bits/lib/pages/panning")
local page_slice = include("bits/lib/pages/slice")
local page_pitch = include("bits/lib/pages/pitch")

local fps = 60
local ready

PLAYBACK_DIRECTION = {
  FWD = "FWD",
  REV = "REV",
  FWD_REV = "FWD_REV"
}

local state = {
  default_font = 68,
  title_font = 68,
  footer_font = 68,
  -- softcut
  softcut = {
    rates = {},    -- playback rates, 1 per voice, 1.0 = normal speed
    muted = false, -- softcut mute
  },

  max_sample_length = 128.0, -- in seconds, longer samples are truncated
  sample_length = nil,       -- full length of the currently loaded sample

  -- time controls
  fade_time = .2,                    -- crossfade when looping playback
  request_update_softcut = false, -- todo: is this still used or replaced it with events?

  pages = {
    -- scanning / gaussian graph settings
    metamixer = {
      sigma = 2,                      -- Width of the gaussian curve, adjustable for sharper or broader curves
      lfo = nil,
    },
    panning = {
      lfo = nil,
      twist = 0,
      pan_positions = { 0, 0, 0, 0, 0, 0, },
      default_lfo_period = 6,
    },
    slice = {
      lfo = nil,
      playback_positions = {},
      -- section of the sample that is currently enabled;
      --  playback position randomizations will be done within this section. [1] and [2] in seconds.
      enabled_section = { nil, nil },
      seek = {
        {
          -- voice 1
          start = 1,
          width = 4,
        },
        {
          -- voice 2
          start = 5,
          width = 9,
        },
        {
          -- voice 3
          start = 10,
          width = 13,
        },
        {
          -- voice 4
          start = 14,
          width = 18,
        },
        {
          -- voice 5
          start = 19,
          width = 23,
        },
        {
          -- voice 6
          start = 24,
          width = 28,
        },
      },
    },
    pitch = {          -- should maybe rename to playback rate
      rate_center = 0, -- 0 = center, bipolar, relative to current range
      rate_spread = 1, -- fraction of playback rate
      quantize = true,
      direction = PLAYBACK_DIRECTION["FWD_REV"],
    },
    sample = {
      waveform_samples = {},
      waveform_width = 59,
      scale_waveform = 10,
      filename = "",
      selected_sample = _path.audio .. "etsuko/sea-minor/sea-minor-chords.wav",
    }
  },
  -- event system
  events = {}
}

local pages = {
  page_sampling,
  page_panning,
  page_levels,
  page_slice,
  page_pitch,
}

local current_page_index = 4
local current_page = pages[current_page_index]

local function cycle_page_forward()
  -- Increment the current page index, reset to 1 if we exceed the table length
  current_page_index = (current_page_index % #pages) + 1
  current_page = pages[current_page_index]
end

local function cycle_page_backward()
  -- Decrement the current page index, wrap around to the last page if it goes below 1
  current_page_index = (current_page_index - 2) % #pages + 1
  current_page = pages[current_page_index]
end

local function count()
  -- relates to fps and flickerless rerndering
  ready = true
end

function update_softcut(state)
  -- no need for events, just make it a global function
  -- resets softcut voice to start of buffer, limits loop length to enabled section
  -- todo: better name, sync_softcut?
  for i = 1, 6 do
    softcut.loop_start(i, state.pages.slice.enabled_section[1])
    softcut.loop_end(i, state.pages.slice.enabled_section[2])
  end
end

function reset_softcut_positions(state)
  for i = 1, 6 do
    softcut.position(i, state.pages.slice.enabled_section[1])
  end
end


local function enable_all_voices()
  for i = 1, 6 do
    softcut.enable(i, 1)
    softcut.buffer(i, 1)
    softcut.loop(i, 1)
    softcut.play(i, 1)
    softcut.fade_time(i, state.fade_time)
  end
end


function init()
  -- Params UX
  params:add_separator("BITS", "BITS")

  -- Encoder sensitivity
  norns.enc.sens(1, 5)

  for i = 2, 3 do
    norns.enc.sens(i, 1)
    norns.enc.accel(i, false)
  end

  for _, page in ipairs(pages) do
    page:initialize(state)
  end

  enable_all_voices()

  -- metro for screen refresh
  c = metro.init(count, 1 / fps)
  c:start()
end

function key(n, z)
  if n == 1 and z == 0 and current_page.k1_off then current_page.k1_off(state) end
  if n == 1 and z == 1 and current_page.k1_on then current_page.k1_on(state) end

  if n == 2 and z == 0 and current_page.k2_off then
    current_page.k2_off(state)
    current_page.footer.active_knob = "k2"
  end
  if n == 2 and z == 1 and current_page.k2_on then
    current_page.k2_on(state)
    current_page.footer.active_knob = "k2"
  end
  if n == 3 and z == 0 and current_page.k3_off then
    current_page.k3_off(state)
    current_page.footer.active_knob = "k3"
  end
  if n == 3 and z == 1 and current_page.k3_on then
    current_page.k3_on(state)
    current_page.footer.active_knob = "k3"
  end
end

function enc(n, d)
  if n == 1 then
    if d > 0 then
      cycle_page_forward()
    else
      cycle_page_backward()
    end
  end
  if n == 2 and current_page.e2 then
    current_page.e2(state, d)
    current_page.footer.active_knob = "e2"
  end
  if n == 3 and current_page.e3 then
    current_page.e3(state, d)
    current_page.footer.active_knob = "e3"
  end
end

local event_handlers = {
  -- maps event names to functions
  event_switch_sample = function()
    execute_event(switch_sample, "event_switch_sample", state.pages.sample.selected_sample)
  end,
}

function execute_event(handler, request, ...)
  handler(...)                  -- Execute the handler with additional arguments
  state.events[request] = false -- Reset the event request
end

function refresh()
  if ready then
    screen.clear()
    current_page:render(state)
    screen.update()

    -- sort of an event based system, allows pages to request main functionality
    -- usage: state.events['event_update_softcut'] = true

    for event, handler in pairs(event_handlers) do
      if state.events[event] == true then
        handler()
      end
    end
    ready = false
  end
end

-- convenience methods for matron
function rerun()
  norns.script.load(norns.state.script)
end

function off()
  for i = 1, 6 do
    softcut.play(i, 0)
  end
end

function on()
  for i = 1, 6 do
    softcut.play(i, 1)
  end
end

