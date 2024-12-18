local debug = include("bits/lib/debug")
local audio_util = include("bits/lib/audio_util")
local main_scene = include("bits/lib/scenes/main")
local sample_length

-- todo: everything with "current" could be saved in in a state table

local scenes = {
  main_scene,
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
loop_starts = {}
loop_ends = {}

function generate_loop_segment(sample_dur, max_length)
  -- Generate a pair of numbers (a, b) reflecting a loop segment.
  -- a = loop start, b = loop end
  -- a < b < sample duration
  -- (b - a) < max_length

  print("sample_dur" .. sample_dur)

  -- limit the maximium loop length
  max_length = max_length or sample_dur / 50

  -- introduce some padding so that a isn't closer than 1% to the sample end
  padding = sample_dur / 100

  -- pick start position
  local a = math.random() * (sample_length - padding)

  -- End position should be a larger number than start position; and confine to the defined max length
  local b_span
  if (sample_dur - a) < max_length then
    -- randomize within the remaining segment, i.e. [a : sample_dur]
    b_span = sample_dur - a
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

  -- range: 0.0-1.0
  local min_level = 0.2
  local max_level = 0.7

  -- available pan range is 2 (-1.0 to 1.0); limit range to avoid extremes
  local pan_range = 1

  for i = 1, 6 do
    -- pick playback rate from rate_values table
    rates[i] = rate_values[math.random(#rate_values)]

    -- define controlled random audio level (result should be 0 - 1)
    levels[i] = min_level + (math.random() * (max_level - min_level))

    -- define pan
    pans[i] = (pan_range / 2) - (math.random() * pan_range)

    -- generate loop segment based on sample length
    loop_starts[i], loop_ends[i] = generate_loop_segment(sample_length)
    print(i .. ": a=" .. loop_starts[i] .. "  b=" .. loop_ends[i])

    -- configure softcut voice
    softcut.level(i, levels[i])
    softcut.rate(i, rates[i])
    softcut.position(i, loop_starts[i])
    softcut.loop_start(i, loop_starts[i])
    softcut.loop_end(i, loop_ends[i])
  end
end

function modulate_loop_points()
  -- not yet implemented
  my_lfo = lfo.new()
  my_lfo:start()
  print('modulating loop points')
end

function update_positions(i, pos)
  -- works together with modulate_loop_points
  -- print("voice" .. i..":"..pos .. "loop: "..loop_starts[i].." - " .. loop_ends[i])
end


function enable_all_voices()
  local pan_locations = { -1, -.5, -.25, .25, .5, 1 }
  for i = 1, 6 do
    softcut.enable(i, 1)
    softcut.buffer(i, 1)
    softcut.loop(i, 1)
    softcut.play(i, 1)
    softcut.pan(i, pan_locations[i]) -- seems to clash with pan randomization
    softcut.fade_time(i, .2)
  end
end


function load_sample(file, mono)
  -- this could be moved to some audio util module, you'll need it every project
  -- it should support both mono and stereo
  debug.print_info(file)
  softcut.buffer_clear()
  sample_length = audio_util.get_duration(file)
  print("sample length: " .. sample_length)
  start_src = 0 -- file read position
  start_dst = 0 -- buffer write position

  if mono or (audio_util.num_channels(file) == 1) then
    softcut.buffer_read_mono(file, start_src, start_dst, sample_length, 1, 1)
  else
    softcut.buffer_read_stereo(file, start_src, start_dst, sample_length)
  end

  -- might take this out of the function, so that the rest is reusbale
  randomize_softcut()
end

local interface = {
  -- functions that scenes can call 
  randomize_softcut = randomize_softcut,
}

function init()
  -- hardware sensitivity
  for i = 1, 3 do
    norns.enc.sens(i, 6)
    norns.enc.accel(i, true)
  end

  -- file selection
  params:add_separator("bits", "bits")
  params:add_file('audio_file_1', 'file')
  params:set_action("audio_file_1", function(file) load_sample(file) end)

  -- params:add_number('max_granularity')

  -- init softcut
  load_sample(_path.dust .. "audio/etsuko/sea-minor/sea-minor-chords.wav")
  softcut.phase_quant(1, 0.5)
  softcut.event_phase(update_positions)
  softcut.poll_start_phase()

  main_scene.k2_off = randomize_softcut
  main_scene.initialize(rates)
  enable_all_voices()

  -- init clock
  c = metro.init(count, 1 / 60)
  c:start()
end

function key(n, z)

  if n == 1 and z == 0 then current_scene.k1_off() end
  if n == 1 and z == 1 then current_scene.k1_on() end

  if n == 2 and z == 0 then current_scene.k2_off() end
  if n == 2 and z == 1 then current_scene.k2_on() end

  if n == 3 and z == 1 then
    current_scene.k3_on()
    randomize_softcut()
  end
end

function enc(n, d)
  if n == 1 then current_scene.e1(n, d) end
  if n == 2 then current_scene.e2(n, d) end
  if n == 3 then current_scene.e3(n, d) end
end

function refresh()
  if ready then
    current_scene.render()
    ready = false
  end
end

function rerun()
  norns.script.load(norns.state.script)
end

function stop()
  norns.script.clear()
end
