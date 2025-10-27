SequencerGraphic = {
    x = 32,
    y = 16,
    rows = 10,
    columns = 21,
    fill = 2,
    active_fill = 6,
    flash_fill = 1,
    current_step = nil,
    sequences = {{},{},{},{},{},{}},
    voice_env = { 0, 0, 0, 0, 0, 0, },
    num_steps = 16,
    is_playing = true,
    hide = false,
}

function SequencerGraphic:new(o)
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
local basex = 32
local basey = 16
local indicator_x = 32 + (block_w + margin_w) * columns + 1
local indicator_y = basey + (block_h + margin_h) * rows + 1
local indicator_base_y = 16
local indicator_w = 1
local indicator_h = 3
local indicator_vmargin = indicator_h + margin_h
local faint_fill = 1

function SequencerGraphic:draw_track_indicator(voice)
    if self.voice_env[voice] == nil then return end
    local zero_idx = voice - 1

    -- brightness is reversely proportional to position of playhead in slice selection
    --- e.g. later in slice, is fainter brightness

    -- sometimes position comes to -0.0003, which troubles math.floor; hence +2 to have min brightness of 1
    screen.level(2)
    local indicator_y = indicator_base_y + (indicator_vmargin * zero_idx)
    local v = self.voice_env[voice]
    screen.level(1 + util.round(v * 14))
    if v > 0 then
        screen.rect(indicator_x, indicator_y, indicator_w, indicator_h)
        screen.fill()
    else
        screen.rect(indicator_x, indicator_y, 1, indicator_h)
        screen.fill()
    end
end

function SequencerGraphic:render()
    if self.hide then return end
    local voice
    local dim = 0
    for row = 0, rows - 1 do
        voice = row + 1
        self:draw_track_indicator(voice)
        for column = 0, columns - 1 do
            -- iterate over entire grid; row = voice, column = step
            local column_idx = column + 1
            local x = basex + (block_w + margin_w) * column
            local y = basey + (block_h + margin_h) * row
            local step_active = self.sequences[voice][column_idx] ~= 0.0

            if column >= self.num_steps then dim = -10 else dim = 0 end

            -- draw sequence step indicator
            if self.current_step == column and self.is_playing then
                graphic_util.screen_level(6, dim)
            else
                graphic_util.screen_level(faint_fill, dim)
            end

            if column < self.num_steps then
                screen.rect(basex + (column * (block_w + margin_w)), indicator_y, 3, 1)
                screen.fill()
            end

            if step_active then
                -- brighten if active
                if self.current_step == column and self.is_playing then
                    -- step triggered, flash block brightly
                    graphic_util.screen_level(self.flash_fill, dim)
                    screen.rect(x, y, block_w, block_h)
                    screen.fill()
                    -- screen.pixel(x,y)
                    -- screen.level(6)
                    -- screen.fill()
                else
                    -- step not triggered, but it is an active step in the sequence
                    local v = self.sequences[voice][column_idx]
                    local lev = math.floor(2 + math.abs(v) * 13)
                    graphic_util.screen_level(lev, dim, 2)
                    screen.rect(x, y, block_w, block_h)
                    screen.fill()
                end
            else
                -- inactive step
                screen.rect(x, y, block_w, block_h)
                graphic_util.screen_level(self.fill, dim, 1)
                screen.fill()
            end
        end
    end
end

return SequencerGraphic
