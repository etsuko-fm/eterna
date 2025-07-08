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
local page_sequencer = include("bits/lib/pages/sequencer")
local page_pitch = include("bits/lib/pages/pitch")

local fps = 60
local ready

screen_dirty = true
local screen_is_updating = false

state = {
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
  fade_time = 8/48000,                    -- crossfade when looping playback
  request_update_softcut = false, -- todo: is this still used or replaced it with events?

  pages = {
    -- scanning / gaussian graph settings
    metamixer = {
      sigma = 2,                      -- Width of the gaussian curve, adjustable for sharper or broader curves
      lfo = nil,
    },
    panning = {
      lfo = nil,
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
    sample = {
      waveform_samples = {},
      waveform_width = 960, -- >=30 per waveform, so 1/32 should be >= 30
      scale_waveform = 5,
      filename = "",
      selected_sample = _path.audio .. "etsuko/sea-minor/sea-minor-chords.wav",
    }
  },
  -- event system
  events = {}
}

local pages = {
  page_sampling,
  page_sequencer,
  page_panning,
  page_pitch,
  page_levels,
}

local current_page_index = 1
local current_page = pages[current_page_index]

local function page_forward()
  -- Increment the current page index, reset to 1 if we exceed the table length
  if current_page_index < #pages then
    current_page_index = current_page_index + 1
  end
  current_page = pages[current_page_index]
end

local function page_backward()
  -- Decrement the current page index, wrap around to the last page if it goes below 1
  if current_page_index > 1 then
    current_page_index = current_page_index - 1
  end
  current_page = pages[current_page_index]
end

local function count()
  -- relates to fps and flickerless rerndering
  ready = true
end


local function enable_all_voices()
  for i = 1, 6 do
    softcut.enable(i, 1)
    softcut.buffer(i, 1)
    softcut.loop(i, 0)
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
      page_forward()
    else
      page_backward()
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

function refresh()
  if ready and not screen_is_updating then
    screen_dirty = false
    ready = false
    screen_is_updating = true
    screen.clear()
    current_page:render(state)
    screen.update()
    screen_is_updating = false
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

