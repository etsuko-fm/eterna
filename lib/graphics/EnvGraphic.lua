EnvGraphic = {
    x = 32,
    y = 24,
    hide = false,
    curve = 'LIN', -- LIN, POS, NEG
    time = 1, -- 0 to 1
    mod = 1, -- 0 to 1; how much sequencer modulates env time
    -- if atk == 0 and dec == 1, then shape = 0
    -- if atk == 1 and dec == 0, then shape = 1
    -- if atk == 0.25 and dec == 0.25, then shape = 0.5
    shape = 0,
}

local screen_w = 128
local env_w = 32
local env_h = 16
local env_x = math.floor(screen_w / 2 - env_w / 2)
local env_y = 35

function EnvGraphic:new(o)
    o = o or {}           -- create state if not provided
    setmetatable(o, self) -- define prototype
    self.__index = self
    return o              -- return instance
end

local bg_fill = 3
local fg_fill = 15

local function draw_v_bar(x, y, w, h, fraction)
    --bg
    screen.level(bg_fill)
    screen.rect(x, y, w, h)
    screen.fill()
    --fg
    screen.level(fg_fill)
    screen.rect(x, y + h, w, -h * fraction)
    screen.fill()
end

local function draw_h_bar(x, y, w, h, fraction)
    --bg
    screen.level(bg_fill)
    screen.rect(x, y, w, h)
    screen.fill()
    --fg
    screen.level(fg_fill)
    screen.rect(x, y, w * fraction, h)
    screen.fill()
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

local function draw_envelope(shape, curve, x, y, w, h)
    screen.line_width(1)
    screen.line_join("bevel")
        screen.level(15)

    local startx = util.round(x)
    local starty = util.round(y)
    local peakx = util.round(startx + shape * w)
    local peaky = util.round(starty-h)
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
    screen.move(startx-1, starty)
    screen.curve(x1, y1, x2, y2, peakx, peaky)

    x1, y1, x2, y2 = bezier_controls(peakx, peaky, endx, endy, curve_mod, 0.25)
    screen.curve(x1, y1, x2, y2, endx, endy)

    screen.stroke()
end


function EnvGraphic:render()
    if self.hide then return end
    -- draw_bar(self.x, self.y, 4, 16, self.atk)
    -- draw_bar(self.x+32, self.y, 4, 16, self.dec)
    -- local shape = calc_shape(self.atk, self.dec)
    -- local time = (self.atk + self.dec)/2
    -- local margin = 4
    draw_envelope(self.shape, self.curve, env_x, env_y, env_w, env_h)

    -- time bar

    draw_h_bar(64-16, 39, 32, 3, self.time)

    -- for voice = 0,2 do
    --     draw_envelope(shape, env_x + voice*(env_w + margin), env_y, env_w, env_h)    
    -- end
    -- for voice = 0,2 do
    --     draw_envelope(shape, env_x + voice*(env_w + margin), env_y + env_h + margin, env_w, env_h)    
    -- end

    -- draw env levels per voice
    -- for voice = 1,6 do
    --     local i = voice - 1
    --     local x = self.x + 15 + i * 4 
    --     local level = self.voice_env[voice]
    --     local y = self.y + 6 * -level
        
    --     screen.level(15)
    --     screen.line_width(1)
    --     screen.move(x,y)
    --     screen.line(x+3,y)
    --     screen.stroke()
    --     -- draw_bar(x, y, 2, 8, level)
    -- end

end

return EnvGraphic
