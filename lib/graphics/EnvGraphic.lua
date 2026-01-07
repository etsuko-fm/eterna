local GraphicBase = require(from_root("lib/graphics/GraphicBase"))

EnvGraphic = {
    x = 32,
    y = 24,
    hide = false,
    curve = 'LIN', -- LIN, POS, NEG
    time = 1,      -- 0 to 1
    mod = 1,       -- 0 to 1; how much sequencer modulates env time
    -- if atk == 0 and dec == 1, then shape = 0
    -- if atk == 1 and dec == 0, then shape = 1
    -- if atk == 0.25 and dec == 0.25, then shape = 0.5
    shape = 0,
}

setmetatable(EnvGraphic, { __index = GraphicBase })

local screen_w = 128
local env_w = 32
local env_h = 16
local env_x = math.floor(screen_w / 2 - env_w / 2)
local env_y = 35
local bg_fill = 2
local fg_fill = 15

local function draw_slider(x, y, w, h, fraction, mod)
    screen.level(1)
    for i = 0, w - 1, 2 do
        screen.rect(x + i, y, 1, h)
        screen.fill()
    end
    local full_w = math.floor(w * fraction)
    local mod_w = math.floor(w * fraction * (1 - mod))
    if mod > 0 then
        local xmod = x + mod_w
        local wmod = math.max(full_w - mod_w, 1)
        local max = math.max(1, wmod - 1)
        for n = 0, max do
            graphic_util.screen_level(fg_fill, (1 / wmod * (wmod - n)) * -14, bg_fill + 1)
            if n == max or max < 2 then screen.level(15) end
            screen.rect(xmod + n, y, 1, h)
            screen.fill()
        end
        screen.fill()
        for i = 1, w - 1, 2 do
            screen.level(0)
            screen.rect(x + i, y, 1, h)
            screen.fill()
        end
    else
        screen.level(fg_fill)
        screen.rect(1 + math.floor((x + (w - 2) * fraction) / 2) * 2, y, 1, h)
        screen.fill()
    end
end

local function bezier_controls(x0, y0, x3, y3, k, t)
    k = k or 2
    t = t or 0.25

    -- distance in pixels between start and end points
    local dx = x3 - x0
    local dy = y3 - y0

    -- x1 and x2: evenly spaced, by factor t*dx; x1 from the start point, x2 from the end point
    -- e.g. for t = 0.25, x1 is at 25% and x2 at 75% of the total x distance
    local x1 = x0 + t * dx
    local x2 = x3 - t * dx

    -- y1 and y2: same as x1 and x2, but with an extra factor k that translates the y pos such
    -- that for positive values it approaches the destination y quicker (log),
    -- while for negative k it approaches destination y slower (exp).
    local y1 = y0 + t * (1 + k) * dy
    local y2 = y3 - t * (1 - k) * dy

    return x1, y1, x2, y2
end

local function draw_envelope(shape, curve, x, y, w, h, level)
    screen.line_width(1)
    -- screen.line_join("bevel")
    screen.level(level)

    local startx = util.round(x)
    local starty = util.round(y)
    local peakx = util.round(startx + shape * w)
    local peaky = util.round(starty - h)
    local endx = util.round(startx + w)
    local endy = util.round(starty)

    local curve_mod
    if curve == "LIN" then
        curve_mod = 0
    elseif curve == "NEG" then
        curve_mod = 1.8
    else
        curve_mod = -1.8
    end

    local x1, y1, x2, y2 = bezier_controls(startx, starty, peakx, peaky, curve_mod, 0.25)
    screen.move(startx - 1, starty)
    screen.curve(x1, y1, x2, y2, peakx, peaky)

    x1, y1, x2, y2 = bezier_controls(peakx, peaky, endx, endy, curve_mod, 0.25)
    screen.curve(x1, y1, x2, y2, endx, endy)

    screen.stroke()
end


function EnvGraphic:render()
    if self.hide then return end
    if self.mod > 0 then
        for i = 3, 0, -1 do
            local level
            if i == 0 then level = 15 else level = math.max(15 - 6 * i, 1) end
            local modify = i * -0.1
            local shape = math.max(self.shape + modify, 0)
            draw_envelope(shape, self.curve, env_x, env_y, env_w, env_h, level)
        end
    else
        draw_envelope(self.shape, self.curve, env_x, env_y, env_w, env_h, 15)
    end

    -- time bar
    local bar_w = 33
    local bar_h = 3
    draw_slider(64 - 17, 39, bar_w, bar_h, self.time, self.mod)
end

return EnvGraphic
