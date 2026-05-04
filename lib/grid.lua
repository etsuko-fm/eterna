-- sequencer values can be retrieved/set via STEPS[voice][step]
local DoubleTapState = include(from_root("lib/util/double_tap"))
local ComboDetector = include(from_root("lib/util/key_combo"))

local grid_conn = { active = false, changed = false, loop_start = 1, loop_end = 16 }
local OFF = 0
local LOW = 2
local MID = 4
local MIDPLUS = 10
local HIGH = 15
local page_leds = { MID, LOW, MID, LOW, LOW, LOW, MID, LOW, MID, LOW, MID, MID }
local LOOP_ROW = 7
local PAGE_ROW = 8
local transport_led = { x = 16, y = 8 }

-- NB: Main module refreshes grid leds at the same rate of the screen (60FPS),
-- given there are changes (read via grid_conn.changed)
-- if changes are required without that 0-16ms delay, self:refresh() can be used
-- TODO: would be fine to write the grid refresh logic with a clock in this module instead;
-- activate it when self.active == true

grid.key = function(x, y, z)
    if z == 1 then
        grid_conn:key_press(x, y)
    else
        grid_conn:key_release(x, y)
    end
end

function grid_conn:modify_sequence(step, voice)
    -- use Y1-6 to modify sequence
    local on = params:get(STEPS[voice][step]) > 0
    local velocity = 0
    if not on then
        -- if cell was off, turn it on by assigning a velocity
        local center = params:get(ID_SEQ_VEL_CENTER)
        local spread = params:get(ID_SEQ_VEL_SPREAD)
        velocity = sequence_util.generate_velocity(center, spread, step)
    end
    params:set(STEPS[voice][step], velocity)
    -- if perlin noise was queued to be renegerated, cancel it, because
    -- it's overwritten now by manual grid sequence editing
    page_sequencer:toggle_regenerate_perlin(false)
    -- indicate that the perlin noise params are not reflected exactly in the sequence anymore
    params:set(ID_SEQ_PERLIN_MODIFIED, 1)
    self:led(step, voice, velocity * 15)
    -- self:refresh()
end

local function update_loop_range_params(loop_start, loop_end)
    print('setting loop range to: ' .. loop_start .. ":" .. loop_end)
    local num_steps = 1 + loop_end - loop_start
    -- for norns-native ux, the step start is limited when twisting E2;
    -- this should be temporarily undone when grid is setting step start,
    -- as grid can set the loop range to anything.
    -- The action connected to ID_SEQ_STEP_START, will re-apply it afterwards.
    controlspec_step_start.maxval = 16
    controlspec_step_start.quantum = 1 / 16
    params:set(ID_SEQ_STEP_START, loop_start)
    params:set(ID_SEQ_NUM_STEPS, num_steps)
end

function grid_conn:key_press(x, y)
    -- wake screen if any grid button is touched
    screen.ping()
    if x <= NUM_PAGES and y == PAGE_ROW then
        -- browse page on norns screen
        self:select_page(x)
    elseif y == LOOP_ROW then
        -- `result` is a table of two values if 2 different buttons on the loop row are held
        local result = self.loop_key_combo:press(x)
        if result then
            local r1 = result[1]
            local r2 = result[2]
            local loop_start = math.min(r1, r2)
            local loop_end = math.max(r1, r2)
            update_loop_range_params(loop_start, loop_end)
        end
    elseif x == transport_led.x and y == transport_led.y then
        -- start/stop playback
        page_sequencer:toggle_transport()
    elseif y <= NUM_VOICES then
        -- modify sequencer step
        local result = self.sequence_key_combo:press(x .. ":" .. y)
        if result then
            local r1 = result[1]
            local r2 = result[2]
            if r1 == "1:1" and r2 == "16:6" then
                -- future update: clear sequence
                page_sequencer:clear_sequence_rect(1, 6, 1, 16)
                self.is_clearing_sequence = true
            end
        end
    end
end

function grid_conn:key_release(x, y)
    if y == LOOP_ROW then
        -- update key combo
        self.loop_key_combo:release(x)
        -- set double tap state to last tapped key on grid
        if self.double_tap_state:register(x .. ":" .. y) then
            print('double tap: x' .. x .. ":y" .. y)
            -- double tap detected for this reference; set loop range to just this step
            update_loop_range_params(x, x)
        end
    elseif y <= NUM_VOICES then
        -- modify sequencer step
        if not self.is_clearing_sequence then
            self:modify_sequence(x, y)
        end
        self.sequence_key_combo:release(x .. ":" .. y)
        -- clear the flag once all keys are released
        if self.sequence_key_combo:keys_held() == 0 then
            self.is_clearing_sequence = false
        end
    end
end

function grid_conn:select_page(x)
    -- x: index of page, 1-based
    if x <= NUM_PAGES then
        self:reset_page_leds()
        switch_page(x)
        self:led(x, PAGE_ROW, MIDPLUS)
        -- self:refresh()
    end
end

function grid_conn:set_current_step(current_step)
    if not self.active then return end
    self.current_step = current_step --int: 1 to 16

    -- reset leds on row 7 (sequence stepper)
    self:reset_loop_leds()

    -- light up active step on step indicator row

    self:led(current_step, LOOP_ROW, MIDPLUS)

    for y = 1, 6 do
        -- set all to actual velocity level (incl previous column which may have flashed)
        for x = 1, 16 do
            local param_id = STEPS[y][x]
            local velocity = params:get(param_id)
            self:led(x, y, velocity * 15)
            if current_step == x and velocity > 0 and self.is_playing then
                -- flash active step
                self:led(x, y, HIGH)
            end
        end
    end
end

function grid_conn:set_current_page(page)
    self:reset_page_leds()
    self:led(page, 8, MIDPLUS)
    self:refresh()
end

function grid_conn:set_loop_range(start, _end)
    self.loop_start = start
    self.loop_end = _end
    self:reset_loop_leds()
end

function grid_conn:reset_page_leds()
    for x = 1, #page_leds do
        self:led(x, PAGE_ROW, page_leds[x])
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

    if x == nil then
        error("x is nil")
    elseif y == nil then
        error("y is nil")
    elseif val == nil then
        error("val is nil")
    end

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
            self:led(x, y, OFF)
        end
    end
end

function grid_conn:reset_loop_leds()
    for x = 1, 16 do
        self:led(x, LOOP_ROW, OFF)
    end

    for x = self.loop_start, self.loop_end do
        self:led(x, LOOP_ROW, LOW)
    end
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
    if state ~= true and state ~= false then error("state should be a bool") end
    self.is_playing = state
    if self.is_playing == false then
        -- clear current step indicator
        self:reset_loop_leds()
    end

    -- toggle lfo that flashes with BPM on X1Y7
    if self.transport_lfo then
        if self.is_playing then
            self.transport_lfo:stop()
        elseif self.transport_lfo:get("enabled") == 0 then
            self.transport_lfo:start()
        end
    end
end

function grid_conn:init(device, current_page_id)
    self.transport_lfo = _lfos:add {
        shape = 'up',     -- shape
        min = 2,          -- min
        max = 4,          -- max
        depth = 1,        -- depth (0 to 1)
        mode = 'clocked', -- mode
        period = 1,       -- period (in 'clocked' mode, represents beats)
        -- pass our 'scaled' value (bounded by min/max and depth) to the engine:
        action = function(scaled, raw)
            self:led(transport_led.x, transport_led.y, scaled)
        end       -- action, always passes scaled and raw values
    }
    self.double_tap_state = DoubleTapState.new(0.3)
    self.loop_key_combo = ComboDetector.new()
    self.sequence_key_combo = ComboDetector.new()
    self.transport_lfo:start()
    populate_grid_state()
    self.is_playing = false
    self.active = true
    self.device = device
    self:reset_page_leds()
    self.device:led(current_page_id, PAGE_ROW, MIDPLUS)
    device:refresh()
    page_sequencer:display_active_sequence()
    self:set_current_step(1)
    print('grid connection init done')
end

function grid_conn:close(device)
    print('grid connection closed')
    self.active = false
    self.transport_lfo:stop()
end

return grid_conn
