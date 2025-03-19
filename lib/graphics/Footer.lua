Footer = {
    hide = false,
    active_fill = 5, -- text brightness when corresponding button has been physically modified
    foreground_fill = 3, -- default text brightness
    background_fill = 1, -- fill of rect surrounding text
    -- text on buttons; `name` is displayed on top row, `value` on bottom row
    button_text = {
        e2 = {
            name = '',
            value ='',
        },
        e3 = {
            name = '',
            value ='',
        },
        k2 = {
            name = '',
            value ='',
        },
        k3 = {
            name = '',
            value ='',
        },
    },
    active_knob = nil,
    font_face = 1,
}

-- default position at bottom of screen; 2 rows of 7px and 1 px spacing
local btn_height = 7
local ver_btn_spacing = 1
local base_y_row1 = 64 - (btn_height*2) - ver_btn_spacing
local base_y_row2 = 64 - btn_height

-- positioning of footer elements
local graphics_ver_spacing = 2
local graphics_y = base_y_row1 + graphics_ver_spacing
local btn_width = 128/4 - 1

local text_y_row_1 = base_y_row1 + 6
local text_y_row_2 = base_y_row2 + 6

local knob_y = 2
local enc_y = 2
local hor_txt_offset = 9

function Footer:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

local rect_x_positions = {}

for i = 1,4 do 
    rect_x_positions[i] = (128 / 4) * (i-1)
end

function Footer:render()
    if self.hide then return end
    local text_trim_width = 21
    screen.line_width(1)

    screen.level(self.background_fill)
    for i = 1, 4 do
        screen.rect(rect_x_positions[i], base_y_row1, btn_width, btn_height)
        screen.rect(rect_x_positions[i], base_y_row2, btn_width, btn_height)
    end
    screen.fill()

    local fill = self.foreground_fill

    -- todo: make a nice for loop
    local buttons = {
        {
            name = "k2",
            type = "knob",
            x_margin = 5,
            y_margin = knob_y,
        },
        {
            name = "k3",
            type = "knob",
            x_margin = 5,
            y_margin = knob_y,
        },
        {
            name = "e2",
            type = "enc",
            x_margin = 5,
            y_margin = enc_y,
        },
        {
            name = "e3",
            type = "enc",
            x_margin = 5,
            y_margin = enc_y,
        }
    }

    for i, btn in ipairs(buttons) do
        if self.active_knob == btn.name then fill = self.active_fill else fill = self.foreground_fill end

        screen.level(fill)
        if btn.type == "knob" then
            -- draw knob icon
            screen.move(rect_x_positions[i] + 4, graphics_y + btn.y_margin)
            screen.line(rect_x_positions[i] + 6, graphics_y + btn.y_margin)
            screen.move(rect_x_positions[i] + 3, graphics_y + btn.y_margin + 1)
            screen.line(rect_x_positions[i] + 7, graphics_y + btn.y_margin + 1)
            screen.stroke()
        else
            -- draw encoder icon
            screen.circle(rect_x_positions[i] + btn.x_margin, graphics_y + btn.y_margin, 2)
        end

        screen.fill()

        screen.move(rect_x_positions[i] + hor_txt_offset, text_y_row_1)
        screen.font_face(self.font_face)
        screen.text(self.button_text[btn.name].name)

        screen.move(rect_x_positions[i] + hor_txt_offset, text_y_row_2)
        screen.text(self.button_text[btn.name].value)

    end

    screen.stroke()
    screen.update()
end

return Footer
