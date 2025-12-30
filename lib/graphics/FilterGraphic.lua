local GraphicBase = require(from_root("lib/graphics/GraphicBase"))

FilterGraphic = {
    x = 33,
    y = 15,
    hide = false,
    freq = 1000,
    lfo_freq = nil,
    res = 0,
    type = nil, -- "HP" / "LP"
    mix = 1,    -- 0 to 1, but only 0, 0.5 and 1 are currently supported
    graph_w = 50,
    graph_h = 23,
    lfo_range = {}, -- start / end freq
    rate_fraction = nil,
    draw_lfo_range = false, -- flag whether to differentiate between filter and filter LFO page
}

setmetatable(FilterGraphic, { __index = GraphicBase })

local min_freq = 20
local max_freq = 20000
local off_db = -32
local norm_db = 0
local margin_x = 12
local res_max_db = 24
local line_w = 2

-- NB: Playing around on https://cubic-bezier.com
--- helps determining control coordinates

-- Maps `freq` (within `min_freq` to `max_freq`) to a horizontal
-- position in the graph. Uses a logarithmic scale, so equal ratios
-- in frequency appear as equal distances on the graph.
function FilterGraphic:freq_to_x(freq)
    -- distance from minimum freq to cutoff freq,
    -- so that freq_normalized = 0 when it equals min_freq
    local freq_normalized = math.log(freq) - math.log(min_freq)

    -- supported frequency range, approx 7 when min=20, max=20k
    local range = math.log(max_freq) - math.log(min_freq)

    -- fraction of the current frequency compared to max frequency
    local pos = util.clamp(freq_normalized / range, 0, 1)

    -- x position
    return self.x + pos * (self.graph_w - 1) -- exclude edge
end

function FilterGraphic:set_size(w, h)
    self:set("graph_w", w)
    self:set("graph_h", h)
end

function FilterGraphic:set_lfo_range(start, _end)
    self:set_table("lfo_range", "start", start)
    self:set_table("lfo_range", "end", _end)
end

function FilterGraphic:db_to_y(db)
    -- graph boundaries
    local offset_y = self.y + self.graph_h - line_w / 2

    -- difference in dB between lowest and highest supported amplitude
    local min_db = off_db
    local max_db = res_max_db
    local range = (max_db - min_db)

    -- fraction of total range
    local fraction = (db - min_db) / range

    -- multiply fraction with graph height
    local y = fraction * -(self.graph_h - line_w)

    -- TODO: the ceil is a bit of temp fix, I think math is 1px wrong, possibly due to stroke width
    return math.ceil(offset_y + y)
end

function FilterGraphic:get_control_points_up(type, cutoff_hz)
    local flat_y = self:db_to_y(norm_db)
    local off_y = self:db_to_y(off_db)

    -- calculate 2 control points for the cubic bezier curve from
    -- the flat 0dB line to the to peak cutoff/resonance poiont
    local cutoff_x = self:freq_to_x(cutoff_hz)
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

function FilterGraphic:get_control_points_down(type, cutoff_hz)
    -- calculate 2 control points for the cubic bezier curve from
    -- the cutoff point to the to the bottom of the graph (-INF dB)
    local off_y = self:db_to_y(off_db)

    local cutoff_x = self:freq_to_x(cutoff_hz)
    if type == "LP" then margin = margin_x else margin = -margin_x end

    local p1 = { x = cutoff_x + margin / 2, y = self:db_to_y(norm_db - 3) }
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
function FilterGraphic:draw_lowpass(cutoff_hz, resonance)
    local flat_y = self:db_to_y(norm_db)
    local off_y = self:db_to_y(off_db)

    local res_db = resonance * res_max_db

    -- starting point
    local cutoff_x = self:freq_to_x(cutoff_hz)
    local peak_db = norm_db + res_db

    -- start left, out of graph range; helps draw curve correctly for lowest frequencies
    local left_x = self.x - margin_x
    screen.move(left_x, flat_y)

    -- draw curve towards resonance
    -- control points are placed nearly under the cutoff x,
    -- to create exponential curve
    local control_points_up = self:get_control_points_up("LP", cutoff_hz)
    local cp1 = control_points_up.c1
    local cp2 = control_points_up.c2
    local dest1 = { x = cutoff_x, y = self:db_to_y(peak_db) }

    screen.curve(cp1.x, cp1.y, cp2.x, cp2.y, dest1.x, dest1.y)
    -- Slope after cutoff: down to -24 dB/octave visually

    local control_points_down = self:get_control_points_down("LP", cutoff_hz)
    local cp3 = control_points_down.c1
    local cp4 = control_points_down.c2
    local dest2 = { x = cutoff_x + margin_x, y = off_y }
    screen.curve(cp3.x, cp3.y, cp4.x, cp4.y, dest2.x, dest2.y)

    screen.line_width(line_w)
    screen.stroke()
end

function FilterGraphic:draw_highpass(cutoff_hz, resonance)
    local flat_y = self:db_to_y(norm_db)
    local off_y = self:db_to_y(off_db)
    local res_db = resonance * res_max_db

    local cutoff_x = self:freq_to_x(cutoff_hz)
    local peak_db = norm_db + res_db
    local end_x = self.x + self.graph_w + 2 * margin_x

    -- left side slope up to cutoff
    local control_points_down = self:get_control_points_down("HP", cutoff_hz)
    local cp1 = control_points_down.c1
    local cp2 = control_points_down.c2
    local dest1 = { x = cutoff_x, y = self:db_to_y(peak_db) }

    screen.move(cutoff_x - margin_x, off_y)
    screen.curve(cp1.x, cp1.y, cp2.x, cp2.y, dest1.x, dest1.y)

    local control_points = self:get_control_points_up("HP", cutoff_hz)

    local cp3 = control_points.c1
    local cp4 = control_points.c2
    local dest2 = { x = end_x, y = flat_y }

    -- right side; from cutoff/res point to 0db
    screen.curve(cp3.x, cp3.y, cp4.x, cp4.y, dest2.x, dest2.y)

    screen.line_width(line_w)
    screen.stroke()
end

function FilterGraphic:draw_filter_off()
    local flat_y = self:db_to_y(norm_db)
    screen.line_width(line_w)
    screen.move(self.x, flat_y)
    screen.line(self.x + self.graph_w + 2 * margin_x, flat_y)
    screen.stroke()
end

function FilterGraphic:draw_stripes(level)
    -- draw vertical black lines to make graphic less intense
    local start = self.x / 2 + 1 -- compensate 1px for stroke start, one for avoiding the first line
    local to = (self.x + self.graph_w) / 2 - 1
    for i = start, to do
        local x = i * 2
        screen.level(level)
        screen.line_width(1)
        screen.move(x, self.y)
        screen.line(x, self.y + self.graph_h - 1)
        screen.stroke()
    end
end

function FilterGraphic:screen_level_from_mix()
    if self.mix < 0.5 then
        return 2
    else
        return 15
    end
end

local function draw_slider(x, y, w, h, fraction)
    -- h is expected to be uneven
    screen.level(1)

    -- index of bar to light up to indicate current fraction
    local target = math.floor((h * (1 - fraction)) / 2) * 2

    for i = 0, h - 1, 2 do
        if i == target then
            screen.level(15)
        else
            screen.level(1)
        end

        screen.rect(x, y + i, w, 1)
        screen.fill()
    end
end


function FilterGraphic:render()
    if self.hide then return end

    screen.level(15)

    -- select function to draw filter
    local draw_filter =
        (self.type == "HP") and self.draw_highpass or
        (self.type == "LP") and self.draw_lowpass

    if self.mix == 0.5 and not self.draw_lfo_range then
        -- 50% mix; draw behind filter
        screen.level(3)
        self:draw_filter_off()
    end

    local main_graph_level = self:screen_level_from_mix()

    if draw_filter then
        if self.mix > 0 then
            if self.lfo_freq ~= nil then
                -- Draw faint LFO graph behind the base frequency
                screen.level(math.ceil(main_graph_level / 2))
                draw_filter(self, self.lfo_freq, self.res)
            end
            -- draw filter over LFO graph
            screen.level(main_graph_level)
            draw_filter(self, self.freq, self.res)
        end
    end
    if self.mix == 0 then
        -- 0% mix; only draw off line
        screen.level(15)
        self:draw_filter_off()
    end


    local level = 0

    -- create "dashed" graphic
    self:draw_stripes(level)

    -- hide out of range stuff
    screen.level(0)
    screen.rect(0, self.y, self.x - 1, self.graph_h)
    screen.rect(self.x + self.graph_w, 15, self.x, self.graph_h)
    screen.fill()

    -- draw edge
    screen.line_width(1)
    screen.level(1)
    screen.rect(self.x, 15, self.graph_w, self.graph_h)
    screen.stroke()

    if self.draw_lfo_range then
        local y = self.y + self.graph_h + 1
        -- compensate 1px for stroke width
        local x1 = 1 + self:freq_to_x(self.lfo_range["start"])
        screen.move(x1, y)
        screen.level(4)
        screen.line_rel(0, 3)
        local x2 = math.max(x1, self:freq_to_x(self.lfo_range["end"]))
        screen.line(x2, y + 3)
        screen.line_rel(0, -3)
        screen.stroke()

        draw_slider(self.x - 7, self.y - 1, 4, self.graph_h + 1, self.rate_fraction)
    end
    self.rerender = false
end

return FilterGraphic
