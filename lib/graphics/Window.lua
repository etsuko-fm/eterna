Window = {
    x = 0,
    y = 0,
    w = 128,
    h = 64,
    title = "WINDOW",
    title_x = 64,
    font_face = 68, -- TITLE_FONT
    brightness = 15,
    bar_height = 7,
}

function Window:new(o)
    o = o or {}           -- create state if not provided
    setmetatable(o, self) -- define prototype
    self.__index = self
    return o
end

function Window:render()
    if self.hide then return end
    screen.font_size(8)
    -- top bar
    screen.line_width(1)

    screen.level(self.brightness)

    screen.move(self.x, self.bar_height - 2)

    screen.move(self.x, self.y)
    screen.rect(self.x, self.y, self.w, self.bar_height)
    screen.fill()

    -- title
    screen.move(self.title_x, self.y + (self.bar_height - 1))
    screen.level(0)
    screen.font_face(self.font_face)
    screen.text_center(self.title)
end

return Window
