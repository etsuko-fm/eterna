-- bits: 6-voice sample player
-- 1.0.0 @etsuko.fm
-- E1: scroll pages
-- 
-- Other controls:
-- see footer


local audio_util =          include("bits/lib/util/audio_util")

local page_playback =       include("bits/lib/pages/playback")
local page_meta_mixer =     include("bits/lib/pages/metamixer")
local page_sample_select =  include("bits/lib/pages/sampleselect")
local page_panning =        include("bits/lib/pages/panning")
local page_slice =          include("bits/lib/pages/slice")

-- global lfos
_lfos = require 'lfo'

local debug_mode = true
local fps = 60


local state = {
  default_font = 68, -- alt: 68
  title_font = 68,
  footer_font = 68,
  -- sample
  filename="",
  playback_positions = {},
  rates = {},               -- playback rates
  pans = {},
  max_sample_length = 10.0, -- limits the allowed enabled section of the sample
  selected_sample = _path.audio .. "etsuko/sea-minor/sea-minor-chords.wav",
  sample_length = nil,      -- full length of the currently loaded sample
  muted = false,            -- softcut mute
  -- section of the sample that is currently enabled;
  --  playback position randomizations will be done within this section.
  enabled_section = { nil, nil },

  -- waveform
  waveform_samples = {},
  waveform_width = 64,
  scale_waveform = 10,

  -- time controls
  fade_time = .2,                    -- crossfade when looping playback
  request_randomize_softcut = false, -- todo: is this still used or replaced it with events?
  loop_sections = {},                -- one item per softcut voice [i][1] = start and [i][2] is end

  -- scanning / gaussian graph settings
  scan = {
    windows = {}
  },
  scan_val = 0.5,                 -- 0 to 1; allows scanning through softcut voices (think smooth soloing/muting)
  levels = { 0, 0, 0, 0, 0, 0, }, -- softcut levels; initialized later by the metamixer page
  sigma = 5,                      -- Width of the gaussian curve, adjustable for sharper or broader curves
  sigma_min = 0.3,
  sigma_max = 15,
  scan_lfo = nil, --todo: rename to metamixer lfo
  scan_lfo_period = 6,
  scan_lfo_sync = false,
  num_bars = 6,
  bar_height = 24,
  graph_width = 64,
  window_width = 128,
  bar_width = 6,
  graph_x = 32, -- (window_width - graph_width) / 2
  graph_y = 40,

  -- panning.
  panning_spread = 8,
  panning_twist = 0,
  pan_positions = {0, 0, 0, 0, 0, 0, },
  pan_lfo = nil,
  pan_lfo_period = 6,
  pan_lfo_sync = false,

  -- event system
  events = {}
}

local pages = {
  page_sample_select,
  page_panning,
  page_playback,
  page_meta_mixer,
  page_slice,
}

local current_page_index = 1
local current_page = pages[current_page_index]

-- todo: this is re-usable functionality, move to lib; also confusing otherwise
-- should then be in a PageManager class. However cyling pages is not always the most straightforward thing to do.
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


local function generate_loop_segment(state)
  -- Generate a pair of numbers (a, b) reflecting a loop segment.
  -- a = loop start, b = loop end
  -- a < b < sample duration
  -- (b - a) < max_length

  -- introduce some padding so that `a` isn't closer than 1% to the sample end [todo: why 1%?]
  local max_allowed_length = (state.enabled_section[2] - state.enabled_section[1])
  local padding = max_allowed_length / 100

  -- pick start position
  local a = state.enabled_section[1] + (math.random() * (max_allowed_length - padding))

  -- End position should be a larger number than start position; and confine to the defined max length
  local b = a + (math.random() * (state.enabled_section[2] - a))
  return a, b
end

local function randomize_softcut(state)
  -- randomize playback rate, loop segment and level of all 6 softcut voices

  -- a few presets to choose from
  local rate_values_mid = { 0.5, 1, 2, -0.5, -1, -2 }
  local rate_values_low = { 0.25, 0.5, 1, -1, -.5, -.25 }
  local rate_values_sub = { 0.125, 0.25, 0.5, -0.5, -.25, -.125 }
  local rate_values = rate_values_mid

  for i = 1, 6 do
    -- pick playback rate from rate_values table
    state.rates[i] = rate_values[math.random(#rate_values)]

    -- generate loop segment based on sample length
    state.loop_sections[i] = {}
    state.loop_sections[i][1], state.loop_sections[i][2] = generate_loop_segment(state)
    -- print(i .. ": a=" .. state.loop_sections[i][1] .. "  b=" .. state.loop_sections[i][2])

    -- configure softcut voice
    softcut.rate(i, state.rates[i])
    softcut.position(i, state.loop_sections[i][1])
    softcut.loop_start(i, state.loop_sections[i][1])
    softcut.loop_end(i, state.loop_sections[i][2])
  end

  -- update rings in the playback page
  page_playback:initialize(state)
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
  enabled_section_length = state.enabled_section[2] - state.enabled_section[1]
  state.playback_positions[i] = (pos - state.enabled_section[1]) / enabled_section_length
  -- print("voice" .. i..":"..pos .. "loop: "..state.loop_starts[i].." - " .. state.loop_ends[i])
end

local function enable_all_voices()
  local pan_locations = { -1, -.5, -.25, .25, .5, 1 }

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
  state.enabled_section = { 0, state.max_sample_length }
  if state.sample_length < state.max_sample_length then
    state.enabled_section = { 0, state.sample_length }
  end

  softcut.render_buffer(1, 0, state.sample_length, state.waveform_width)
  randomize_softcut(state)
end

function init()
  -- hardware sensitivity
  for i = 1, 3 do
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
  if n == 2 and z == 0 and current_page.k2_off then current_page.k2_off(state) end
  if n == 2 and z == 1 and current_page.k2_on then current_page.k2_on(state) end
  if n == 3 and z == 0 and current_page.k3_off then current_page.k3_off(state) end
  if n == 3 and z == 1 and current_page.k3_on then current_page.k3_on(state) end
end

local ticks = 0
function enc(n, d)
  if n == 1 then
    -- the ticks mechanism verifies that page switch is intentional todo: ticks not necessary except if displayed
    if d > 0 then
      ticks = ticks + 1
      if ticks >= 5 then
        cycle_page_forward()
        ticks = 0
      end
    else
      ticks = ticks - 1
      if ticks <= -5 then
        cycle_page_backward()
        ticks = 0
      end
    end
  end
  if n == 2 and current_page.e2 then current_page.e2(state, d) end
  if n == 3 and current_page.e3 then current_page.e3(state, d) end
end

function query_positions()
  for i = 1, 6 do
    softcut.query_position(i)
  end
end

local event_handlers = {
  -- maps event names to functions
  event_randomize_softcut = function()
    execute_event(randomize_softcut, "event_randomize_softcut", state)
  end,
  event_switch_sample = function()
    execute_event(switch_sample, "event_switch_sample", state.selected_sample)
  end,
}

function execute_event(handler, request, ...)
  handler(...)                  -- Execute the handler with additional arguments
  state.events[request] = false -- Reset the event request
end

function refresh()
  if ready then
    query_positions()
    current_page:render(state)

    -- sort of an event based system, allows pages to request main functionality
    -- usage: state.events['event_randomize_softcut'] = true

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

function stop()
  norns.script.clear()
end
