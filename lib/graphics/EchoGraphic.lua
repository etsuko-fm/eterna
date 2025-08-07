EchoGraphic = {
    x = 64,
    y = 25,
    radius = 10,
    hide = false,
    curve = 'lin', --lin, convex, concave
    selected = 1, -- time slice selected
    feedback = 1,
    wet = 1,
    time=7,
}

function EchoGraphic:new(o)
    o = o or {}           -- create state if not provided
    setmetatable(o, self) -- define prototype
    self.__index = self
    return o              -- return instance
end


local spacing = math.pi/16
local offset = math.pi / 2 + spacing/2

local first = true
function EchoGraphic:render()
    if self.hide then return end
    local radius = self.radius * self.feedback
    local count = 0
    local r = 1
    local n = 1
    local brightness = 15
    while r < radius do
        count = count + 1
        r = math.floor((n) + n * self.time/2)
        brightness = util.clamp(15 - r, 1, 15)
        brightness = util.round_up(brightness * self.feedback)
        screen.level(brightness)
        n = n+1
        if first then print(r) end
        for i = 1, 8 do
            -- offset = offset + spacing/1000 % math.pi*2
            local slice = math.pi/4

            local a1 = offset + (i * slice)
            local a2 = offset + (i + 1) * slice - spacing

            -- Compute start point of the arc
            local start_x = self.x + r * math.cos(a1)
            local start_y = self.y + r * math.sin(a1)
            screen.move(start_x, start_y)
            screen.arc(self.x, self.y, r, a1, a2)
            screen.line_width(1)
            screen.stroke()
            screen.move(self.x, self.y)
        end

    end

    -- for i = 1, 4 do
    --     screen.level(0)
    --     screen.circle(self.x, self.y, self.radius - i)
    --     screen.fill()
    -- end

    screen.level(1)
    local w = 32
    local h  = 3
    -- screen.rect(self.x-w/2, self.y+18, w, h)
    -- screen.fill()

    screen.level(1)
    local x = self.x-w/2
    local y = self.y+16
    for i = 1, w, 2 do
        screen.rect(x + i, y, 1, 3)
        screen.fill()
    end
    screen.level(15)
    screen.rect(x + (w-2) * self.wet, y, 3, h)
    screen.fill()
    first = false
end

return EchoGraphic
