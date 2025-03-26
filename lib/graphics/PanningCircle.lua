PanningCircle = {
    x = 64,
    y = 11,
    radius=2,
    w = 8,
    h = 8,
    hide = false,
    pan_positions = {0, 0, 0, 0, 0, 0, },
    twist = math.pi / 12,
}

function PanningCircle:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function PanningCircle:render()
    if self.hide then return end
    screen.level(15)
    -- self.twist = self.twist + 0.01
    for i = 0, 5 do
        local anglex = (i / 6) * math.pi * 2 + self.twist-- Divide full circle into 6 parts
        local x = math.floor(self.x + self.radius * self.w * math.cos(anglex))
        local y = math.floor(self.y + 3 * i * self.radius)
        screen.move(x,y)
        screen.rect(x, y, 2, 4)
        screen.fill()
    end
    screen.update()
end

return PanningCircle
