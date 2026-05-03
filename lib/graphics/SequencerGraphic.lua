local GraphicBase = require(from_root("lib/graphics/GraphicBase"))

SequencerGraphic = {
    x = 32,
    y = 16,
    fill = 1,
    active_fill = 6,
    flash_fill = 3,
    current_step = 1,                       -- 1-based
    sequences = { {}, {}, {}, {}, {}, {} }, -- pattern per voice
    voice_env = { 0, 0, 0, 0, 0, 0, },      -- realtime envelope level of each voice
    loop_start = 1,
    loop_end = 16,
    is_playing = false,
    velocity_center = 0.5,
    velocity_spread = 0.5,
    hide = false,
    mode = "GRID", -- GRID | VELOCITY
}

setmetatable(SequencerGraphic, { __index = GraphicBase })

function SequencerGraphic:set_cell(voice, step, val)
    -- keeping this one simple because it's called a lot
    if val == nil then
        error("val for voice " .. voice ", step " .. step .. "can't be nil")
    end
    self.sequences[voice][step] = val
    self.changed = true
end

function SequencerGraphic:clear()
    for y = 1, 6 do
        for x = 1, 16 do
            self.sequences[y][x] = 0
        end
    end
    self.changed = true
end

local rows = 6
local columns = 16
local block_w = 3
local block_h = 3
local margin_w = 1
local margin_h = 1
local basex = 32
local basey = 16
local indicator_x = 32 + (block_w + margin_w) * columns + 1
local indicator_y = basey + (block_h + margin_h) * rows + 1
local velocity_base_y = basey + (block_h + margin_h) * rows
local velocity_range_h = (block_h + margin_h) * rows
local indicator_base_y = 16
local indicator_w = 1
local indicator_h = 3
local indicator_vmargin = indicator_h + margin_h
local faint_fill = 1

function SequencerGraphic:compute_env_meter(voice, rects)
    if self.voice_env[voice] == nil then return end
    local zero_idx = voice - 1

    -- brightness is reversely proportional to position of playhead in slice selection
    --- e.g. later in slice, is fainter brightness

    -- sometimes position comes to -0.0003, which troubles math.floor; hence +2 to have min brightness of 1
    local indicator_y = indicator_base_y + (indicator_vmargin * zero_idx)
    local v = self.voice_env[voice]
    local level = 1 + util.round(v * 14)
    if v > 0 and self.is_playing then
        -- brighten up according to envelope
        level = 1 + util.round(v * 14)
    else
        -- dim brightness when voice is not playing
        level = 2
    end
    table.insert(rects[level], { indicator_x, indicator_y, indicator_w, indicator_h })
end

function SequencerGraphic:compute_level(base, mod, min, max)
    -- compute brightness level
    return util.clamp(base + (util.round(mod) or 0), min or 1, max or 15)
end

function SequencerGraphic:compute_step_indicator(column, dim, rects)
    -- column: 1 to 16
    if column < self.loop_start or column > self.loop_end then return end

    -- compute brightness
    local base_level =
        (self.current_step == column and self.is_playing)
        and 6
        or faint_fill
    local level = self:compute_level(base_level, dim)

    -- compute coordinates
    local x = basex + ((column - 1) * (block_w + margin_w))
    table.insert(rects[level], { x, indicator_y, 3, 1 })
end

function SequencerGraphic:get_grid_cell_x(column)
    --- column: 1-16
    return basex + (block_w + margin_w) * (column - 1)
end

function SequencerGraphic:compute_grid_cell(voice, row, column, dim, rects)
    -- computes and stores the coordinates, brightness and size of a grid cell
    --- voice: 1-6
    --- row: 1-6
    --- column: 1-16
    --- dim: 0-15
    --- rects: a table to store the results
    local x = self:get_grid_cell_x(column)
    local y = basey + (block_h + margin_h) * row

    local step_velocity = self.sequences[voice][column]
    local step_active = step_velocity ~= 0.0
    local is_current = (self.current_step == column and self.is_playing)

    local level
    if step_active then
        if is_current then
            -- compute brightness
            -- if step triggered, different brightness
            level = self:compute_level(self.flash_fill, dim)
        else
            -- step not triggered, but it is an active step in the sequence
            local v = self.sequences[voice][column]
            if v == nil then
                error("Value for " .. voice .. ":" .. column .. " can't be nil")
            end
            local base_level = math.floor(2 + math.abs(v) * 13)
            level = self:compute_level(base_level, dim, 2)
        end
    else
        -- inactive step, lower level
        level = self:compute_level(self.fill, dim, 1)
    end
    table.insert(rects[level], { x, y, block_w, block_h })
end

function SequencerGraphic:perform_draws(rects)
    -- draws rects grouped by brightness level, to minimize screen.level() calls
    for level = 0, 15 do
        local batch = rects[level]
        if #batch > 0 then
            screen.level(level)
            for i = 1, #batch do
                local r = batch[i]
                screen.rect(r[1], r[2], r[3], r[4])
                screen.fill()
            end
        end
    end
end

function SequencerGraphic:compute_velocity_indicator(voice, column, rects)
    local x = self:get_grid_cell_x(column)
    local step_velocity = self.sequences[voice][column]
    local step_active = step_velocity ~= 0.0
    local level = 6 -- static, velocities are indicated by height, not brightness
    local y = math.floor(self:get_velocity_y(step_velocity))
    if step_active then
        table.insert(rects[level], { x, y, 3, 1 })
    end
end

function SequencerGraphic:get_velocity_y(velocity)
    return velocity_base_y - velocity_range_h * velocity
end

function SequencerGraphic:render()
    if self.hide then return end
    local draw_velocity = self.mode == "VELOCITY"

    -- rects to draw, organized by their brightness level. each entry: { x, y, w, h }
    -- As screen.level calls are expensive, this method allows the script to just
    -- do a single such call per distinct brightness
    local rects = {}
    for level = 0, 15 do
        rects[level] = {}
    end

    if draw_velocity then
        local bg_level = 1
        local velo_min = util.clamp(self.velocity_center - self.velocity_spread/2, 0.01, 1)
        local velo_max = util.clamp(self.velocity_center + self.velocity_spread/2, 0.01, 1)
        local velo_bottom_y = math.ceil(self:get_velocity_y(velo_min)) -- y for min velocity (bottom of screen)
        local velo_top_y = math.floor(self:get_velocity_y(velo_max)) -- y for max velocity (top of screen)
        local height = math.max(velo_bottom_y - velo_top_y, 1)
        screen.rect(29, velo_top_y, 2, height)
        screen.fill()
        for column = 1, columns do
            local x =  self:get_grid_cell_x(column)
            table.insert(rects[bg_level], { x, basey, 3, velo_top_y - basey })
            table.insert(rects[bg_level + 2], { x, velo_top_y, 3, height })
            table.insert(rects[bg_level], { x, velo_top_y + height, 3, velocity_range_h - height - (velo_top_y - basey) })
        end
    end

    for row = 0, rows - 1 do
        local voice = row + 1
        if not draw_velocity then
            self:compute_env_meter(voice, rects)
        end

        for column = 1, columns do
            local dim = (column < self.loop_start or column > self.loop_end) and -10 or 0
            self:compute_step_indicator(column, dim, rects)
            if draw_velocity then
                self:compute_velocity_indicator(voice, column, rects)
            else
                self:compute_grid_cell(voice, row, column, dim, rects)
            end
        end
    end
    self:perform_draws(rects)
end

return SequencerGraphic
