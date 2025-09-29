MasterGraphic = {
    x = 32,
    y = 11,
    hide = false,
    drive_amount = 0,
    pre_comp_levels = {0,0},
    post_comp_levels = {0,0},
    comp_amount_levels = {0,0},
    lissajous_buf = {},
}

function MasterGraphic:new(o)
    -- create state if not provided
    o = o or {}

    -- define prototype
    setmetatable(o, self)
    self.__index = self

    -- return instance
    return o
end

function MasterGraphic:add_sample(l, r)
  table.insert(self.lissajous_buf, {l, r})
  if #self.lissajous_buf > 30 then
    table.remove(self.lissajous_buf, 1)
  end
end

function MasterGraphic:draw_lissajous()
  local center_x = 64
  local center_y = 32
  local scale = 30

  for i, s in ipairs(self.lissajous_buf) do
    screen.level(i)
    local x = center_x + s[1] * scale
    local y = center_y - s[2] * scale
    screen.pixel(x, y)
  end
  screen.stroke()
end

local function draw_slider(x, y, w, h, fraction)
    screen.level(1)
    local target = math.floor((h * (1 - fraction)) / 2) * 2

    for i = 0, h-1, 2 do
        if i == target then
            screen.level(15)
        else
            screen.level(1)
        end

        screen.rect(x, y + i, w, 1)
        screen.fill()
    end
    screen.level(15)

    -- -- indictor
    -- local offset = 2
    -- local indicator_y_raw = (h-offset) * fraction
    -- local indicator_y =  offset + math.floor((y + (h-offset) * fraction) / 2) * 2
    -- screen.rect(x, indicator_y, w, 1)
    -- screen.fill()
end


local meters_x = 32
local drive_slider_x = meters_x + 14
local post_meters_x = drive_slider_x + 7
local padding = 7
local meters_y = 40
local meters_h = 20

function MasterGraphic:render()
    if self.hide then return end
    screen.level(15)

    -- post levels
    local post_level_x = meters_x + padding
    local post_hL = self.post_comp_levels[1] * -meters_h
    local post_hR = self.post_comp_levels[2] * -meters_h
    screen.rect(post_meters_x, meters_y, 4, post_hL)
    screen.fill()
    screen.rect(post_meters_x + padding, meters_y, 4, post_hR)
    screen.fill()

    screen.level(4)
    local pre_level_x = meters_x

    -- pre levels 
    local pre_h_left = self.pre_comp_levels[1] * -meters_h
    local pre_h_right = self.pre_comp_levels[2] * -meters_h

    screen.rect(pre_level_x, meters_y, 4, math.min(pre_h_left, -1))
    screen.fill()
    screen.rect(pre_level_x + padding, meters_y, 4, math.min(pre_h_right, -1))
    screen.fill()
    screen.move(64,32)
    
    local comp_padding = 5
    local comp_x = post_meters_x + comp_padding
    -- comp amount
    screen.rect(comp_x, meters_y-meters_h-5, 1, math.min(self.comp_amount_levels[1], 1) * meters_h)
    screen.rect(comp_x+padding, meters_y-meters_h-5, 1, math.min(self.comp_amount_levels[2], 1) * meters_h)
    screen.fill()

    draw_slider(drive_slider_x, meters_y-25, 4, 25, self.drive_amount)
    -- lissajous
    -- self:add_sample(self.post_comp_levels[1], self.post_comp_levels[2])
    -- self:draw_lissajous()

end

return MasterGraphic
