-- bits: 6-voice sample player
-- 1.0.0 @etsuko.fm
-- E1: scroll pages
--
-- Other controls, see footer:
-- | K2 | K3 | E2 | E3 |

_lfos = require 'lfo'
MusicUtil = require "musicutil"

local audio_util = include("bits/lib/util/audio_util")

local page_sampling = include("bits/lib/pages/sampling")
local page_sequencer = include("bits/lib/pages/sequencer")
local page_control = include("bits/lib/pages/control")
local page_panning = include("bits/lib/pages/panning")
local page_pitch = include("bits/lib/pages/pitch")
local page_levels = include("bits/lib/pages/levels")

local fps = 60
local ready

DEFAULT_FONT = 68
TITLE_FONT = 68
FOOTER_FONT = 68
state = {
  max_sample_length = 128.0, -- in seconds, longer samples are truncated

  -- time controls
  fade_time = 8/48000,                    -- crossfade when looping playback
}

local pages = {
  page_sampling,
  page_sequencer,
  page_control,
  page_panning,
  page_pitch,
  page_levels,
}

local current_page_index = 3
local current_page = pages[current_page_index]

local function page_forward()
  -- Increment the current page index, reset to 1 if we exceed the table length
  if current_page_index < #pages then
    current_page_index = current_page_index + 1
  end
  current_page = pages[current_page_index]
end

local function page_backward()
  -- Decrement the current page index, wrap around to the last page if it goes below 1
  if current_page_index > 1 then
    current_page_index = current_page_index - 1
  end
  current_page = pages[current_page_index]
end

local function count()
  -- relates to fps and flickerless rerndering
  ready = true
end


local function enable_all_voices()
  for i = 1, 6 do
    softcut.enable(i, 1)
    softcut.buffer(i, 1)
    softcut.loop(i, 0)
    softcut.fade_time(i, state.fade_time)
  end
end


function init()
  -- Params UX
  params:add_separator("BITS", "BITS")

  -- Encoder sensitivity
  norns.enc.sens(1, 5)

  for i = 2, 3 do
    norns.enc.sens(i, 1)
    norns.enc.accel(i, false)
  end

  for _, page in ipairs(pages) do
    page:initialize()
  end

  enable_all_voices()

  -- metro for screen refresh
  c = metro.init(count, 1 / fps)
  c:start()
end

function key(n, z)
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

function enc(n, d)
  if n == 1 then
    if d > 0 then
      page_forward()
    else
      page_backward()
    end
  end
  if n == 2 and current_page.e2 then
    current_page.e2(d)
    current_page.footer.active_knob = "e2"
  end
  if n == 3 and current_page.e3 then
    current_page.e3(d)
    current_page.footer.active_knob = "e3"
  end
end

function refresh()
  if ready then
    ready = false
    screen.clear()
    current_page:render()
    screen.update()
  end
end

-- convenience methods for matron
function rerun()
  norns.script.load(norns.state.script)
end

function off()
  for i = 1, 6 do
    softcut.play(i, 0)
  end
end

function on()
  for i = 1, 6 do
    softcut.play(i, 1)
  end
end
