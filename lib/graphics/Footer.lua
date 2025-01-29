Footer = {
    x = 0,
    y = 55,
    graphics_y = 59,
    height = 9,
    text_y = 3,
    knob_y = 1,
    enc_y = 1,
    hide = false,
    active_fill = 5,
    foreground_fill = 3,
    background_fill = 1,
    e2 = '',
    e3 = '',
    k2 = '',
    k3 = '',
    active_knob = nil,
    font_face = 1,
}

function Footer:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function Footer:render()
    if self.hide then return end
    local text_trim_width = 21
    screen.line_width(1)
    local x1 = 0
    local x2 = 128 / 4
    local x3 = (128 / 4) * 2
    local x4 = (128 / 4) * 3

    screen.level(self.background_fill)
    screen.rect(x1, self.y, 128 / 4 - 1, self.height)
    screen.rect(x2, self.y, 128 / 4 - 1, self.height)
    screen.rect(x3, self.y, 128 / 4 - 1, self.height)
    screen.rect(x4, self.y, 128 / 4 - 1, self.height)
    screen.fill()

    local fill = self.foreground_fill

    -- todo: make a nice for loop
    local buttons = {
        {
            name = "k2",
            type = "knob",
            x_margin = 5,
            y_margin = self.knob_y
        },
        {
            name = "k3",
            type = "knob",
            x_margin = 5,
            y_margin = self.knob_y
        },
        {
            name = "e2",
            type = "enc",
            x_margin = 5,
            y_margin = self.enc_y
        },
        {
            name = "e3",
            type = "enc",
            x_margin = 5,
            y_margin = self.enc_y
        }
    }
    local xposes = { x1, x2, x3, x4 }

    for i, btn in ipairs(buttons) do
        if self.active_knob == btn.name then fill = self.active_fill else fill = self.foreground_fill end

        screen.level(fill)
        if btn.type == "knob" then
            screen.move(xposes[i] + 4, self.graphics_y + btn.y_margin)
            screen.line(xposes[i] + 6, self.graphics_y + btn.y_margin)
            screen.move(xposes[i] + 3, self.graphics_y + btn.y_margin + 1)
            screen.line(xposes[i] + 7, self.graphics_y + btn.y_margin + 1)
            screen.stroke()
        else
            screen.circle(xposes[i] + btn.x_margin, self.graphics_y + btn.y_margin, 2)
        end

        screen.fill()

        screen.move(xposes[i] + 9, self.graphics_y + self.text_y)
        screen.font_face(self.font_face)
        screen.text(util.trim_string_to_width(self[btn.name], 23))
    end

    screen.stroke()
    screen.update()
end

return Footer
