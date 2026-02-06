-- sequencer values can be retrieved/set via STEPS[track][step]
local grid_conn = { active = false, changed = false }
local low = 2
local mid = 4
local midplus = 10
local high = 15
local leds = { mid, low, mid, low, low, low, mid, low, mid, low, mid, low, mid, mid }
local page_row = 8

function grid_conn:key_press(x, y)
    redraw()
    if y == page_row then
        self:select_page(x)
    elseif y <= NUM_TRACKS then
        if params:string(ID_SEQ_SOURCE) ~= SOURCE_GRID then
            -- #2 = SOURCE_GRID... there's not really a built-in neat way to do it
            params:set(ID_SEQ_SOURCE, 2)
            print('Perlin noise sequence was active, but grid button pressed; switching mode')
        end
        local center = params:get(ID_SEQ_VEL_CENTER)
        local spread = params:get(ID_SEQ_VEL_SPREAD)
        local on = params:get(STEPS[y][x]) > 0
        local velocity = 0
        if not on then
            -- if cell was off, turn it on by assigning a velocity
            velocity = page_sequencer:generate_random_velocity(x, y, center, spread)
        end
        params:set(STEPS[y][x], velocity)
        self:set_cell(x, y, velocity * 15)
        self.device:refresh()
    end
end

function grid_conn:select_page(x)
    -- x: index of page, 1-based
    if x <= NUM_PAGES then
        self:reset_page_leds()
        switch_page(x)
        self.device:led(x, page_row, midplus)
        self.device:refresh()
    end
end

function grid_conn:set_current_step(current_step)
    self.current_step = current_step

    -- reset leds on row 7 (sequence stepper)
    for x = 1, 16 do
        self.device:led(x, 7, low)
    end
    -- light up active step
    self.device:led(current_step, 7, midplus)

    for y = 1, 6 do
        -- reset all to actual velocity level
        for x = 1, 16 do
            local param_id = STEPS[y][x]
            local velocity = params:get(param_id)
            self:set_cell(x, y, velocity * 15)
            if current_step == x and velocity > 0 then
                -- flash
                self.device:led(x, y, high)
            end
        end
    end
    self.device:refresh()
end

function grid_conn:set_current_page(page)
    self:reset_page_leds()
    self.device:led(page, 8, midplus)
    self.device:refresh()
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
    self.device:led(x, y, math.ceil(level))
    self.changed = true
    -- refresh call responsibility of the caller
end

function grid_conn:display_sequence()

end

function grid_conn:refresh()
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
    print('grid connection init')
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
