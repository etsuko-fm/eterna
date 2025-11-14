-- Symbiosis
-- 0.9.12 @etsuko.fm
-- E1: scroll pages
--
-- Other controls, see footer:
-- | K2 | K3 | E2 | E3 |
engine.name = 'Symbiosis'

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

include("symbiosis/lib/parameters")

sym = include('symbiosis/lib/symbiosis_engine')

local page_sample = include("symbiosis/lib/pages/sample")
page_sequencer = include("symbiosis/lib/pages/sequencer")
local page_envelopes = include("symbiosis/lib/pages/envelopes")
local page_lpf = include("symbiosis/lib/pages/lpf")
local page_hpf = include("symbiosis/lib/pages/hpf")
local page_echo = include("symbiosis/lib/pages/echo")
local page_master = include("symbiosis/lib/pages/master")
page_control = include("symbiosis/lib/pages/control")
local page_panning = include("symbiosis/lib/pages/panning")
local page_rates = include("symbiosis/lib/pages/rates")
local page_levels = include("symbiosis/lib/pages/levels")
local fps = 45
local ready


UPDATE_SLICES = false

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
  page_lpf,
  page_hpf,
  --
  page_echo,
  page_master,
}

amp_historyL = {}
amp_historyR = {}

local current_page_index = 4
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

function sym.on_amp_history(left, right)
  page_master.amp_history[1] = left
  page_master.amp_history[2] = right
end

DB_FLOOR = -60

env_polls = {}
amp_polls = {}

function to_dBFS(x)
  -- TODO: move to util
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

  -- Enable engine module to process OSC from SuperCollider
  sym.install_osc_hook()

  -- Setup polls
  pre_comp_left_poll, pre_comp_right_poll = sym.get_polls("pre_comp")
  post_comp_left_poll, post_comp_right_poll = sym.get_polls("post_comp")
  post_gain_left_poll, post_gain_right_poll = sym.get_polls("post_gain")
  master_left_poll, master_right_poll = sym.get_polls("master")
  amp_polls = sym.get_polls("voice_amp", false)
  env_polls = sym.get_polls("voice_env", false)

  sym.add_params()

  -- Initialize pages
  for _, page in ipairs(pages) do
    page:initialize()
  end
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
        screen.rect(x, y + 3, 1, enc1n)
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
