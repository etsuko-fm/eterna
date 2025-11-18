FilterGraphic = {
    x = 64,
    y = 25,
    radius = 12,
    hide = false,
    freq = 1000,
    res = 0,
    type = 1, -- 1 HP / 2 LP
    mix = 1,  -- 0 to 1, but only 0, 0.5 and 1 are currently supported
}

local min_freq = 20
local max_freq = 20000
local off_db = -32
local max_db = 0
local norm_db = -18
local graph_w = 64
local graph_h = 30
local offset_y = 11
local margin_x = 12
local res_max_db = 12
local line_w = 2
local start_x = (128 / 2 - graph_w / 2) -- - margin_x

-- NB: Playing around on https://cubic-bezier.com
--- helps determining control coordinates

-- Maps `freq` (within `min_freq` to `max_freq`) to a horizontal
-- position in the graph. Uses a logarithmic scale, so equal ratios
-- in frequency appear as equal distances on the graph.
local function freq_to_x(freq)
    -- distance from minimum freq to cutoff freq,
    -- so that freq_normalized = 0 when it equals min_freq
    local freq_normalized = math.log(freq) - math.log(min_freq)

    -- supported frequency range
    local range = math.log(max_freq) - math.log(min_freq)

    -- fraction of the current frequency compared to max frequency
    local pos = freq_normalized / range

    -- x position
    return start_x + pos * (graph_w - 1) -- exclude edge
end

local function db_to_y(db)
    local db_range = off_db - max_db
    local norm = (db - max_db) / db_range
    return offset_y + norm * graph_h
end

local flat_y = db_to_y(norm_db)
local off_y = db_to_y(off_db)

local function get_control_points_up(type, cutoff_hz)
    -- calculate 2 control points for the cubic bezier curve from
    -- the flat 0dB line to the to peak cutoff/resonance poiont
    local cutoff_x = freq_to_x(cutoff_hz)
    local margin

    -- for lowpass, control point is before the cutoff (subtract margin)
    -- for highpass, control point is after cutoff (add margin)
    if type == "LP" then margin = -margin_x else margin = margin_x end

    -- keep x close to the cutoff, y on the flat line,
    -- to create exponential slope
    local p1 = { x = cutoff_x + margin / 2, y = flat_y }
    local p2 = { x = cutoff_x + margin / 4, y = flat_y }

    -- swap points depending on low/highpass
    if type == "LP" then
        return { c1 = p1, c2 = p2 }
    elseif type == "HP" then
        return { c1 = p2, c2 = p1 }
    else
        print(type .. " is not a supported filter type")
    end
end

local function get_control_points_down(type, cutoff_hz)
    -- calculate 2 control points for the cubic bezier curve from
    -- the cutoff point to the to the bottom of the graph (-INF dB)

    local cutoff_x = freq_to_x(cutoff_hz)
    if type == "LP" then margin = margin_x else margin = -margin_x end

    local p1 = { x = cutoff_x + margin / 2, y = db_to_y(norm_db - 3) }
    local p2 = { x = cutoff_x + margin, y = off_y }

    -- swap points depending on low/highpass
    if type == "LP" then
        return { c1 = p1, c2 = p2 }
    elseif type == "HP" then
        return { c1 = p2, c2 = p1 }
    else
        print(type .. " is not a supported filter type")
    end
end

-- Draw a low-pass filter curve with adjustable cutoff and resonance.
-- cutoff_hz: 20 - 20000
-- resonance: 0.0 - 1.0
local function draw_lowpass(cutoff_hz, resonance)
    local res_db = resonance * res_max_db

    -- starting point
    local cutoff_x = freq_to_x(cutoff_hz)
    local peak_db = norm_db + res_db -- up to +6 dB boost at cutoff

    -- start left, out of graph range; helps draw curve correctly for lowest frequencies
    local left_x = start_x - margin_x
    screen.move(left_x, flat_y)

    -- draw curve towards resonance
    -- control points are placed nearly under the cutoff x,
    -- to create exponential curve
    local control_points_up = get_control_points_up("LP", cutoff_hz)
    local cp1 = control_points_up.c1
    local cp2 = control_points_up.c2
    local dest1 = { x = cutoff_x, y = db_to_y(peak_db) }

    screen.curve(cp1.x, cp1.y, cp2.x, cp2.y, dest1.x, dest1.y)
    -- Slope after cutoff: down to -24 dB/octave visually

    local control_points_down = get_control_points_down("LP", cutoff_hz)
    local cp3 = control_points_down.c1
    local cp4 = control_points_down.c2
    local dest2 = { x = cutoff_x + margin_x, y = off_y }
    screen.curve(cp3.x, cp3.y, cp4.x, cp4.y, dest2.x, dest2.y)

    screen.line_width(line_w)
    screen.stroke()
end


local function draw_highpass(cutoff_hz, resonance)
    local res_db = resonance * res_max_db

    local cutoff_x = freq_to_x(cutoff_hz)
    local peak_db = norm_db + res_db
    local end_x = start_x + graph_w + 2 * margin_x

    -- left side slope up to cutoff
    local control_points_down = get_control_points_down("HP", cutoff_hz)
    local cp1 = control_points_down.c1
    local cp2 = control_points_down.c2
    local dest1 = { x = cutoff_x, y = db_to_y(peak_db) }

    screen.move(cutoff_x - margin_x, off_y)
    screen.curve(cp1.x, cp1.y, cp2.x, cp2.y, dest1.x, dest1.y)

    local control_points = get_control_points_up("HP", cutoff_hz)

    local cp3 = control_points.c1
    local cp4 = control_points.c2
    local dest2 = { x = end_x, y = flat_y }

    -- right side; from cutoff/res point to 0db
    screen.curve(cp3.x, cp3.y, cp4.x, cp4.y, dest2.x, dest2.y)

    screen.line_width(line_w)
    screen.stroke()
end

local function draw_filter_off()
    screen.line_width(line_w)
    screen.move(start_x, flat_y)
    screen.line(start_x + graph_w + 2 * margin_x, flat_y)
    screen.stroke()
end

function FilterGraphic:new(o)
    o = o or {}           -- create state if not provided
    setmetatable(o, self) -- define prototype
    self.__index = self
    return o              -- return instance
end

local function draw_stripes()
    -- draw vertical black lines to make graphic less intense
    for i = 1, 64 do
        local x = i * 2
        screen.level(0)
        screen.line_width(1)
        screen.move(x, 10)
        screen.line(x, 54)
        screen.stroke()
    end
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
    end

    draw_stripes()
    screen.line_width(1)
    screen.level(3)
    screen.rect(start_x, 15, graph_w, graph_h - 3)
    screen.stroke()
    -- hide out of range stuff
    screen.level(0)
    screen.rect(0, 15, start_x - 1, graph_h)
    screen.rect(start_x + graph_w, 15, 32, graph_h)
    screen.fill()
end

return FilterGraphic
