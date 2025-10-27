-- Symbiosis
-- 1.0.0 @etsuko.fm
-- E1: scroll pages
--
-- Other controls, see footer:
-- | K2 | K3 | E2 | E3 |

_lfos = require 'lfo'
MusicUtil = require "musicutil"

Page = include("symbiosis/lib/Page")
Window = include("symbiosis/lib/graphics/Window")
Footer = include("symbiosis/lib/graphics/Footer")
audio_util = include("symbiosis/lib/util/audio_util")
lfo_util = include("symbiosis/lib/util/lfo")
misc_util = include("symbiosis/lib/util/misc")
sequence_util = include("symbiosis/lib/util/sequence")
graphic_util = include("symbiosis/lib/util/graphic")

include("symbiosis/lib/parameters/global")
include("symbiosis/lib/parameters/slice")
include("symbiosis/lib/parameters/sequencer")
include("symbiosis/lib/parameters/envelopes")
include("symbiosis/lib/parameters/rates")
include("symbiosis/lib/parameters/levels")
include("symbiosis/lib/parameters/panning")
include("symbiosis/lib/parameters/filter")
include("symbiosis/lib/parameters/echo")
include("symbiosis/lib/parameters/master")

include("symbiosis/lib/tests")

local page_sample = include("symbiosis/lib/pages/sample")
page_sequencer = include("symbiosis/lib/pages/sequencer")
local page_envelopes = include("symbiosis/lib/pages/envelopes")
local page_filter = include("symbiosis/lib/pages/filter")
local page_echo = include("symbiosis/lib/pages/echo")
local page_master = include("symbiosis/lib/pages/master")
page_control = include("symbiosis/lib/pages/control")
local page_panning = include("symbiosis/lib/pages/panning")
local page_rates = include("symbiosis/lib/pages/rates")
local page_levels = include("symbiosis/lib/pages/levels")
local fps = 45
local ready


UPDATE_SLICES = false
engine.name = 'Symbiosis'

grid_device = grid.connect()

page_indicator_disabled = false

DEFAULT_FONT = 68
TITLE_FONT = 68
FOOTER_FONT = 68

local pages = {
  --
  page_sample,
  page_sequencer,
  page_control,
  --
  page_envelopes,
  page_rates,
  page_levels,
  --
  page_panning,
  page_filter,
  page_echo,
  --
  page_master,
}

amp_historyL = {}
amp_historyR = {}

local current_page_index = 1
local current_page = pages[current_page_index]

local function switch_page(new_index)
  if new_index ~= current_page_index and pages[new_index] then
    current_page:exit()
    current_page_index = new_index
    current_page = pages[current_page_index]
    current_page:enter()
  end
end

local function page_forward()
  if current_page_index < #pages then
    switch_page(current_page_index + 1)
  end
end

local function page_backward()
  if current_page_index > 1 then
    switch_page(current_page_index - 1)
  end
end

local function count()
  ready = true -- used for fps
end

local midi_device = {}
local midi_device_names = {}
local midi_target

function midi_to_hz(note)
  local hz = (440 / 32) * (2 ^ ((note - 9) / 12))
  return hz
end

function midi_cb(data)
  local d = midi.to_msg(data)
  if d.type == "note_on" then
    engine.filter_freq(midi_to_hz(d.note))
  end
end

function blob_to_table(blob, len)
  -- converts OSC blobs, assuming to be an array of 32 bit integers, to a lua table
  local ints = {}
  local size = #blob
  local offset = 1

  while offset <= size do
    -- iterate over blob, starting at `offset` (1 = first char)
    local value
    -- Unpack using ">i1" for big-endian single-byte integer, see lua docs 6.4.2
    value, offset = string.unpack(">i1", blob, offset)
    table.insert(ints, value)
  end

  return ints
end


function osc.event(path, args, from)
  if path == "/waveform" then
    print("Lua: /waveform received from SC")
    local blob = args[1] -- the int8 array from OSC
    local channel = args[2] -- 0 or 1 for left, right
    print('channel: '.. tonumber(channel))
    local waveform = blob_to_table(blob)
    for i, v in ipairs(waveform) do
      -- convert int8 array to floats
      waveform[i] = waveform[i] / 127
    end
    page_sample:update_waveform(waveform, channel+1)
  elseif path == "/duration" then
    local duration = tonumber(args[1])
    print('received duration: ' .. duration)
    page_sample:set_sample_duration(duration)
  elseif path == "/amp_history_left" then
    local blob = args[1]
    amp_historyL = blob_to_table(blob)
  elseif path == "/amp_history_right" then
    local blob = args[1]
    amp_historyR = blob_to_table(blob)
  end
end

DB_FLOOR = -60

env_polls = {}
amp_polls = {}

function to_dBFS(x)
  -- x: 0 to 1
  local floor = DB_FLOOR
  if x <= 0 then return floor end
  local db = 20 * math.log(x, 10)
  if db < floor then return floor else return db end
end

function amp_to_log(amp)
  -- converts linear range to logarithmic range used by decibels
  local floor = DB_FLOOR
  if amp <= 0 then return 0.0 end
  local db = to_dBFS(amp)
  return (db - floor) / -floor -- normalize to 0..1
end

function init()
  -- Encoder sensitivity
  norns.enc.sens(1, 2)

  for i = 2, 3 do
    norns.enc.sens(i, 1)
    norns.enc.accel(i, false)
  end

  loaded_poll = poll.set("file_loaded")

  for i = 1,6 do amp_polls[i] = poll.set("voice" .. i .. "amp") end
  for i = 1,6 do env_polls[i] = poll.set("voice" .. i .. "env") end

  pre_comp_left_poll = poll.set("pre_comp_left")
  pre_comp_right_poll = poll.set("pre_comp_right")
  post_comp_left_poll = poll.set("post_comp_left")
  post_comp_right_poll = poll.set("post_comp_right")
  post_gain_left_poll = poll.set("post_gain_left")
  post_gain_right_poll = poll.set("post_gain_right")
  master_left_poll = poll.set("master_left")
  master_right_poll = poll.set("master_right")

  for _, page in ipairs(pages) do
    page:initialize()
  end
  params:bang()

  for i = 1, #midi.vports do         -- query all ports
    midi_device[i] = midi.connect(i) -- connect each device
    table.insert(
      midi_device_names,
      i .. ": " .. util.trim_string_to_width(midi_device[i].name, 38) -- value to insert
    )
  end
  params:add_option("midi keyboard", "midi keyboard", midi_device_names, 1)
  params:set_action("midi keyboard",
    function(x)
      if midi_target then midi_target.event = nil end
      midi_target = midi_device[x]
      midi_target.event = midi_cb
    end
  )
  params:bang()

  -- metro for screen refresh
  c = metro.init(count, 1 / fps)
  c:start()
end

clock.tempo_change_handler = function(bpm)
  recalculate_echo_time(bpm)
end



function key(n, z)
  -- K1/K2/K3 controls whatever is assigned to them on the current page
  if n == 1 and z == 0 and current_page.k1_off then current_page.k1_off() end
  if n == 1 and z == 1 and current_page.k1_on then current_page.k1_on() end

  if n == 2 and z == 0 and current_page.k2_off then
    current_page.k2_off()
    current_page.footer.active_knob = "k2"
  end
  if n == 2 and z == 1 and current_page.k2_on then
    current_page.k2_on()
    current_page.footer.active_knob = "k2"
  end
  if n == 3 and z == 0 and current_page.k3_off then
    current_page.k3_off()
    current_page.footer.active_knob = "k3"
  end
  if n == 3 and z == 1 and current_page.k3_on then
    current_page.k3_on()
    current_page.footer.active_knob = "k3"
  end
end

local enc1n = 0
local counter = 0

function enc(n, d)
  -- E1 cycles pages
  if n == 1 then
    counter = 0 -- reset
    if (current_page_index < #pages and d > 0) or current_page_index > 1 and d < 0 then
      enc1n = enc1n + d
    end

    if enc1n > 3 then
      page_forward()
      enc1n = 0
    elseif enc1n < -3 then
      page_backward()
      enc1n = 0
    end
  end

  -- E2/E3 controls whatever is assigned to them on the current page
  if n == 2 and current_page.e2 then
    current_page.e2(d)
    current_page.footer.active_knob = "e2"
  end

  if n == 3 and current_page.e3 then
    current_page.e3(d)
    current_page.footer.active_knob = "e3"
  end
end

local function draw_page_indicator()
  -- draw stripes on top left that indicate which page is active
  screen.level(11)
  local h
  local y
  for i = 0, #pages - 1 do
    h = 3
    local x = 2 + i * 2
    if pages[i + 1] == current_page then
      y = 2
      screen.level(0)
      screen.rect(2 + i * 2, y, 1, h)
      screen.fill()
      screen.level(3)
      if enc1n > 0 then
        -- line from bottom to top
        screen.rect(x, y, 1, enc1n)
      elseif enc1n < 0 then
        -- line from top to bottom
        screen.rect(x, y+3, 1, enc1n)
      end
    else
      screen.level(6)
      y = 2
      screen.rect(x, y, 1, h)
    end
    screen.fill()
  end
end


function refresh()
  counter = counter + 1
  -- refresh screen
  if ready then
    ready = false
    screen.clear()
    current_page:render()
    if enc1n ~= 0 and counter > 120 then
      enc1n = 0
      counter = 0
    end
    enc1n = enc1n
    -- todo: move this rendering to the Window class
    if not page_indicator_disabled then
      draw_page_indicator()
    end
    screen.update()
  end
end

-- convenience methods for matron
function rerun()
  norns.script.load(norns.state.script)
end

function cleanup()
  metro.free_all()
  poll.clear_all()
end
