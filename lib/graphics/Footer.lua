Footer = {
    hide = false,
    active_fill = 10,    -- text brightness when corresponding button has been physically modified
    foreground_fill = 3, -- default text brightness
    background_fill = 1, -- fill of rect surrounding text
    -- text on buttons; `name` is displayed on top row, `value` on bottom row
    button_text = {
        e2 = {
            name = '',
            value = '',
        },
        e3 = {
            name = '',
            value = '',
        },
        k2 = {
            name = '',
            value = '',
        },
        k3 = {
            name = '',
            value = '',
        },
    },
    active_knob = nil,
    font_face = 1,
    brightness_state = {
        e2 = 1,
        e3 = 1,
        k2 = 1,
        k3 = 1,
    }
}


local btn_width = 128 / 4 - 1
local btn_height = 7

-- default position at bottom of screen; 2 rows of 7px and 1 px spacing
local ver_btn_spacing = 1
local base_y_row1 = 64 - (btn_height * 2) - ver_btn_spacing
local base_y_row2 = 64 - btn_height

-- positioning of footer elements
local graphics_ver_spacing = 2
local graphics_y = base_y_row1 + graphics_ver_spacing

local text_y_row_1 = base_y_row1 + 6
local text_y_row_2 = base_y_row2 + 7

local knob_y = 2
local enc_y = 2
local hor_txt_offset = 8

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

for i = 1, 4 do
    rect_x_positions[i] = (128 / 4) * (i - 1)
end

local buttons = {
    {
        name = "k2",
        type = "knob",
        x_margin = 2,
        y_margin = knob_y,
    },
    {
        name = "k3",
        type = "knob",
        x_margin = 2,
        y_margin = knob_y,
    },
    {
        name = "e2",
        type = "enc",
        x_margin = 4,
        y_margin = enc_y,
    },
    {
        name = "e3",
        type = "enc",
        x_margin = 4,
        y_margin = enc_y,
    }
}


function Footer:render()
    if self.hide then return end
    screen.line_width(1)
    screen.font_size(8)
    screen.font_face(self.font_face)

    -- draw 8 blocks
    screen.level(self.background_fill)

    for i = 1, 4 do
        screen.rect(rect_x_positions[i], base_y_row1 - 1, btn_width, 1)
        screen.rect(rect_x_positions[i], base_y_row2, btn_width, 1) -- btn_height
    end
    screen.fill()

    local fill = self.foreground_fill

    local active_button_switched = false
    for i, btn in ipairs(buttons) do
        if self.active_knob == btn.name then
            fill = self.active_fill
            self.active_knob = nil
            active_button_switched = true
        else
            fill = self.foreground_fill
            if not active_button_switched and self.brightness_state[btn.name] ~= nil and self.brightness_state[btn.name] > fill then
                fill = self.brightness_state[btn.name] - .1
            end
        end

        screen.level(math.floor(fill + .5))
        self.brightness_state[btn.name] = fill

        if btn.type == "knob" then
            -- draw knob icon
            screen.move(rect_x_positions[i] + btn.x_margin + 1, graphics_y + btn.y_margin)
            screen.line(rect_x_positions[i] + btn.x_margin + 3, graphics_y + btn.y_margin)
            screen.move(rect_x_positions[i] + btn.x_margin, graphics_y + btn.y_margin + 1)
            screen.line(rect_x_positions[i] + btn.x_margin + 4, graphics_y + btn.y_margin + 1)
            screen.stroke()
        else
            -- draw encoder icon
            local circle_x = rect_x_positions[i] + btn.x_margin
            local circle_y = graphics_y + btn.y_margin
            screen.move(circle_x, circle_y)
            screen.circle(circle_x, circle_y, 2)
        end

        screen.fill()

        -- write button text
        screen.move(rect_x_positions[i] + hor_txt_offset, text_y_row_1)
        screen.text(self.button_text[btn.name].name)
        screen.move(rect_x_positions[i] + hor_txt_offset, text_y_row_2)
        screen.text(self.button_text[btn.name].value)
    end

    screen.stroke()
end

return Footer
