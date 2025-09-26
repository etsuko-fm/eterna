MasterGraphic = {
    x = 32,
    y = 11,
    hide = false,
    pre_comp_levels = {0,0},
    post_comp_levels = {0,0},
    lissajous_buf = {},
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

function MasterGraphic:add_sample(l, r)
  table.insert(self.lissajous_buf, {l, r})
  if #self.lissajous_buf > 30 then
    table.remove(self.lissajous_buf, 1)
  end
end

function MasterGraphic:draw_lissajous()
  local center_x = 64
  local center_y = 32
  local scale = 30

  for i, s in ipairs(self.lissajous_buf) do
    screen.level(i)
    local x = center_x + s[1] * scale
    local y = center_y - s[2] * scale
    screen.pixel(x, y)
  end
  screen.stroke()
end

function MasterGraphic:render()
    if self.hide then return end
    screen.level(15)

    -- pre levels 
    screen.rect(32, 40, 4, self.pre_comp_levels[1] * -20)
    screen.fill()
    screen.rect(38, 40, 4, self.pre_comp_levels[2] * -20)
    screen.fill()
    screen.move(64,32)

    -- post levels
    screen.rect(48, 40, 4, self.post_comp_levels[1] * -20)
    screen.fill()
    screen.rect(54, 40, 4, self.post_comp_levels[2] * -20)
    screen.fill()
    screen.move(64,32)

    -- lissajous
    -- self:add_sample(self.post_comp_levels[1], self.post_comp_levels[2])
    -- self:draw_lissajous()

end

return MasterGraphic
