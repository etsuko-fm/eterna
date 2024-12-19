Ring = {
  x = 64,           -- center x
  y = 32,           -- center y
  selected = false, -- if true, shows a dot next to the ring
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

  -- -- draw circle
  -- if self.luma ~= 0 then
  --   screen.move(self.x + self.radius, self.y)
  --   screen.circle(self.x, self.y, self.radius)
  --   screen.level(self.luma)
  --   screen.stroke()
  -- end


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

    -- update arc segment for next iteration
    -- todo: should an arc rotate itself? or should the caller do it?
    -- problem a t hand: I want to want to show the current playback position in the arc, not just
    -- roll forward constantly
    -- arc.a1 = arc.a1 + arc.rate
    -- arc.a2 = arc.a2 + arc.rate
  end

  if self.selected then
    screen.line_width(1)
    -- screen.move(self.x - self.radius, self.y - self.radius)
    local A270 = 9 * math.pi/12
    screen.pixel(
      self.x + math.cos(A270) * (self.radius + 4),
      self.y + math.sin(A270) * (self.radius + 4)
    )
    screen.level(15)
    screen.fill()
  end

end

return Ring
