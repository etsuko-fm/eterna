-- sequencer values can be retrieved/set via ID_SEQ_STEP_GRID[track][step]
local grid_conn = {}
local low = 2
local mid = 4
local midplus = 10
local high = 15
local leds = { mid, low, mid, low, low, low, mid, low, mid, low, mid, low, mid, mid }
local page_row = 8

-- maps page name to page number
local page_map = {
    SAMPLE = 1,
    SLICE = 2,
    ENVELOPES = 3,
    PLAYBACK_RATES = 4,
    LEVELS = 5,
    PANNING = 6,
    SEQUENCER = 7,
    ["SEQUENCE CONTROL"] = 8,
    LOWPASS = 9,
    ["LOWPASS LFO"] = 10,
    HIGHPASS = 11,
    ["HIGHPASS_LFO"] = 12,
    ECHO = 13,
    MASTER = 14,
}

local function add_params()
    params:set_action(ID_CURRENT_PAGE,
        function(v) switch_page(page_map[v]) end
    )
end

function grid_conn:key_press(x, y)
    if y == page_row then
        self:select_page(x)
    end
end

function grid_conn:select_page(x)
    if x <= 14 then
        self:reset_page_leds()
        switch_page(x)
        self.device:led(x, page_row, midplus)
        self.device:refresh()
    end
end

grid.key = function(x, y, z)
    if z == 1 then grid_conn:key_press(x, y) end
end

function grid_conn:reset_page_leds()
    for x = 1, 14 do
        self.device:led(x, 8, leds[x])
    end
end

function grid_conn:init(device, current_page_id)
    self.device = device
    self:reset_page_leds()
    self.device:led(current_page_id, page_row, midplus)
    device:refresh()
end

-- bottom 2 grid rows
-- x x x x x x x x x x x x x x x x
-- x x x x x x x x x x x x x x x x
-- s - - - - - - s - l - h - - - -
-- s - e p l p - s - l - h - e m >

-- s s e p l p - s s l l h h - e m
return grid_conn
