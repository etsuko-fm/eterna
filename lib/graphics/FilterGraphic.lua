FilterGraphic = {
    x = 64,
    y = 25,
    radius = 12,
    hide = false,
    freq = 1000,
    res = 0,
    type = 1, -- 1 HP / 2 LP / 3 BP / 4 Swirl
    mix = 1, -- 0 to 1, but only 0, 0.5 and 1 are currently supported
}

local min_freq = 20
local max_freq = 20000
local off_db = -32
local max_db = 0
local norm_db = -18
local graph_w = 40
local graph_h = 30
local offset_y = 11
local slack_x = 12
local res_max_db = 12
local line_w = 2
local start_x = (128 / 2 - graph_w / 2) - slack_x

-- Helper: frequency to x-coordinate (logarithmic mapping)
local function freq_to_x(freq)
    local norm = (math.log(freq) - math.log(min_freq)) /
        (math.log(max_freq) - math.log(min_freq))
    return start_x + slack_x + norm * graph_w
end

local function db_to_y(db)
    local norm = (db - max_db) / (off_db - max_db)
    return offset_y + norm * graph_h
end

local norm_y = db_to_y(norm_db)
local off_y = db_to_y(off_db)
-- Draw a low-pass filter curve with adjustable cutoff and resonance.
-- cutoff_hz: 20 - 20000
-- resonance: 0.0 - 1.0
function draw_lowpass(cutoff_hz, resonance)
    -- local slack_x = 8
    -- starting point
    local y0 = db_to_y(norm_db)
    local cutoff_x = freq_to_x(cutoff_hz)
    local peak_db = norm_db + resonance * res_max_db -- up to +6 dB boost at cutoff

    -- Start from left edge: flat line at 0 dB
    screen.move(start_x, y0)

    -- Left side: flat response until near cutoff
    screen.curve(start_x, norm_y,
        cutoff_x - slack_x, norm_y,
        cutoff_x, db_to_y(peak_db))

    -- Slope after cutoff: down to -24 dB/octave visually
    screen.curve(cutoff_x + slack_x / 4, norm_y,
        cutoff_x + slack_x / 2, db_to_y(norm_db - 3),
        cutoff_x + slack_x, off_y)
    screen.line_width(line_w)
    screen.stroke()
end

function draw_highpass(cutoff_hz, resonance)
    local y0 = off_y
    local cutoff_x = freq_to_x(cutoff_hz)
    local peak_db = norm_db + resonance * res_max_db
    local end_x = start_x + graph_w + 2 * slack_x

    -- left side slope up to cutoff
    screen.move(cutoff_x - slack_x, y0)
    screen.curve(cutoff_x - slack_x, off_y,
        cutoff_x - slack_x / 2, db_to_y(norm_db - 3),
        cutoff_x, db_to_y(peak_db))
    -- right side; from cutoff_x/res_y to end_x/norm_y

    -- spacing between points: from cutoff_x to cutoff_x + slack_x / 4
    screen.curve(cutoff_x + slack_x / 4, norm_y,
        cutoff_x + slack_x / 2, norm_y,
        end_x, norm_y)

    screen.line_width(line_w)
    screen.stroke()
end

function draw_bandpass(center_hz, resonance)
    local cutoff_x = freq_to_x(center_hz)
    local peak_db = norm_db + resonance * res_max_db
    -- Left slope
    screen.move(cutoff_x - slack_x, off_y)
    screen.curve(cutoff_x - slack_x, off_y,
        cutoff_x - slack_x / 2, db_to_y(norm_db - 3),
        cutoff_x, db_to_y(peak_db))

    -- Right slope
    screen.curve(cutoff_x, db_to_y(peak_db),
        cutoff_x + slack_x / 2, db_to_y(norm_db - 3),
        cutoff_x + slack_x, off_y)

    screen.line_width(line_w)
    screen.stroke()
end

local function draw_filter_off()
    screen.line_width(line_w)
    screen.move(start_x, norm_y)
    screen.line(start_x + graph_w + 2 * slack_x, norm_y)
    screen.stroke()
end

function FilterGraphic:new(o)
    o = o or {}           -- create state if not provided
    setmetatable(o, self) -- define prototype
    self.__index = self
    return o              -- return instance
end

function FilterGraphic:render()
    if self.hide then return end
    -- add filter off graphic if mix is dry or 50/50
    if self.mix == 0.5 then
        screen.level(2)
        draw_filter_off()
    end

    screen.level(15)
    if self.mix > 0 then screen.level(15) else screen.level(3) end
    if self.type == 1 then
        draw_highpass(self.freq, self.res)
    elseif self.type == 2 then
        draw_lowpass(self.freq, self.res)
    elseif self.type == 3 then
        draw_bandpass(self.freq, self.res)
    elseif self.type == 4 then
        -- swirl
        draw_bandpass(self.freq, self.res)
        draw_bandpass(self.freq * 4, self.res)
        draw_bandpass(self.freq * 16, self.res)
        draw_bandpass(self.freq * 64, self.res)
    end

    -- draw vertical black lines to make graphic less intense
    for i = 1, 64 do
        local x = i * 2
        screen.level(0)
        screen.line_width(1)
        screen.move(x, 10)
        screen.line(x, 54)
        screen.stroke()
    end
    screen.line_width(1)
    screen.level(3)
    screen.rect(start_x, 15, graph_w + 2 * slack_x, graph_h-3)
    screen.stroke()
    -- hide out of range swirl
    screen.level(0)
    screen.rect(start_x + graph_w + 2 * slack_x, 15, 32, graph_h-3)
    screen.fill()
end

return FilterGraphic
