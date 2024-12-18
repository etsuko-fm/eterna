Zigzag = {
  x = 0,
  y = 32,
  w = 128,
  h = 4,
  zigzag_width = 4,
  hide = false,
}
function Zigzag:new(o)
  -- create state if not provided
  o = o or {}

  -- define prototype
  setmetatable(o, self)
  self.__index = self

  -- return instance
  return o
end

function Zigzag:render()
  if self.hide then return end
  screen.line_width(1)
  screen.level(1)
  screen.move(self.x, self.y - self.h / 2)
  screen.level(3)

  for i = 1, self.w / self.zigzag_width do
    screen.line(
      i * self.zigzag_width,
      self.y - self.h / 2 + (i % 2 * self.h)
    )
  end
  screen.stroke()
  screen.update()
end

return Zigzag
