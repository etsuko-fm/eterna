Ring = {
  x = 64,           -- center x
  y = 32,           -- center y
  hide = false,

  -- one ring can have multiple independent arcs (circle segments)
  layers = {
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
  -- draw arc(s)
  for _, layer in ipairs(self.layers) do
    screen.level(layer.luma)
    screen.line_width(layer.thickness)
    screen.move(
      self.x + (math.cos(layer.a1) * layer.radius),
      self.y + (math.sin(layer.a1) * layer.radius)
    )
    screen.arc(self.x, self.y, layer.radius, layer.a1, layer.a2)
    screen.stroke()
  end
end

return Ring