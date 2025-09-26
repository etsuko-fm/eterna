MasterGraphic = {
    x = 32,
    y = 11,
    hide = false,
    pre_comp_levels = {0,0},
    post_comp_levels = {0,0},
}

function MasterGraphic:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function MasterGraphic:render()
    if self.hide then return end
    screen.level(15)
    screen.rect(32, 40, 4, self.pre_comp_levels[1] * -20)
    screen.fill()
    screen.rect(38, 40, 4, self.pre_comp_levels[2] * -20)
    screen.fill()
    screen.move(64,32)
    screen.text_center("hello world!")
end

return MasterGraphic
