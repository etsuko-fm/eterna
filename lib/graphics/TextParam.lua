TextParam = {
    x = 0,
    y = 0,
    val = 0,
    unit = ' Hz',
    hide = false,
}

function TextParam:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function TextParam:render()
    if self.hide then return end
    screen.move(self.x, self.y)
    screen.level(15)
    rounded = tonumber(string.format("%.2f", self.val))
    screen.text(rounded .. self.unit)
    screen.update()
end

return TextParam
