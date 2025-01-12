Toggle = {
    x = 0,
    y = 0,
    size = 4,
    hide = false,
    on = false,
  }
  
  function Toggle:new(o)
    -- create state if not provided
    o = o or {}
  
    -- define prototype
    setmetatable(o, self)
    self.__index = self
  
    -- return instance
    return o
  end
  
  function Toggle:render()
    if self.hide then return end
    screen.line_width(1)
    screen.level(1)
    screen.move(self.x, self.y)
    screen.level(3)
    screen.rect(self.x, self.y, self.size, self.size)
    local txt
    if self.selected then
        screen.fill()
        txt = 'ON'
    else
        screen.stroke()
        txt = "OFF"
    end
    screen.move(self.x + self.size + 3, self.y + 4)

    screen.text(txt)
    screen.update()
  end


  return Toggle