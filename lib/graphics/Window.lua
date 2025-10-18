Window = {
    x = 0,
    y = 0,
    w = 128,
    h = 64,
    title = "WINDOW",
    font_face = 1,
    brightness = 15,
    deselected_brightness = 4,
    border = false,
    selected = true,
    horizontal_separations = 0,
    vertical_separations = 0,
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
    screen.font_size(8)
    -- top bar
    screen.line_width(1)
    if self.selected then
        screen.level(self.brightness)
    else
        screen.level(self.deselected_brightness)
    end

    screen.move(self.x, self.y)
    screen.rect(self.x, self.y, self.w, self.bar_height)
    screen.fill()

    -- title
    screen.move(self.x + (self.w / 2), self.y + (self.bar_height - 1))
    if self.selected then
        -- draw black on white background
        screen.level(0)
    else
        screen.level(self.brightness)
    end
    screen.font_face(self.font_face)
    screen.text_center(self.title)

    -- border
    screen.line_width(1)
    if self.border then
        if self.selected then
            screen.level(self.brightness)
        else
            screen.level(self.deselected_brightness)
        end
        screen.move(self.x + 1, self.y + self.bar_height)
        screen.line(self.x + 1, self.y + self.h - 1)
        screen.line(self.x + self.w, self.y + self.h - 1)
        screen.line(self.x + self.w, self.y + self.bar_height)
        screen.stroke()
    end

    if self.vertical_separations then
        local v_spacing = ((self.h - self.bar_height) / (self.vertical_separations + 1))
        if self.selected then
            screen.level(self.brightness)
        else
            screen.level(self.deselected_brightness)
        end
        for n = 1, self.vertical_separations do
            local pos = math.floor(self.bar_height + (v_spacing * n))
            screen.move(self.x, pos)
            screen.line(self.x + self.w, pos)
            screen.stroke()
        end
    end
end

return Window
