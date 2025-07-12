local misc_util = include("bits/lib/util/misc")

Grid = {
    x = 32,
    y = 16,
    rows = 10,
    columns = 21,
    block_w = 3,
    block_h = 3,
    margin_w = 1,
    margin_h = 1,
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

local indicator_x = 97
local indicator_base_y = 16
local indicator_w = 1
local indicator_h = 3
local indicator_vmargin = indicator_h + 1
local faint_fill = 1

local function draw_env_up(fill,x,y)
    screen.level(fill)

    screen.rect(x,y+2,1,1)
    screen.fill()

    screen.rect(x+1,y+1,1,2)
    screen.fill()

    screen.rect(x+2,y,1,3)
    screen.fill()
end

local function draw_env_down(fill,x,y)
    screen.level(fill)

    screen.rect(x+2,y+2,1,1)
    screen.fill()

    screen.rect(x+1,y+1,1,2)
    screen.fill()

    screen.rect(x,y,1,3)
    screen.fill()
end

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

function Grid:render()
    if self.hide then return end
    local voice
    --draw grid
    for row = 0, self.rows - 1 do
        voice = row + 1
        self:draw_track_indicator(voice)
        for column = 0, self.columns - 1 do
            local idx = column + 1
            local x = self.x + (self.block_w + self.margin_w) * column
            local y = self.y + (self.block_h + self.margin_h) * row
            local step_active = self.sequences[voice][idx] ~= 0.0

            -- draw sequence step indicator
            if self.current_step == idx then
                screen.level(6)
            else
                screen.level(faint_fill)
            end
            screen.rect(28 + (idx * 4), 41, 3, 1)
            screen.fill()

            -- screen.rect(x, y, self.block_w, self.block_h)
            if step_active then
                -- brighten if active
                if self.current_step == idx then
                    -- sequencer is at this step, flash block brightly
                    screen.level(self.flash_fill)
                    screen.rect(x, y, self.block_w, self.block_h)
                    screen.fill()
                else
                    -- local h = misc_util.round(self.block_h * self.sequences[voice][idx])
                    local v = self.sequences[voice][idx]
                    local l = misc_util.round(self.active_fill * math.abs(v))
                    if v < 0 then
                        draw_env_up(l, x,y)
                    else
                        draw_env_down(l, x,y)
                    end
                    -- screen.rect(x, y, self.block_w, h)
                    -- screen.fill()
                end
            else
                screen.rect(x, y, self.block_w, self.block_h)
                screen.level(self.fill)
                screen.fill()
            end
        end
    end
end

return Grid
