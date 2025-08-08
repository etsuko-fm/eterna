FilterGraphic = {
    x = 64,
    y = 25,
    radius = 12,
    hide = false,
    freq = 1000,
    res = 0,
    type=0,
}

local min_freq = 20
local max_freq = 20000
local off_db = -32
local max_db = 0
local norm_db = -18
local graph_w = 64
local graph_h = 32
local offset_y = 4
local slack_x = 12
local res_max_db = 9


-- Helper: frequency to x-coordinate (logarithmic mapping)
local function freq_to_x(freq, start_x, slack_x)
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
    local w, h = 64, 32 -- graph width/height in pixels
    local slack_x = 8
    local x0 = 32 - slack_x -- starting point
    local y0 = db_to_y(norm_db)
    local cutoff_x = freq_to_x(cutoff_hz, x0, slack_x)
    local peak_db = norm_db + resonance * res_max_db -- up to +6 dB boost at cutoff

    -- Start from left edge: flat line at 0 dB
    screen.move(x0, y0)

    -- Left side: flat response until near cutoff
    screen.curve(x0, norm_y,
                 cutoff_x - slack_x, norm_y,
                 cutoff_x, db_to_y(peak_db))

    -- Slope after cutoff: down to -24 dB/octave visually
    screen.curve(cutoff_x + slack_x/4, norm_y,
                 cutoff_x + slack_x/2, db_to_y(norm_db - 3),
                 cutoff_x + slack_x, off_y)
    screen.line_width(2)
    screen.stroke()
end

function draw_highpass(cutoff_hz, resonance)
    local x0 = 32 - slack_x
    local y0 = off_y
    local cutoff_x = freq_to_x(cutoff_hz, x0, slack_x)
    local peak_db = norm_db + resonance * res_max_db
    local end_x = x0 + graph_w + 2*slack_x

    -- left side slope up to cutoff
    screen.move(cutoff_x - slack_x, y0)
    screen.curve(cutoff_x - slack_x, off_y,
                 cutoff_x - slack_x/2, db_to_y(norm_db - 3),
                 cutoff_x, db_to_y(peak_db))
    -- right side; from cutoff_x/res_y to end_x/norm_y 

    -- spacing between points: from cutoff_x to cutoff_x + slack_x / 4
    screen.curve(cutoff_x + slack_x / 4, norm_y,
                 cutoff_x + slack_x / 2, norm_y,
                 end_x, norm_y)

    screen.line_width(2)
    screen.stroke()
end

function draw_bandpass(center_hz, resonance)
    local x0 = 32 - slack_x
    local cutoff_x= freq_to_x(center_hz, x0, slack_x)
    local peak_db = norm_db + resonance * res_max_db
    -- Left slope
    screen.move(cutoff_x - slack_x, off_y)
    screen.curve(cutoff_x - slack_x, off_y,
                 cutoff_x - slack_x/2, db_to_y(norm_db - 3),
                 cutoff_x, db_to_y(peak_db))

    -- Right slope
    screen.curve(cutoff_x, db_to_y(peak_db),
                 cutoff_x + slack_x/2, db_to_y(norm_db - 3),
                 cutoff_x + slack_x, off_y)

    screen.line_width(2)
    screen.stroke()
end

local function draw_filter_off()
    screen.line_width(2)
    screen.move(32-slack_x, norm_y)
    screen.line(32 + graph_w + slack_x, norm_y)
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
    if self.type == 2 then
        draw_lowpass(self.freq, self.res)
    elseif self.type == 1 then
        draw_highpass(self.freq, self.res)
    elseif self.type == 3 then
        draw_bandpass(self.freq, self.res)
    else
        draw_filter_off()
    end
    -- draw_lowpass(self.freq, self.res)
    -- draw_highpass(self.freq, self.res)
end

return FilterGraphic
