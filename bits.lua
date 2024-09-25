local Ring = include("bits/lib/Ring")
local debug = include("bits/lib/debug")
local bits_sampler = include("bits/lib/sampler")
local rings = {}
local rings2 = {}
local sample_length

function render_mixer()
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
  render_zigzag()
end

local scenes = {
  start = {
    render = render_home,
    e1 = nil,
    e2 = nil,
    e3 = nil,
    k1 = nil,
    k2 = nil,
    k3 = nil,
  },
  mixer = {
    render = render_mixer,
  },
}

local current_scene = scenes["start"]

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

  -- init rings
  local y_offset = 18
  for i = 1, 6, 1 do
    rings[i] = Ring:new({
      x = i * 16 + 8,
      y = 32 + y_offset + (-2 * y_offset * (i % 2)),
      a1 = radians.A0,
      a2 = radians.A90,
      radius = 6,
      rate = rates[i],
      bg = 0,
      thickness = 3,
      level = 15,
    })
  end
  for i = 1, 6, 1 do
    rings2[i] = Ring:new({
      x = i * 16 + 8,
      y = 32 + y_offset + (-2 * y_offset * (i % 2)),
      a1 = loop_starts[i] / sample_length * math.pi * 2,
      a2 = loop_ends[i] / sample_length * math.pi * 2,
      radius = 6,
      rate = 0,
      bg = 1,
      level = 4,
      thickness = 3
    })
  end

  -- init clock
  c = metro.init(count, 1 / 60)
  c:start()
end

function key(n, z)
  if n == 3 and z == 1 then
    randomize_all()
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
