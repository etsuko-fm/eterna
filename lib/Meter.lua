Meter = {
    x=0,
    y=0,
    w=2,
    h=10,
    bg=1,
    level=5,
    live_amp=0,
    mute=false,
    solo=false,
}
function Meter:new(o)
    -- create state if not provided
    o = o or {}   
    
    -- define prototype
    setmetatable(o, self)
    self.__index = self  
    
    -- return instance
    return o
end


function Meter:render()
    if self.bg ~= 0 then
        screen.move(self.x, self.y)
        screen.rect(self.x, self.y, self.x+self.w, self.y+self.h)
        screen.level(self.bg)
        screen.fill()
    end
    screen.move(self.x, self.y)
    screen.rect(self.x, self.y, self.x+self.w, self.y+self.h)
    screen.level(self.level)
    screen.fill()
end
