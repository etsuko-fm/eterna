Ring = {
  x = 64,           -- center x
  y = 32,           -- center y
  hide = false,

  -- one ring can have multiple independent arcs (circle segments)
  arcs = {
    {
      a1 = 0,        -- start point in radians
      a2 = 0,        -- end point in radians
      luma = 5,      -- luma, 0-15
      thickness = 3, -- pixels
      radius = 8,    -- pixels
      rate = 1,      -- rotation speed of arc
    }
  },
}
function Ring:new(o)
  -- create state if not provided
  o = o or {}

  -- define prototype
  setmetatable(o, self)
  self.__index = self

  -- return instance
  return o
end

function Ring:render()
  if self.hide then return end
  screen.line_width(self.thickness)

  -- draw arc(s)
  for _, arc in ipairs(self.arcs) do
    screen.level(arc.luma)
    screen.line_width(arc.thickness)
    screen.move(
      self.x + (math.cos(arc.a1) * arc.radius),
      self.y + (math.sin(arc.a1) * arc.radius)
    )
    screen.arc(self.x, self.y, arc.radius, arc.a1, arc.a2)
    screen.stroke()
    screen.update()
  end
end

return Ring