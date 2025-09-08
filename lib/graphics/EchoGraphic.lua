EchoGraphic = {
    x = 64,
    y = 23,
    radius = 12,
    hide = false,
    curve = 'lin', --lin, convex, concave
    selected = 1,  -- time slice selected
    feedback = 1,
    wet = 1,
    time = 7,
}
local RADIANS = math.pi * 2

function EchoGraphic:new(o)
    o = o or {}           -- create state if not provided
    setmetatable(o, self) -- define prototype
    self.__index = self
    return o              -- return instance
end

local spacing = math.pi / 16
local offset = math.pi / 2 + spacing / 2

local function draw_slider(x, y, w, h, fraction)
    screen.level(1)
    for i = 1, w, 2 do
        screen.rect(x + i, y, 1, h)
        screen.fill()
    end
    screen.level(15)
    screen.rect(2 + math.floor((x + (w-2) * fraction) / 2) * 2, y, 1, h)
    screen.fill()
end

function EchoGraphic:draw_old_graphic()
    local radius = self.radius * (self.feedback / 4)
    local count = 0
    local r = 1
    local n = 1
    local brightness = 15
    while r < radius do
        count = count + 1
        r = math.floor((n) + n * self.time / 4)
        brightness = util.clamp(15 - count * 3, 1, 15)
        brightness = util.round_up(brightness * self.feedback / 4)
        screen.level(brightness)
        n = n + 1
        for i = 1, 8 do
            -- offset = offset + spacing/1000 % math.pi*2
            local slice = math.pi / 4

            local a1 = offset + (i * slice)
            local a2 = offset + (i + 1) * slice - spacing

            -- Compute start point of the arc
            local start_x = self.x + r * math.cos(a1)
            local start_y = self.y + r * math.sin(a1)
            screen.move(start_x, start_y)
            screen.arc(self.x, self.y, r, a1, a2)
            screen.line_width(1)
            screen.stroke()
            screen.move(self.x, self.y)
        end
    end
end


-- draws n_arcs arcs evenly spaced between start_radians and end_radians
-- spacing = angular gap (in radians) between arcs
-- line_width = stroke width
function EchoGraphic:draw_spaced_arcs(n_arcs, start_radians, end_radians, spacing, line_width)
    local total_radians = util.wrap(end_radians - start_radians, 0, RADIANS)
    local available_angle = total_radians - (n_arcs - 1) * spacing
    if available_angle <= 0 then
        print("no space to draw echo graphic with these params", start_radians, end_radians)
        return -- nothing to draw, spacing too large
    end

    local arc_angle = available_angle / n_arcs
    screen.line_width(line_width)

    for i = 0, n_arcs - 1 do
        local current_option = i + 1
        local a1 = start_radians + i * (arc_angle + spacing)
        local a2 = a1 + arc_angle

        local r = self.radius or 10
        local start_x = self.x + r * math.cos(a1)
        local start_y = self.y + r * math.sin(a1)

        screen.move(start_x, start_y)
        screen.arc(self.x, self.y, r, a1, a2)
        if current_option == self.time then
            screen.level(15)
        else
            screen.level(3)
        end

        screen.stroke()
    end
end

function EchoGraphic:draw_rects()
    local total_width = 48
    local num_options = 9
    local width_per_option = total_width/num_options
    local spacing = 1
    local width_per_block = width_per_option - spacing
    local x = self.x - total_width/2
    for i = 0, num_options - 1 do
        local current_option = i + 1
        screen.rect(x + i * (width_per_block + spacing), self.y, width_per_block, 4)
        if current_option == self.time then
            screen.level(15)
        else
            screen.level(3)
        end
        screen.fill()
    end
end

function EchoGraphic:draw_circles()
    local num_options = 9
    for i = 0, num_options - 1 do
        local current_option = i + 1
        screen.arc(self.x,self.y + 10, 1+i*2.3, math.pi, math.pi*2)
        if current_option == self.time then
            screen.level(15)
        else
            screen.level(1 * i % 3)
        end
        screen.line_width(1)
        screen.stroke()
    end
end

function EchoGraphic:render()
    if self.hide then return end
    local bottom = math.pi / 2
    local div = 9
    local availble_space = RADIANS * 0.5
    local negative_space = RADIANS - availble_space
    local radians_per_slice = (availble_space - (div*spacing)) / div
    print(negative_space)
    local a1 = bottom
    local a2 = -bottom
    -- self:draw_spaced_arcs(div, math.pi/16 * 4, math.pi/16 RADIANS/32, 4)
    -- self:draw_rects()
    self:draw_circles()

    screen.level(1)
    local w = 41
    local h = 3

    screen.level(1)
    local x = self.x - w / 2
    local y = self.y + 16

    draw_slider(x, y-4, w, h, self.feedback)
    draw_slider(x, y+1, w, h, self.wet)
end

return EchoGraphic
