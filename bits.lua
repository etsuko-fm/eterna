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

local debug_mode = true
local fps = 60
local ready
-- engine.name = "Sines"

PLAYBACK_DIRECTION = {
  FWD = "FWD",
  REV = "REV",
  FWD_REV = "FWD_REV"
}

SAMPLE_MODE = {
  SAMPLE = "SAMPLE",
  DELAY = "DELAY",
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
  loop_sections = {},                -- one item per softcut voice [i][1] = start and [i][2] is end


  pages = {
    -- scanning / gaussian graph settings
    metamixer = {
      windows = {},
      scan_val = 0.5,                 -- 0 to 1; allows scanning through softcut voices (think smooth soloing/muting)
      levels = { 0, 0, 0, 0, 0, 0, }, -- softcut levels; initialized later by the metamixer page
      sigma = 2,                      -- Width of the gaussian curve, adjustable for sharper or broader curves
      sigma_min = 0.3,
      sigma_max = 15,
      lfo = nil,
      lfo_period = 6,
    },
    panning = {
      lfo = nil,
      twist = 0,
      spread = 32,
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
        start = 1,
        width = 32,
      },
    },
    pitch = {          -- should maybe rename to playback rate
      rate_center = 0, -- 0 = center, bipolar, relative to current range
      rate_spread = 1, -- fraction of playback rate
      quantize = true,
      direction = PLAYBACK_DIRECTION["FWD_REV"],
    },
    sample = {
      mode = SAMPLE_MODE["SAMPLE"],
      waveform_samples = {},
      waveform_width = 59,
      scale_waveform = 10,
      filename = "",
      selected_sample = _path.audio .. "etsuko/sea-minor/sea-minor-chords.wav",
      echo = {
        feedback = 80,
        time = 4, -- seconds
      }
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

local function update_softcut(state)
  for i = 1, 6 do
    state.loop_sections[i] = {}
    state.loop_sections[i][1] = state.pages.slice.enabled_section[1]
    state.loop_sections[i][2] = state.pages.slice.enabled_section[2]

    -- configure softcut voice
    softcut.position(i, state.pages.slice.enabled_section[1])
    softcut.loop_start(i, state.pages.slice.enabled_section[1])
    softcut.loop_end(i, state.pages.slice.enabled_section[2])
  end
end

local function update_positions(i, pos)
  --- callback for softcut.event_position.
  --- i:   softcut voice
  --- pos: playback position of voice i, in seconds
  ---
  --- updates state.playback_positions[i] with a val between 0 and 1, relative to the length of the enabled section.
  --- if the enabled section is 10s long, starts at 0:05:
  ---   pos = 0 means absolute position 0:05
  ---   pos = 1 means absolute position is 0:15
  --- This is used to display the playback positions in the rings.
  local enabled_section_length = state.pages.slice.enabled_section[2] - state.pages.slice.enabled_section[1]
  state.pages.slice.playback_positions[i] = (pos - state.pages.slice.enabled_section[1]) / enabled_section_length
  -- print("voice" .. i..":"..pos .. "loop: "..state.loop_starts[i].." - " .. state.loop_ends[i])
end

local function enable_all_voices()
  local pan_locations = { -1, -.5, -.25, .25, .5, 1 } -- todo: should be based on pan page

  for i = 1, 6 do
    softcut.enable(i, 1)
    softcut.buffer(i, 1)
    softcut.loop(i, 1)
    softcut.play(i, 1)
    softcut.pan(i, pan_locations[i]) -- seems to clash with pan randomization
    softcut.fade_time(i, state.fade_time)
    softcut.level(i, state.levels[i])
  end
end

local function switch_sample(file)
  -- use specified `file` as a sample
  state.sample_length = audio_util.load_sample(file, true)
  state.pages.slice.enabled_section = { 0, state.max_sample_length }
  if state.sample_length < state.max_sample_length then
    state.pages.slice.enabled_section = { 0, state.sample_length }
  end

  softcut.render_buffer(1, 0, state.sample_length, state.pages.sample.waveform_width)
  update_softcut(state)
end

function init()
  -- hardware sensitivity
  norns.enc.sens(1, 5)

  for i = 2, 3 do
    norns.enc.sens(i, 1)
    norns.enc.accel(i, false)
  end

  -- file selection
  params:add_separator("bits", "bits")
  params:add_file('audio_file_1', 'file')
  params:set_action("audio_file_1", function(file) switch_sample(file) end)

  -- params:add_number('max_granularity')

  -- init softcut
  local sample1 = "audio/etsuko/sea-minor/sea-minor-chords.wav"
  local sample2 = "audio/etsuko/neon-light/neon intro.wav"
  if debug_mode then switch_sample(_path.dust .. sample2) end
  -- softcut.phase_quant(1, 1/fps)
  -- softcut.event_phase(update_positions)
  -- softcut.poll_start_phase()
  softcut.event_position(update_positions)

  -- get initial position values for softcut voices
  query_positions()

  for _, page in ipairs(pages) do
    page:initialize(state)
  end

  enable_all_voices()

  -- init clock
  c = metro.init(count, 1 / fps)
  c:start()
end

function key(n, z)
  if n == 1 and z == 0 and current_page.k1_off then current_page.k1_off(state) end
  if n == 1 and z == 1 and current_page.k1_on then current_page.k1_on(state) end
  -- engine.hz(0, 440)
  -- -- engine.vol(0, 1)

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

function query_positions()
  for i = 1, 6 do
    softcut.query_position(i)
  end
end

local event_handlers = {
  -- maps event names to functions
  event_update_softcut = function()
    execute_event(update_softcut, "event_update_softcut", state)
  end,
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
    query_positions()
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

function rerun()
  norns.script.load(norns.state.script)
end
