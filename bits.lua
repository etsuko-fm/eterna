local audio_util = include("bits/lib/util/audio_util")
local scene_main = include("bits/lib/scenes/main")
local scene_time_controls = include("bits/lib/scenes/timecontrols")
local scene_scan = include("bits/lib/scenes/scan")
local scene_sample_select = include("bits/lib/scenes/sampleselect")

local debug_mode = true
local fps = 60
local state = {
  -- sample
  playback_positions = {},
  rates = {}, -- playback rates
  pans = {},
  max_sample_length = 10.0, -- limits the allowed enabled section of the sample
  selected_sample = _path.audio .. "etsuko/sea-minor/sea-minor-chords.wav",
  sample_length = nil, -- full length of the currently loaded sample

   -- section of the sample that is currently enabled; 
   --  playback position randomizations will be done within this section.
  enabled_section = {nil, nil},

  -- waveform
  waveform_samples = {},
  interval = 0, -- of what? unused?
  scale_waveform = 15,

  -- time controls
  fade_time = .2, -- crossfade when looping playback
  request_randomize_softcut = false, -- todo: is this still used or replaced it with events?
  loop_sections = {}, -- one item per softcut voice

  -- scanning
  scan_val = 0.5,                 -- 0 to 1; allows scanning through softcut voices (think smooth soloing/muting)
  levels = { 0, 0, 0, 0, 0, 0, }, -- softcut levels; initialized later by the scan scene
  sigma = 1,                      -- Width of the gaussian curve, adjustable for sharper or broader curves

  -- event system
  events = {}
}

local scenes = {
  scene_main,
  scene_time_controls,
  scene_scan,
  scene_sample_select,
}

local current_scene_index = 1
local current_scene = scenes[current_scene_index]

-- todo: this is great re-usable functionality, move to lib; also confusing otherwise
-- should then be in a SceneManager class. However cyling scenes is not always the most straightforward thing to do.
local function cycle_scene_forward()
  -- Increment the current scene index, reset to 1 if we exceed the table length
  current_scene_index = (current_scene_index % #scenes) + 1
  current_scene = scenes[current_scene_index]
end

local function cycle_scene_backward()
  -- Decrement the current scene index, wrap around to the last scene if it goes below 1
  current_scene_index = (current_scene_index - 2) % #scenes + 1
  current_scene = scenes[current_scene_index]
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
  local b = a + (math.random() * (state.enabled_section[2]-a))
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
    local max_len

    -- generate loop segment based on sample length
    state.loop_sections[i] = {}
    state.loop_sections[i][1], state.loop_sections[i][2] = generate_loop_segment(state)
    print(i .. ": a=" .. state.loop_sections[i][1] .. "  b=" .. state.loop_sections[i][2])

    -- configure softcut voice
    softcut.rate(i, state.rates[i])
    softcut.position(i, state.loop_sections[i][1])
    softcut.loop_start(i, state.loop_sections[i][1])
    softcut.loop_end(i, state.loop_sections[i][2])
  end
end

local function modulate_loop_points()
  -- not yet implemented
  -- https://monome.org/docs/norns/api/modules/lib.lfo.html#new
  -- my_lfo = lfo.new(shape, min, max, depth, mode, period, action, phase, baseline)
  -- my_lfo:start()
  -- print('modulating loop points')
end

local function update_positions(i, pos)
  state.playback_positions[i] = pos / (state.enabled_section[2] - state.enabled_section[1])
  -- works together with modulate_loop_points
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
  print("sample_length: " .. state.sample_length)

  state.enabled_section = {0, state.max_sample_length}
  if state.sample_length < state.max_sample_length then
    state.enabled_section = {0, state.sample_length}
  end

  softcut.render_buffer(1, 0, state.sample_length, 128)
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
  if debug_mode then switch_sample(_path.dust .. "audio/etsuko/sea-minor/sea-minor-chords.wav") end
  -- softcut.phase_quant(1, 1/fps)
  -- softcut.event_phase(update_positions)
  -- softcut.poll_start_phase()
  softcut.event_position(update_positions)

  -- get initial position values for softcut voices
  query_positions()

  scene_main.k2_off = randomize_softcut -- bind function to scene, todo: use events

  for _, scene in ipairs(scenes) do
    scene:initialize(state)
  end

  enable_all_voices()

  -- init clock
  c = metro.init(count, 1 / fps)
  c:start()
end


function key(n, z)
  if n == 1 and z == 0 and current_scene.k1_off then current_scene.k1_off(state) end
  if n == 1 and z == 1 and current_scene.k1_on then current_scene.k1_on(state) end
  if n == 2 and z == 0 and current_scene.k2_off then current_scene.k2_off(state) end
  if n == 2 and z == 1 and current_scene.k2_on then current_scene.k2_on(state) end
  if n == 3 and z == 0 and current_scene.k3_off then current_scene.k3_off(state) end
  if n == 3 and z == 1 and current_scene.k3_on then current_scene.k3_on(state) end
end

local ticks = 0
function enc(n, d)
  if n == 1 then
    -- the ticks mechanism verifies that scene switch is intentional
    if d > 0 then
      ticks = ticks + 1
      if ticks >= 5 then
        cycle_scene_forward()
        ticks = 0
      end
    else
      ticks = ticks - 1
      if ticks <= -5 then
        cycle_scene_backward()
        ticks = 0
      end
    end
  end
  if n == 2 and current_scene.e2 then current_scene.e2(state, d) end
  if n == 3 and current_scene.e3 then current_scene.e3(state, d) end
end

function query_positions()
  for i = 1, 6 do
    softcut.query_position(i)
  end
end

local event_handlers = {
  -- maps event names to functions
  event_randomize_softcut = function()
    execute_event(randomize_softcut, "event_randomize_softcut")
  end,
  event_switch_sample = function()
    execute_event(switch_sample, "event_switch_sample", state.selected_sample)
  end,
}

function execute_event(handler, request, ...)
  handler(...)                  -- Execute the handler with additional arguments
  state.events[request] = false -- Reset the event state
end

function refresh()
  if ready then
    query_positions()
    current_scene:render(state)

    -- sort of an event based system, allows scenes to request main functionality

    for event, handler in pairs(event_handlers) do
      if state.events[event] then
        handler()
      end
    end

    if state.request_randomize_softcut then
      execute_event(randomize_softcut, "request_randomize_softcut")
      randomize_softcut()
      state.request_randomize_softcut = false
    end
    if state.request_switch_sample then
      execute_event(switch_sample, state.selected_sample)

      state.request_switch_sample = false
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
