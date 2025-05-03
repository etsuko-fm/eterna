EchoGraphic = {
    x = 12,
    y = 40,
    bar_w = 2,
    bar_h = 24,
    margin_w = 2,
    hide = false,
    feedback = nil, -- should be between 0 and 1
    max_feedback = nil,
    time = nil, -- should be between 0 and 1
    num_lines = 7,
}
local max_brightness = 15
function EchoGraphic:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end
local max_radians = math.pi*2
function EchoGraphic:render()
    if self.hide then return end
    local margin_w = 1.5 + .5 * self.time -- tweakable
    local net_bar_width = self.bar_w + margin_w
    local total_width = self.num_lines * net_bar_width

    -- this was with lines
    -- for i = 0, self.num_lines do
    --     screen.level(15)
    --     local x = self.x + i * net_bar_width
    --     local period = .07 * (self.max_feedback - self.feedback) -- finely tuned
    --     local radians = (max_radians * (i/self.num_lines*period) / 4) + max_radians / 4
    --     local h = (-self.bar_h * math.sin(radians))
    --     if h > 0 then
    --         -- if height is greater then stop drawing more lines. not the most beautiful math but soix.
    --         return
    --     end
    --     screen.rect(math.floor(x), self.y, self.bar_w, h)
    -- end
    local exp = 1.5
    for i = 0, self.num_lines do
        -- higher feedback = higher brightness for outer rings
        -- if ring == 5 and feedback == 1, brightness = 15
        -- local level = (i * mult) * (max_brightness / self.num_lines) * self.feedback
        local level = max_brightness
        if i > 1 and self.feedback < 1 then
            level = 1+(self.num_lines * 1/i) * max_brightness * self.feedback
        end
        screen.level(math.floor(level))
        -- screen.move(64,32)
        screen.arc(64, 44, i * (0.4+self.time) * 6, math.pi, math.pi*2)
        screen.stroke()
    end

end

return EchoGraphic
