local GraphicBase = require(from_root("lib/graphics/GraphicBase"))

SequencerGraphic = {
    x = 32,
    y = 16,
    rows = 10,
    columns = 21,
    fill = 1,
    active_fill = 6,
    flash_fill = 3,
    current_step = 0, -- 0-based
    sequences = { {}, {}, {}, {}, {}, {} }, -- pattern per voice
    voice_env = { 0, 0, 0, 0, 0, 0, },      -- realtime envelope level of each voice
    num_steps = 16,
    is_playing = true,
    hide = false,
    background_grid = screen.create_image(67, 27),
    image = screen.create_image(67, 27),
}

setmetatable(SequencerGraphic, { __index = GraphicBase })
local screen_rect = screen.rect
local screen_level = screen.level

function SequencerGraphic:set_cell(voice, step, val)
    -- keeping this one simple because it's called a lot
    self.sequences[voice][step] = val
    self.changed = true
end

local rows = 6
local columns = 16
local block_w = 3
local block_h = 3
local margin_w = 1
local margin_h = 1
local basex = 0
local basey = 0
local indicator_x = basex + (block_w + margin_w) * columns + 1
local indicator_y = basey + (block_h + margin_h) * rows + 1
local indicator_base_y = basey
local indicator_w = 1
local indicator_h = 3
local indicator_vmargin = indicator_h + margin_h
local faint_fill = 1

local function get_indicator_y(zero_idx)
    -- zero_idx = integer representing voice number (0-5)
    return indicator_base_y + (indicator_vmargin * zero_idx)
end

local function render_base_grid()
    -- executes once to render the static grid into an image buffer
    screen_level(1)
    for row = 0, rows - 1 do
        local indicator_y = get_indicator_y(row)
        screen.rect(indicator_x, indicator_y, indicator_w, indicator_h)
        screen.fill()

        for column = 0, columns - 1 do
            local x = basex + (block_w + margin_w) * column
            local y = basey + (block_h + margin_h) * row
            screen.rect(x, y, block_w, block_h)
            screen.fill()
        end
    end
end

function SequencerGraphic:init()
    screen.draw_to(self.background_grid, render_base_grid)
end

function SequencerGraphic:queue_env_meter(voice, rects)
    if self.voice_env[voice] == nil then return end
    local zero_idx = voice - 1

    -- brightness is reversely proportional to position of playhead in slice selection
    --- e.g. later in slice, is fainter brightness

    -- sometimes position comes to -0.0003, which troubles math.floor; hence +2 to have min brightness of 1
    local indicator_y = get_indicator_y(zero_idx)
    local v = self.voice_env[voice]
    local level = 1 + util.round(v * 14)
    if v > 0 and self.is_playing then
        -- brighten up according to envelope
        level = 1 + util.round(v * 14)
        table.insert(rects[level], { indicator_x, indicator_y, indicator_w, indicator_h })
    end
end

function SequencerGraphic:compute_level(base, mod, min, max)
    -- compute brightness level
    return util.clamp(base + (util.round(mod) or 0), min or 1, max or 15)
end

function SequencerGraphic:queue_step_indicator(column, dim, rects)
    if column >= self.num_steps then return end

    -- compute brightness
    local base_level =
        (self.current_step == column and self.is_playing)
        and 6
        or faint_fill
    local level = self:compute_level(base_level, dim)

    -- compute coordinates
    local x = basex + (column * (block_w + margin_w))
    table.insert(rects[level], { x, indicator_y, 3, 1 })
end

function SequencerGraphic:queue_grid_cell(voice, row, column, dim, rects)
    local column_idx = column + 1
    local x = basex + (block_w + margin_w) * column
    local y = basey + (block_h + margin_h) * row

    local step_value = self.sequences[voice][column_idx]
    local step_active = step_value ~= 0.0
    local is_current = (self.current_step == column and self.is_playing)

    local level
    if step_active then
        if is_current then
            -- compute brightness
            -- if step triggered, different brightness
            level = self:compute_level(self.flash_fill, dim)
        else
            -- step not triggered, but it is an active step in the sequence
            local v = self.sequences[voice][column_idx]
            local base_level = math.floor(2 + math.abs(v) * 13)
            level = self:compute_level(base_level, dim, 2)
        end
        table.insert(rects[level], { x, y, block_w, block_h })
    end
end

function SequencerGraphic:flush_rects(rects)
    for level = 0, 15 do
        local batch = rects[level]
        if #batch > 0 then
            screen_level(level)
            for i = 1, #batch do
                local r = batch[i]
                screen_rect(r[1], r[2], r[3], r[4])
                screen.fill()
            end
        end
    end
end


function SequencerGraphic:render()
    if self.hide then return end

    -- rects to draw, organized by their brightness level. each entry: { x, y, w, h }
    -- As screen.level calls are expensive, this method allows the script to just
    -- do a single such call per distinct brightness
    local rects = {}
    for i = 0, 15 do
        rects[i] = {}
    end

    for row = 0, rows - 1 do
        local voice = row + 1
        self:queue_env_meter(voice, rects)

        for column = 0, columns - 1 do
            local dim = (column >= self.num_steps) and -10 or 0
            self:queue_step_indicator(column, dim, rects)
            self:queue_grid_cell(voice, row, column, dim, rects)
        end
    end

    -- draw the actual rects
    screen.draw_to(self.image,
        function()
            screen.clear()
            self:flush_rects(rects)
        end
    )
    screen.display_image(self.background_grid, self.x, self.y)
    screen.display_image(self.image, self.x, self.y)
    self.rerender = false
end

return SequencerGraphic
