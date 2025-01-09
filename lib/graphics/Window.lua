Window = {
    x = 0,
    y = 0,
    w = 128,
    h = 64,
    title="WINDOW",
    font_face=1,
    brightness=15,
    border=true,
    selected=true,
    horizontal_separations=0,
    vertical_separations=0,
    bar_height = 7
}


function Window:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function Window:render()
    if self.hide then return end

    -- top bar
    screen.line_width(1)
    screen.level(self.brightness)
    screen.rect(self.x, self.y, self.w, self.bar_height)
    screen.fill()

    -- title
    screen.move(self.x + (self.w/2), self.y + (self.bar_height - 1))
    screen.level(0)
    screen.font_face(self.font_face)
    screen.text_center(self.title)

    -- border
    screen.level(self.brightness)
    screen.line_width(1)
    screen.rect(self.x+1,self.y+1,self.w-1,self.h-1)
    screen.stroke()

    if self.vertical_separations then
        local v_spacing = ((self.h - self.bar_height) / (self.vertical_separations + 1))
        for n = 1, self.vertical_separations do
            local pos = self.bar_height + (v_spacing * n)
            screen.move(self.x, pos)
            screen.line(self.x + self.w, pos)
            screen.stroke()
        end
    end
    -- todo: horizontal separations
    screen.update()
end

return Window