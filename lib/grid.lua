-- sequencer values can be retrieved/set via STEPS_GRID[track][step]
local grid_conn = { active = false, changed = false }
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
    -- could still do this, but not sure if current page should really be a state param
    -- params:set_action(ID_CURRENT_PAGE,
    --     function(v) switch_page(page_map[v]) end
    -- )
end

function grid_conn:key_press(x, y)
    if y == page_row then
        self:select_page(x)
    elseif y < 7 then
        local state = misc_util.toggle_param(STEPS_GRID[y][x]) -- 0 or 1
        self.device:led(x, y, state * midplus) -- should be velocity
        self.device:refresh()
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

function grid_conn:reset_sequence_leds()
    for y = 1, 6 do
        for x = 1, 16 do
            self.device:led(x, y, 0)
        end
    end
    self.device:refresh()
end

function grid_conn:set_cell(x, y, level)
    self.device:led(x, y, util.round(level))
    self.changed = true
    -- refresh call responsibility of the caller
end

function grid_conn:refresh()
    if not self.active then return end
    if self.changed then
        self.device:refresh()
        self.changed = false
    end
end

function grid_conn:init(device, current_page_id)
    self.active = true
    add_params()
    self.device = device
    self:reset_page_leds()
    self.device:led(current_page_id, page_row, midplus)
    device:refresh()
end

return grid_conn
