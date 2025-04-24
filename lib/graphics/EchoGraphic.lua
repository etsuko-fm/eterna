EchoGraphic = {
    x = 64,
    y = 40,
    bar_w = 2,
    bar_h = 24,
    margin_w = 2,
    hide = false,
    feedback = nil,
    time = nil,
    num_lines = 12,
}

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
    local margin_w = .1 * self.time -- tweakable
    local net_bar_width = self.bar_w + margin_w
    local total_width = self.num_lines * net_bar_width
    for i = 0, self.num_lines do
        screen.level(15)
        local x = (self.x - total_width/2) + i * net_bar_width
        local period = .1 * self.feedback -- tweakable
        local radians = (max_radians * (i/self.num_lines*period) / 4) + max_radians / 4
        local h = -self.bar_h * math.sin(radians)
        if h > 0 then
            -- if height is greater then stop drawing more lines. not the most beautiful math but soix.
            return
        end
        screen.rect(x, self.y, self.bar_w, h)
    end
end

return EchoGraphic
