local Ring = include("bits/lib/Ring")
local Meter = include("bits/lib/Meter")
local debug = include("bits/lib/debug")
local bits_sampler = include("bits/lib/sampler")
local shapes = include("bits/lib/graphics/shapes")
local rings = {}
local rings2 = {}
local sample_length
local current_ring = 1


function render_mixer()
  screen.clear()
  screen.font_size(8)
  screen.move(20, 20)
  screen.text('scene 2')
  screen.update()
end

radians = {
  A0 = 0,
  A90 = math.pi / 2,
  A180 = math.pi,
  A270 = 3 * math.pi / 2
}

-- todo: before randomizing, allow emphasis on low, mid or high


function rate_to_radians(rate)
  -- this is an arbitrary conversion
  -- nominal rate looks acceptable at 1/10 radians
  return rate / 10
end

function render_home(stage)
  screen.clear()
  for i = 1, 6, 1 do
    rings2[i]:render()
    rings[i]:render()
  end
  zigzag_line(0, 32, 128, 4)
end

Scene = {
  name = nil,
  render = nil,
  e1 = nil,
  e2 = nil,
  e3 = nil,
  k1_hold_on = nil,
  k1_hold_off = nil,
  k2_on = nil,
  k2_off = nil,
  k3_on = nil,
  k3_off = nil,
}

function Scene:create(o)
  -- create state if not provided
  o = o or {}

  -- define prototype
  setmetatable(o, self)
  self.__index = self

  -- return instance
  return o
end

local scenes = {
  {
    name = "start",
    render = render_home,
    e1 = nil,
    e2 = nil,
    e3 = nil,
    k1_hold_on = nil,
    k1_hold_off = nil,
    k2_on = nil,
    k2_off = nil,
    k3_on = nil,
    k3_off = nil,
  },
  {
    name = "mixer",
    render = render_mixer,
  },
}

current_scene_index = 1
local current_scene = scenes[current_scene_index]

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
  ready = true
end

rates = {}
pans = {}
levels = {}
positions = {}
loop_starts = {}
loop_ends = {}

function generate_random_pair(max_length)
  -- Generate a random number a
  local a = math.random(0, max_length)
  -- Generate b such that b > a and b - a <= max_length
  if max_length - a == 0 then
    max_length = max_length + 1 -- todo check if logic correct in all cases
  end
  local b = a + math.random(1, max_length - a)

  return a, b
end

function randomize_all()
  local rate_values_mid = { 0.5, 1, 2, -0.5, -1, -2 }
  local rate_values_low = { 0.25, 0.5, 1, -1, -.5, -.25 }
  local rate_values_sub = { 0.125, 0.25, 0.5, -0.5, -.25, -.125 }
  local rate_values = rate_values_low
  for i = 1, 6 do
    rates[i] = rate_values[math.random(#rate_values)]
    levels[i] = math.random() * 0.5 + 0.2
    pans[i] = 0.5 - math.random()
    loop_starts[i], loop_ends[i] = generate_random_pair(sample_length)
    positions[i] = 1 + math.random(8) * 0.25
    softcut.level(i, levels[i])
    softcut.rate(i, rates[i])
    softcut.position(i, positions[i])
    softcut.loop_start(i, math.random(10))
    softcut.loop_end(i, 10 + math.random(10))
  end
  print("rates:")
  print(rates[1])
end

function enable_all()
  local pan_locations = { -1, -.5, -.25, .25, .5, 1 }

  for i = 1, 6 do
    softcut.enable(i, 1)
    softcut.buffer(i, 1)
    softcut.loop(i, 1)
    softcut.play(i, 1)
    softcut.pan(i, pan_locations[i])
    softcut.fade_time(i, .2)
  end
end

function update_positions(i, pos)
  -- print("voice" .. i..":"..pos .. "loop: "..loop_starts[i].." - " .. loop_ends[i])
end

function init()
  -- init softcut
  -- file = _path.dust.."code/softcut-studies/lib/whirl1.aif"
  file = _path.dust .. "audio/etsuko/sea-minor/sea-minor-chords.wav"
  debug.print_info(file)
  sample_length = bits_sampler.get_duration(file)

  softcut.buffer_clear()

  --- buffer_read_mono (file, start_src, start_dst, dur, ch_src, ch_dst)
  start_src = 5
  start_dst = 0
  dur = 40
  ch_src = 1
  ch_dst = 1
  softcut.buffer_read_mono(file, start_src, start_dst, dur, ch_src, ch_dst)

  enable_all()
  randomize_all()

  softcut.phase_quant(1, 0.5)
  softcut.event_phase(update_positions)
  softcut.poll_start_phase()

  -- init rings, todo: should be in a separate file that defines this scene
  local y_offset = 18
  for i = 1, 6, 1 do
    -- these rings rotate according to playback rate
    rings[i] = Ring:new({
      x = i * 16 + 8, -- space evenly from x=24 to x=104
      y = 32 + y_offset + (-2 * y_offset * (i % 2)), -- 3 above, 3 below
      a1 = radians.A0,
      a2 = radians.A90,
      radius = 6,
      rate = rates[i],
      bg = 0,
      thickness = 3,
      level = 15, -- 15 = max level
    })
  end
  for i = 1, 6 do
    -- these rings display the looped section of the buffer
    rings2[i] = Ring:new({
      x = rings[i].x,
      y = rings[i].y,
      a1 = loop_starts[i] / sample_length * math.pi * 2,
      a2 = loop_ends[i] / sample_length * math.pi * 2,
      radius = rings[i].radius,
      rate = 0,
      bg = 5,
      level = 10,
      thickness = rings[i].thickness
    })
  end

  -- init clock
  c = metro.init(count, 1 / 60)
  c:start()
end

-- KEY DEFINITIONS
local key_latch = {
  [2] = false,
  [3] = false,
}
function select_ring(n)
  current_ring = n
  for i = 1, 6 do
    if i == current_ring then
      rings[i].level = 15
      rings2[i].bg = 5
      rings2[i].level = 10
    else
      rings[i].level = 5
      rings2[i].bg = 1
      rings2[i].level = 3
    end
  end
end
function one_indexed_modulo(n,m)
  -- utility to help cycling through 1-indexed arrays
  return ((n - 1) % m) + 1
end

function key(n, z)
  -- todo: add a dot to the selected ring
  print("key press: " .. n .. ", " .. z)
  if n == 3 and z == 1 then
    key_latch[n] = true
    next_ring = current_ring + 1
    select_ring(one_indexed_modulo(next_ring, 6))
    print("new selected ring = " .. current_ring)
    if key_latch[2] then
        -- key combination: k2 held, press k3
      cycle_scene_forward()
    end
    randomize_all()
  end
  if n == 3 and z == 0 then
    key_latch[n] = false
  end

  if n == 2 and z == 1 then
    key_latch[n] = true
    if key_latch[3] then
      -- key combination: k3 held, press k2
      cycle_scene_backward()
    end
  end
  if n == 2 and z == 0 then
    key_latch[n] = false
  end
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
end
