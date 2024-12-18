local Ring = include("bits/lib/Ring")
local Meter = include("bits/lib/Meter")
local Scene = include("bits/lib/Scene")
local debug = include("bits/lib/debug")
local bits_sampler = include("bits/lib/sampler")
local shapes = include("bits/lib/graphics/shapes")
local rings = {}
local sample_length
local current_ring = nil
local current_param = nil
local current_param_value = nil
local zigzag_line = nil
local edit_mode = false
-- todo: everything with "current" could be saved in in a state table

local ring_luma = {
  -- todo: could these be properties of the ring?
  -- so add when initializing
  circle = {
    normal = 3,
    deselected = 1,
  },
  rate_arc = {
    normal = 15,
    deselected = 5,
  },
  section_arc = {
    normal = 7,
    deselected = 2,
  },
}


function render_mixer()
  screen.clear()
  screen.font_size(8)
  screen.move(20, 20)
  screen.text('scene 2')
  screen.update()
end

radians = {
  A0 = 0,                -- 3 o'clock
  A90 = math.pi / 2,     -- 6 o'clock
  A180 = math.pi,        -- 9 o'clock
  A270 = 3 * math.pi / 2 -- 12 o'clock
}

-- todo: before randomizing, allow emphasis on low, mid or high

function render_home(stage)
  screen.clear()
  for i = 1, 6, 1 do
    rings[i]:render()
  end
  
  if zigzag_line then
    zigzag_line:render()
  end

  if current_param then
    render_param_text(current_param, current_param_value)
  end
end

local scenes = {
  Scene:create({
    name = "home",
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
  }),
  Scene:create({
    name = "mixer",
    render = render_mixer,
  }),
}

current_scene_index = 1
local current_scene = scenes[current_scene_index]


-- todo: this is great re-usable functionality, move to lib; also confusing otherwise
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

function generate_loop_segment(sample_dur)
  -- Generate a pair of numbers (a, b) reflecting a loop segment.
  -- a = loop start, b = loop end
  -- a < b < sample duration

  print("sample_dur" .. sample_dur)

  -- limit the maximium loop length
  max_length = 1

  -- introduce some padding so that a isn't closer than 1% to the sample end
  padding = sample_dur / 100

  -- pick start position
  local a = math.random() * (sample_length - padding)

  -- End position is such that a < b < sample duration
  local b = a + (math.random() * (max_length - a))
  return a, b
end

function randomize_all()
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
    print(i .. ": a=" .. loop_starts[i] .. "  b=" .. loop_ends[i] )

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


function enable_all_voices()
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

function load_sample(file)
  -- this could be moved to some audio util module, you'll need it every project
  -- it should support both mono and stereo
  debug.print_info(file)
  softcut.buffer_clear()
  sample_length = bits_sampler.get_duration(file)
  print("sample length: ".. sample_length)
  start_src = 0
  start_dst = 0
  dur = 40
  ch_src = 1
  ch_dst = 1
  softcut.buffer_read_mono(file, start_src, start_dst, dur, ch_src, ch_dst)
  randomize_all()
end

function create_rings()
  -- init rings. todo: should be in a separate file that defines this scene
  local y_offset = 18
  zigzag_line = shapes.ZigZagLine:new({0, 32, 128, 4, 4})
  for i = 1, 6, 1 do
    -- these rings rotate according to playback rate
    rings[i] = Ring:new({
      x = i * 16 + 8,                                -- space evenly from x=24 to x=104
      y = 32 + y_offset + (-2 * y_offset * (i % 2)), -- 3 above, 3 below
      radius = 6,
      thickness = 3,
      luma = ring_luma.circle.normal, -- 15 = max level
      arcs = {
        -- {
        --   -- loop section arc
        --   a1 = loop_starts[i] / sample_length * math.pi * 2,
        --   a2 = loop_ends[i] / sample_length * math.pi * 2,
        --   luma = ring_luma.section_arc.normal,
        --   thickness = 3, -- pixels
        --   radius = 6,    -- pixels
        --   rate = 0,
        -- },
        {
          -- playback rate arc
          a1 = radians.A0,
          a2 = radians.A90,
          luma = ring_luma.rate_arc.normal, -- brightness, 0-15
          thickness = 3,                    -- pixels
          radius = 6,                       -- pixels
          rate = rates[i] / 10,
        },
      }
    })
  end
  
end


function init()
  -- hardware sensitivity
  for i = 1,3 do
    norns.enc.sens(i, 6)
    norns.enc.accel(i, true)
  end

  -- file selection
  params:add_separator("bits","bits")
  params:add_file('audio_file_1', 'file')
  params:set_action("audio_file_1", function(file) load_sample(file) end)

  -- params:add_number('max_granularity')

  -- init softcut
  load_sample(_path.dust  .. "audio/etsuko/sea-minor/sea-minor-chords.wav")
  softcut.phase_quant(1, 0.5)
  softcut.event_phase(update_positions)
  softcut.poll_start_phase()

  create_rings()
  enable_all_voices()


  -- init clock
  c = metro.init(count, 1 / 60)
  c:start()
end


function select_ring(n)
  current_ring = n
  for i = 1, 6 do
    if i == current_ring then
      rings[i].luma = ring_luma.circle.normal
      rings[i].arcs[1].luma = ring_luma.rate_arc.normal
      rings[i].selected = true
    else
      rings[i].luma = ring_luma.circle.deselected
      rings[i].arcs[1].luma = ring_luma.rate_arc.deselected
      rings[i].selected = false
    end
  end
end

function deselect_rings()
  for i = 1, 6 do
    rings[i].luma = ring_luma.circle.normal
    rings[i].arcs[1].luma = ring_luma.rate_arc.normal
    rings[i].selected = false
  end
  current_ring = nil
end

function one_indexed_modulo(n, m)
  -- utility to help cycling through 1-indexed arrays
  -- todo: move to util
  return ((n - 1) % m) + 1
end

function select_next_ring()
  if current_ring == nil then current_ring = 0 end
  next_ring = current_ring + 1
  if current_ring == 6 then
    current_ring = nil
    deselect_rings()
  else
    select_ring(one_indexed_modulo(next_ring, 6))
  end
end

local keycombo = false
function key(n, z)
    -- K2
    if n == 2 and z == 0 then
      if not edit_mode then
        print("next ring")
        select_next_ring()
      end

    end

  -- K3
  if n == 3 and z == 1 then
    if current_ring ~= nil then
      edit_mode = not edit_mode
      print("edit mode " .. tostring(edit_mode))
      if edit_mode then
        -- hide other rings
        -- hide zigzag 
        -- show rate param
        -- show solo/mute param
        zigzag_line.hide = true
        for i = 1,6 do
          if i ~= current_ring then
            rings[i].hide = true
          end
        end
      else
        zigzag_line.hide = false
        for i = 1,6 do
            rings[i].hide = false
        end
      end

    end
    randomize_all()
  end
end


function enc(n,d)
  if n == 1 then
    audio.adjust_output_level(d/100)
  end
  if n == 2 then
    print(d)
    current_param = "rate"
    if current_param_value == nil then
      current_param_value = 0
    end
    current_param_value = current_param_value + d
  end
end

function render_param_text(param, value)
  -- screen.level(15)
  -- screen.move(64,32)
  -- screen.text_center(param ..": "..value)
  -- screen.update()
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
