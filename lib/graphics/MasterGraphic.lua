MasterGraphic = {
  x = 32,
  y = 11,
  hide = false,
  drive_amount = 0,
  input_levels = { 0, 0 },
  pre_comp_levels = { 0, 0 },
  post_gain_levels = { 0, 0 },
  post_comp_levels = { 0, 0 },
  out_levels = { 0, 0 },
  out_level = 1.0,
  amp_history = { {}, {} }
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

local prev_frames = {}

function MasterGraphic:draw_lissajous()
  screen.line_width(1)
  local center_x = 64
  local center_y = 29
  local scale = 8
  local box_size = (scale + 2) * 2
  screen.level(4)
  screen.rect(center_x - box_size / 2 + 1, center_y - box_size / 2, box_size, box_size) -- don't let graphic touch the boundary
  screen.stroke()

  screen.level(5)
  -- draw previous frames with lower brightness
  for i, frame in ipairs(prev_frames) do
    if i == 1 then
      screen.level(11)
    elseif i == 2 then
      screen.level(7)
    else
      screen.level(3)
    end

    for _, pixel in ipairs(frame) do
      screen.pixel(pixel['x'], pixel['y'])
      screen.fill()
    end
  end
  -- shift all frame values
  for i = 3, 1, -1 do
    prev_frames[i + 1] = prev_frames[i]
  end
  screen.level(15)

  -- clear most recent frame (other values have been shifted)
  prev_frames[1] = {}

  for i, s in ipairs(self.amp_history[1]) do
    -- convert int8 (0-127) to float (0-1), then scale
    local divL = (s / 127) * scale
    local divR = (self.amp_history[2][i] / 127) * scale
    local x = center_x + divL
    local y = center_y - divR - 1
    screen.pixel(x, y)
    screen.fill()
    -- save state of pixels of current frame for feedback effect
    prev_frames[1][i] = {}
    prev_frames[1][i]['x'] = x
    prev_frames[1][i]['y'] = y
  end
end

local function draw_slider(x, y, w, h, fraction)
  -- h is expected to be uneven
  screen.level(1)

  -- index of bar to light up to indicate current fraction
  local target = math.floor((h * (1 - fraction)) / 2) * 2

  for i = 0, h - 1, 2 do
    if i == target then
      screen.level(15)
    else
      screen.level(1)
    end

    screen.rect(x, y + i, w, 1)
    screen.fill()
  end
end

local pre_level_x = 32
local comp_amount_x = 64 - 17
local drive_slider_x = 64 - 23
local post_meters_x = 64 + 13
local master_out_x = 64 + 13
local center_y = 29
local meters_y = center_y + 10
local meters_h = 20
local meter_width = 2

function MasterGraphic:draw_input_levels(x, y)
  local draw_pre = false
  if not draw_pre then return end

  screen.level(15)
  local pre_h_left = self.input_levels[1] * -meters_h
  local pre_h_right = self.input_levels[2] * -meters_h
  local pre_padding = 3

  screen.rect(x, y, meter_width, math.min(pre_h_left, -1))
  screen.fill()
  screen.rect(x + pre_padding, y, meter_width, math.min(pre_h_right, -1))
  screen.fill()
end

function MasterGraphic:draw_post_levels(x, y)
  -- levels after compression
  screen.level(7)
  local render = false -- feature flag
  if not render then return end

  local post_hL = self.post_comp_levels[1] * -meters_h
  local post_hR = self.post_comp_levels[2] * -meters_h
  local post_padding = 3

  screen.rect(x, y, meter_width, math.min(-1, post_hL))
  screen.fill()
  screen.rect(x + post_padding, y, meter_width, math.min(-1, post_hR))
  screen.fill()

  -- 0dB line
  screen.level(5)
  screen.move(x, center_y - 10)
  screen.line(x + 5, center_y - 10)
  screen.stroke()
end

function MasterGraphic:draw_drive_slider(x, y, w, h)
  screen.level(5)
  draw_slider(x, y, w, h, self.drive_amount)
end

function MasterGraphic:draw_final_out_level(x, y)
  screen.level(15)
  local master_out_hL = self.out_levels[1] * -meters_h
  local master_out_hR = self.out_levels[2] * -meters_h

  screen.rect(x, y, meter_width, math.min(-1, master_out_hL))
  screen.fill()
  screen.rect(x + 3, y, meter_width, math.min(-1, master_out_hR))
  screen.fill()

  -- 0dB line
  screen.level(5)
  screen.move(x, center_y - 10)
  screen.line(x + 5, center_y - 10)
  screen.stroke()
end

function MasterGraphic:draw_comp_amount(x, y)
  local comp_amountL = self.post_gain_levels[1] - self.post_comp_levels[1]
  local comp_amountR = self.post_gain_levels[2] - self.post_comp_levels[2]

  comp_amountL = math.min(comp_amountL * 2, 1)
  comp_amountR = math.min(comp_amountR * 2, 1)

  local comp_hL = comp_amountL * meters_h
  local comp_hR = comp_amountR * meters_h
  local comp_padding = 3

  screen.rect(x, y - meters_h - 1, meter_width, math.max(1, comp_hL))
  screen.fill()
  screen.rect(x + comp_padding, y - meters_h - 1, meter_width, math.max(1, comp_hR))
  screen.fill()

  -- -30dB line
  screen.level(5)
  screen.move(x, y)
  screen.line(x + 5, y)
  screen.stroke()
end

function MasterGraphic:render()
  if self.hide then return end
  screen.level(15)

  -- self:draw_input_levels(pre_level_x, meters_y)
  self:draw_comp_amount(comp_amount_x, meters_y)
  -- self:draw_post_levels(post_meters_x, meters_y)
  self:draw_drive_slider(drive_slider_x, center_y - 11, 4, 21)
  self:draw_final_out_level(master_out_x, meters_y)
  self:draw_lissajous()
end

return MasterGraphic
