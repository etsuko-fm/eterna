-- sequencer values can be retrieved/set via STEPS[track][step]
local grid_conn = { active = false, changed = false }
local low = 2
local mid = 4
local midplus = 10
local high = 15
local page_leds = { mid, low, mid, low, low, low, mid, low, mid, low, mid, low, mid, mid }
local page_row = 8

function grid_conn:key_press(x, y)
    redraw()
    if y == page_row then
        self:select_page(x)
    elseif y <= NUM_TRACKS then
        local on = params:get(STEPS[y][x]) > 0
        local velocity = 0
        if not on then
            -- if cell was off, turn it on by assigning a velocity
            local center = params:get(ID_SEQ_VEL_CENTER)
            local spread = params:get(ID_SEQ_VEL_SPREAD)
            velocity = page_sequencer:generate_velocity(x, y, center, spread)
        end
        params:set(STEPS[y][x], velocity)
        -- if perlin noise was queued to be renegerated, cancel it, because
        -- it's overwritten now by manual grid sequence editing
        page_sequencer:toggle_regenerate_perlin(false)
        -- indicate that the perlin noise params are not reflected exactly in the sequence anymore
        params:set(ID_SEQ_PERLIN_MODIFIED, 1)
        self:led(x, y, velocity * 15)
        self:refresh()
    end
end

function grid_conn:select_page(x)
    -- x: index of page, 1-based
    if x <= NUM_PAGES then
        self:reset_page_leds()
        switch_page(x)
        self:led(x, page_row, midplus)
        self:refresh()
    end
end

function grid_conn:set_current_step(current_step)
    if not self.active then return end
    self.current_step = current_step --int: 1 to 16

    -- reset leds on row 7 (sequence stepper)
    for x = 1, 16 do
        self:led(x, 7, low)
    end

    -- light up active step on step indicator row
    self:led(current_step, 7, midplus)

    for y = 1, 6 do
        -- set all to actual velocity level (incl previous column which may have flashed)
        for x = 1, 16 do
            local param_id = STEPS[y][x]
            local velocity = params:get(param_id)
            self:led(x, y, velocity * 15)
            if current_step == x and velocity > 0 then
                -- flash active step
                self:led(x, y, high)
            end
        end
    end
    self:refresh()
end

function grid_conn:set_current_page(page)
    self:reset_page_leds()
    self:led(page, 8, midplus)
    self:refresh()
end

grid.key = function(x, y, z)
    if z == 1 then grid_conn:key_press(x, y) end
end

function grid_conn:reset_page_leds()
    for x = 1, 14 do
        self:led(x, 8, page_leds[x])
    end
end

grid_conn.grid_state = {}

local function populate_grid_state()
    for x = 1, 16 do
        grid_conn.grid_state[x] = {}
        for y = 1, 8 do
            grid_conn.grid_state[x][y] = 0
        end
    end
end

function grid_conn:led(x, y, val)
    if not self.active then return end

    -- level should be an integer value
    local level = math.ceil(val)

    -- update shadow state for testability
    self.grid_state[x][y] = level

    -- set actual led on grid
    self.device:led(x, y, level)

    -- mark for device refresh; refresh call responsibility of the caller
    self.changed = true
end

function grid_conn:reset_sequence_leds()
    for y = 1, 6 do
        for x = 1, 16 do
            self:led(x, y, 0)
        end
    end
    self:refresh()
end

function grid_conn:refresh()
    -- updated the physical lights
    if not self.active then return end
    if self.changed then
        self.device:refresh()
        self.changed = false
    end
end

function grid_conn:set_transport(state)
    self.is_playing = state
end

function grid_conn:init(device, current_page_id)
    populate_grid_state()
    self.is_playing = false
    self.active = true
    self.device = device
    self:reset_page_leds()
    self.device:led(current_page_id, page_row, midplus)
    device:refresh()
    page_sequencer:display_active_sequence()
    self:set_current_step(1)
    print('grid connection init done')
end

function grid_conn:close(device)
    print('grid connection closed')
    self.active = false
end

return grid_conn
