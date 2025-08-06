Grid = {
    x = 32,
    y = 16,
    rows = 10,
    columns = 21,
    fill = 1,
    active_fill = 6,
    flash_fill = 15,
    current_step = nil,
    sequences = {
        { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
        { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
        { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
        { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
        { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
        { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
    },
    voice_pos_percentage = { nil, nil, nil, nil, nil, nil }, -- table of 6 items, with value 0-1 for position of voice in loop section
    is_playing = { false, false, false, false, false, false },
    hide = false,
}

function Grid:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

local rows = 6
local columns = 16
local block_w = 3
local block_h = 3
local margin_w = 1
local margin_h = 1
local indicator_x = 32 + (block_w+margin_w)*columns + 1
local indicator_base_y = 16
local indicator_w = 1
local indicator_h = 3
local indicator_vmargin = indicator_h + margin_h
local faint_fill = 1

function Grid:draw_track_indicator(voice)
    if self.voice_pos_percentage[voice] == nil then return end
    local zero_idx = voice - 1

    -- brightness is reversely proportional to position of playhead in slice selection
    --- e.g. later in slice, is fainter brightness

    -- sometimes position comes to -0.0003, which troubles math.floor; hence +2 to have min brightness of 1
    local brightness = faint_fill
    if self.is_playing[voice] then
        local rev_pos = 1 - self.voice_pos_percentage[voice]
        brightness = math.floor(2 + rev_pos * 15)
    end

    screen.level(brightness)
    local indicator_y = indicator_base_y + (indicator_vmargin * zero_idx)
    screen.rect(indicator_x, indicator_y, indicator_w, indicator_h)

    screen.fill()
end

local basex = 32
local basey = 16
function Grid:render()
    if self.hide then return end
    local voice
    for row = 0, rows - 1 do
        voice = row + 1
        -- self:draw_track_indicator(voice)
        for column = 0, columns - 1 do
            -- iterate over entire grid
            local idx = column + 1 -- step index in for loop
            local x = basex + (block_w + margin_w) * column
            local y = basey + (block_h + margin_h) * row
            local step_active = self.sequences[voice][idx] ~= 0.0

            -- draw sequence step indicator
            if self.current_step == idx then
                screen.level(6)
            else
                screen.level(faint_fill)
            end
            screen.rect(basex + (column * (block_w+margin_w)), basey + (block_h+margin_h)*self.rows + 1, 3, 1)
            screen.fill()

            if step_active then
                -- brighten if active
                if self.current_step == idx then
                    -- step triggered, flash block brightly
                    screen.level(self.flash_fill)
                    screen.rect(x, y, block_w, block_h)
                    screen.fill()
                else
                    -- step not triggered, but it is an active step in the sequence
                    local v = self.sequences[voice][idx]
                    screen.level(math.floor(2 + math.abs(v) * 13))
                    screen.rect(x, y, block_w, block_h)
                    screen.fill()
                end
            else
                -- inactive step
                screen.rect(x, y, block_w, block_h)
                screen.level(self.fill)
                screen.fill()
            end
        end
    end
end

return Grid
