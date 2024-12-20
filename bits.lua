local audio_util = include("bits/lib/util/audio_util")
local scene_main = include("bits/lib/scenes/main")
local scene_time_controls = include("bits/lib/scenes/time_controls")
local scene_scan = include("bits/lib/scenes/scan")
local sample_length
local debug_mode = true
local fps = 60
local state = {
  -- main scene
  playback_positions = {},
  max_sample_length = 10.0, -- fraction

  -- time controls
  fade_time = .2,
  request_randomize_softcut = false,
  loop_starts = {},
  loop_ends = {},

  -- scanning
  scan_val = 0,                  -- 0 to 1
  levels = { 1, 1, 1, 1, 1, 1 }, -- softcut levels
  sigma = 1,                     -- Width of the gaussian curve, adjustable for sharper or broader curves
}

local scenes = {
  scene_main,
  scene_time_controls,
  scene_scan,
}

current_scene_index = 1
local current_scene = scenes[current_scene_index]

-- todo: this is great re-usable functionality, move to lib; also confusing otherwise
-- should then be in a SceneManager class. However cyling scenes is not always the most straightforward thing to do.
function cycle_scene_forward()
  -- Increment the current scene index, reset to 1 if we exceed the table length
  current_scene_index = (current_scene_index % #scenes) + 1
  current_scene = scenes[current_scene_index]
end

function cycle_scene_backward()
  -- Decrement the current scene index, wrap around to the last scene if it goes below 1
  current_scene_index = (current_scene_index - 2) % #scenes + 1
  current_scene = scenes[current_scene_index]
end

function count()
  -- relates to fps and flickerless rerndering
  ready = true
end

rates = {}
pans = {}
levels = {}
positions = {}

function generate_loop_segment(max_length)
  -- Generate a pair of numbers (a, b) reflecting a loop segment.
  -- a = loop start, b = loop end
  -- a < b < sample duration
  -- (b - a) < max_length

  -- bit icky, but sample_length is a global var

  -- limit the maximium loop length
  max_length = max_length or sample_length / 4 -- might need to get rid of that /4

  -- introduce some padding so that `a` isn't closer than 1% to the sample end
  padding = sample_length / 100

  -- pick start position
  local a = math.random() * (sample_length - padding)

  -- End position should be a larger number than start position; and confine to the defined max length
  local b_span
  if (sample_length - a) < max_length then
    -- randomize within the remaining segment, i.e. [a : sample_length]
    b_span = sample_length - a
  else
    -- randomize within [a : (a + max_length)]
    b_span = max_length
  end
  local b = a + (math.random() * b_span)
  return a, b
end

function randomize_softcut()
  -- randomize playback rate, loop segment and level of all 6 softcut voices

  -- a few presets to choose from
  local rate_values_mid = { 0.5, 1, 2, -0.5, -1, -2 }
  local rate_values_low = { 0.25, 0.5, 1, -1, -.5, -.25 }
  local rate_values_sub = { 0.125, 0.25, 0.5, -0.5, -.25, -.125 }
  local rate_values = rate_values_mid

  for i = 1, 6 do
    -- pick playback rate from rate_values table
    rates[i] = rate_values[math.random(#rate_values)]

    -- generate loop segment based on sample length
    state.loop_starts[i], state.loop_ends[i] = generate_loop_segment(state.max_sample_length)
    print(i .. ": a=" .. state.loop_starts[i] .. "  b=" .. state.loop_ends[i])

    -- configure softcut voice
    softcut.rate(i, rates[i])
    softcut.position(i, state.loop_starts[i])
    softcut.loop_start(i, state.loop_starts[i])
    softcut.loop_end(i, state.loop_ends[i])
  end
end

function modulate_loop_points()
  -- not yet implemented
  -- https://monome.org/docs/norns/api/modules/lib.lfo.html#new
  -- my_lfo = lfo.new(shape, min, max, depth, mode, period, action, phase, baseline)
  -- my_lfo:start()
  -- print('modulating loop points')
end

function update_positions(i, pos)
  state.playback_positions[i] = pos / sample_length
  -- works together with modulate_loop_points
  -- print("voice" .. i..":"..pos .. "loop: "..state.loop_starts[i].." - " .. state.loop_ends[i])
end

function enable_all_voices()
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

function switch_sample(file)
  -- use specified `file` as a sample
  sample_length = audio_util.load_sample(file, true, 10)
  print("sample_length: " .. sample_length)
  randomize_softcut()
end

function init()
  -- hardware sensitivity
  for i = 1, 3 do
    norns.enc.sens(i, 1)
    norns.enc.accel(i, true)
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

  scene_main.k2_off = randomize_softcut -- bind function to scene
  scene_main:initialize(rates)
  enable_all_voices()

  -- init clock
  c = metro.init(count, 1 / fps)
  c:start()
end

local key_latch = {
  [2] = false,
  [3] = false,
}


function key(n, z)
  if n == 1 and z == 0 and current_scene.k1_off then current_scene.k1_off() end
  if n == 1 and z == 1 and current_scene.k1_on then current_scene.k1_on() end

  if n == 2 and z == 0 then
    key_latch[n] = false
    -- skip functionality while key combinations are being performed
    if not key_latch[3] and current_scene.k2_off then current_scene.k2_off() end
  end

  if n == 2 and z == 1 then
    key_latch[n] = true
    if key_latch[3] then
      -- prioritize scene switching over scene functionality
      -- key combination: k3 held, press k2
      cycle_scene_backward()
      print("switching to prev scene")
    elseif current_scene.k2_on then
      current_scene.k2_on()
    end
  end

  if n == 3 and z == 0 then
    key_latch[n] = false
    if current_scene.k3_off then current_scene.k3_off() end
  end

  if n == 3 and z == 1 then
    key_latch[n] = true
    if key_latch[2] then
      -- prioritize scene switching
      -- key combination: k2 held, press k3
      cycle_scene_forward()
      print("switching to next scene")
    elseif current_scene.k3_on then
      current_scene.k3_on()
    end
  end
end

function enc(n, d)
  if n == 1 and current_scene.e1 then current_scene.e1(state, d) end
  if n == 2 and current_scene.e2 then current_scene.e2(state, d) end
  if n == 3 and current_scene.e3 then current_scene.e3(state, d) end
end

function query_positions()
  for i = 1, 6 do
    softcut.query_position(i)
  end
end

function refresh()
  if ready then
    query_positions()
    current_scene:render(state)

    -- sort of an event based system, allows scenes to request main functionality
    if state.request_randomize_softcut then
      randomize_softcut()
      state.request_randomize_softcut = false
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
