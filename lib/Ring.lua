Ring = {
  x=0, -- center x
  y=0, -- centr y
  a1=0, -- start point in radians
  a2=0, -- end point in radians
  radius=8, -- pixels
  thickness=3, -- pixels
  rate=1, -- movement speed of ring; corresponds 1:1 to softcut playback rate 
  level=10, -- brightness of arc
  bg=1, -- brightness of circle
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
  screen.line_width(self.thickness)
  
  -- draw circle
  if self.bg ~= 0 then
    screen.move(self.x+self.radius, self.y)
    screen.circle(self.x,self.y,self.radius)
    screen.level(self.bg)
    screen.stroke()
  end
  
  
  -- draw arc
  screen.level(self.level)
  screen.move(
    self.x + (math.cos(self.a1)*self.radius), 
    self.y + (math.sin(self.a1)*self.radius)
    )
  screen.arc(self.x, self.y, self.radius, self.a1, self.a2)
  screen.stroke()
  screen.update()
  
  -- update arc segment for next iteration
  self.a1 = self.a1 + rate_to_radians(self.rate)
  self.a2 = self.a2 + rate_to_radians(self.rate)
end

return Ring