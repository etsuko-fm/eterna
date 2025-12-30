-- eterna
-- 0.12.0 @etsuko.fm
-- E1: scroll pages
--
-- Other controls, see footer:
-- | K2 | K3 | E2 | E3 |
engine.name = 'Eterna'

_lfos = require 'lfo'
MusicUtil = require "musicutil"
local script = "eterna"
function from_root(path)
  return script .. "/" .. path
end

Page = include(from_root("lib/Page"))
Window = include(from_root("lib/graphics/Window"))
Footer = include(from_root("lib/graphics/Footer"))
audio_util = include(from_root("lib/util/audio_util"))
lfo_util = include(from_root("lib/util/lfo"))
misc_util = include(from_root("lib/util/misc"))
sequence_util = include(from_root("lib/util/sequence"))
graphic_util = include(from_root("lib/util/graphic"))

engine_lib = include(from_root("lib/eterna-engine"))

include(from_root("lib/parameters"))


local page_sample = include(from_root("lib/pages/sample"))
page_slice = include(from_root("lib/pages/slice"))
page_sequencer = include(from_root("lib/pages/sequencer"))
local page_envelopes = include(from_root("lib/pages/envelopes"))
page_lpf = include(from_root("lib/pages/lpf"))
local page_lpf_lfo = include(from_root("lib/pages/lpf_lfo"))
page_hpf = include(from_root("lib/pages/hpf"))
local page_hpf_lfo = include(from_root("lib/pages/hpf_lfo"))
local page_echo = include(from_root("lib/pages/echo"))
local page_master = include(from_root("lib/pages/master"))
page_control = include(from_root("lib/pages/control"))
local page_panning = include(from_root("lib/pages/panning"))
local page_rates = include(from_root("lib/pages/rates"))
local page_levels = include(from_root("lib/pages/levels"))
draw_frame = false -- indicates if the next frame should be drawn
local page_indicator_counter = 0
window = Window:new({ title = "ETERNA" })

UPDATE_SLICES = false

window:set("page_indicator_disabled", false)

DEFAULT_FONT = 68
TITLE_FONT = 68
FOOTER_FONT = 68

local pages = {
  -- sample
  page_sample,
  page_slice,
  -- voice settings
  page_envelopes,
  page_rates,
  page_levels,
  page_panning,
  -- sequencer
  page_sequencer,
  page_control,
  -- processing
  page_lpf,
  page_lpf_lfo,
  page_hpf,
  page_hpf_lfo,
  page_echo,
  -- output
  page_master,
}


amp_historyL = {}
amp_historyR = {}

local current_page_index = 1
local current_page = pages[current_page_index]

window:set("num_pages", #pages)
window:set("current_page", current_page_index)

local function switch_page(new_index)
  if new_index ~= current_page_index and pages[new_index] then
    current_page:exit()
    current_page_index = new_index
    current_page = pages[current_page_index]
    current_page:enter()
    window.current_page = current_page_index
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

function engine_lib.on_amp_history(left, right)
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
  engine_lib.install_osc_hook()

  -- Setup polls
  pre_comp_left_poll, pre_comp_right_poll = engine_lib.get_polls("pre_comp")
  post_comp_left_poll, post_comp_right_poll = engine_lib.get_polls("post_comp")
  post_gain_left_poll, post_gain_right_poll = engine_lib.get_polls("post_gain")
  master_left_poll, master_right_poll = engine_lib.get_polls("master")
  amp_polls = engine_lib.get_polls("voice_amp", false)
  env_polls = engine_lib.get_polls("voice_env", false)

  engine_lib.add_params()

  -- Initialize pages
  for _, page in ipairs(pages) do
    page:initialize()
  end

  params:bang()

  -- check supercollider connection
  print("pinging supercollider...")
  engine_lib.ping()
end

engine_lib.on_pong = function()
  print("connection verified")
  current_page:enter()
  draw_frame = true
end

params.action_read = function(filename, silent, number)
  -- switch to first page after loading a pset
  switch_page(1)
end

function key(n, z)
  -- K1/K2/K3 controls whatever is assigned to them on the current page
  if n == 1 and z == 0 and current_page.k1_off then current_page.k1_off() end
  if n == 1 and z == 1 and current_page.k1_on then current_page.k1_on() end

  if n == 2 and z == 0 and current_page.k2_off then
    current_page.k2_off()
    current_page.footer:set("active_knob", "k2")
  end
  if n == 2 and z == 1 and current_page.k2_on then
    current_page.k2_on()
    current_page.footer:set("active_knob", "k2")
  end
  if n == 3 and z == 0 and current_page.k3_off then
    current_page.k3_off()
    current_page.footer:set("active_knob", "k3")
  end
  if n == 3 and z == 1 and current_page.k3_on then
    current_page.k3_on()
    current_page.footer:set("active_knob", "k3")
  end
end

local counter = 0

function enc(n, d)
  -- E1 cycles pages
  if n == 1 then
    counter = 0 -- reset
    if (current_page_index < #pages and d > 0) or current_page_index > 1 and d < 0 then
      window:set("enc1n", window.enc1n + d)
    end

    if window.enc1n > 3 then
      page_forward()
      window:set("enc1n", 0)
    elseif window.enc1n < -3 then
      page_backward()
      window:set("enc1n", 0)
    end
  end

  -- E2/E3 controls whatever is assigned to them on the current page
  if n == 2 and current_page.e2 then
    current_page.e2(d)
    current_page.footer:set("active_knob", "e2")
  end

  if n == 3 and current_page.e3 then
    current_page.e3(d)
    current_page.footer:set("active_knob", "e3")
  end
end

function redraw()
  -- called when returning from a sys menu
  draw_frame = true
  refresh(true)
end

function refresh(force)
  -- called at the completion of an actual screen redraw: https://llllllll.co/t/norns-update-231114/64915/62?page=4
  -- driver runs at 1/60fps
  -- FPS-based timer for the page indicator animation
  page_indicator_counter = page_indicator_counter + 1

  if draw_frame then
    -- prevent new screen events being queued until this frame is done
    draw_frame = false

    -- actual render
    render_frame(force)

    -- for frame indicator animation (90fps until reset)
    -- TODO this should really be time-based
    if window.enc1n ~= 0 and page_indicator_counter > 90 then
      window:set("enc1n", 0)
      page_indicator_counter = 0
    end
  end
end

function render_frame(force)
  if window.enc1n ~= 0 and counter > 90 then
    window:set("enc1n", 0)
    counter = 0
  end
  current_page:render(force)
  draw_frame = true
end

-- convenience methods for matron
function rerun()
  norns.script.load(norns.state.script)
end

function shot()
  local name = "screenshot-" .. os.date("%Y-%m-%d-%H-%M-%S")
  screen.export_screenshot(name)
  print("screenshot saved to " .. name)
end

function cleanup()
  metro.free_all()
  current_page:exit()
end
