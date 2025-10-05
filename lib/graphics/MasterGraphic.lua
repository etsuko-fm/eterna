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

local prev_frames = {}

function MasterGraphic:draw_lissajous()
  screen.line_width(1)
  local center_x = 64
  local center_y = 29
  local scale = 8
  local box_size = (scale + 2) * 2
  screen.level(4)
  screen.rect(center_x - box_size / 2 + 1, center_y - box_size / 2, box_size, box_size) -- don't let graphic touch the boundary
  -- screen.circle(center_x, center_y, scale / 2 + 3)
  screen.stroke()

  screen.level(5)

  -- draw previous frames with lower brightness
  for i, frame in ipairs(prev_frames) do
    -- if i % 2 == 0 then
    --   lev = lev-1
    --   screen.level(math.max(lev,1))
    -- end
    if i == 1 then
      screen.level(10)
    elseif i == 2 then
      screen.level(5)
      -- elseif i == 3 then screen.level(1)
    else
      screen.level(1)
    end

    for j, pixel in ipairs(frame) do
      screen.pixel(pixel['x'], pixel['y'])
      screen.fill()
    end
  end
  -- shift all frame values
  for i = 3, 1, -1 do
    prev_frames[i + 1] = prev_frames[i]
  end
  screen.level(15)

  prev_frames[1] = {}
  for i, s in ipairs(amp_historyL) do
    if i < 16 then
      local divL = (s / 127) * scale
      local divR = (amp_historyR[i] / 127) * scale
      local x = center_x + divL
      local y = center_y - divR - 1
      screen.pixel(x, y)
      screen.fill()
      prev_frames[1][i] = {}
      prev_frames[1][i]['x'] = x
      prev_frames[1][i]['y'] = y
    end
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
local master_out_x = 64 + 20
local center_y = 29
local meters_y = center_y + 10
local meters_h = 20
local meter_width = 2

function MasterGraphic:render()
  if self.hide then return end
  screen.level(15)
  local draw_pre = false

  -- pre levels
  if draw_pre then
    local pre_h_left = self.input_levels[1] * -meters_h
    local pre_h_right = self.input_levels[2] * -meters_h
    local pre_padding = 3
    screen.rect(pre_level_x, meters_y, meter_width, math.min(pre_h_left, -1))
    screen.fill()
    screen.rect(pre_level_x + pre_padding, meters_y, meter_width, math.min(pre_h_right, -1))
    screen.fill()
    screen.move(64, 32)
  end

  -- comp amount
  local comp_amountL = self.post_gain_levels[1] - self.post_comp_levels[1]
  local comp_amountR = self.post_gain_levels[2] - self.post_comp_levels[2]

  -- comp levels are pretty low, you'd never reach a 60dB reduction. so we multiply by 3 so a full meter down
  -- equals 30dB reduction

  comp_amountL = math.min(comp_amountL * 2, 1)
  comp_amountR = math.min(comp_amountR * 2, 1)

  local comp_hL = comp_amountL * meters_h
  local comp_hR = comp_amountR * meters_h
  local comp_padding = 3
  screen.rect(comp_amount_x, meters_y - meters_h - 1, meter_width, math.max(1, comp_hL))
  screen.fill()
  screen.rect(comp_amount_x + comp_padding, meters_y - meters_h - 1, meter_width, math.max(1, comp_hR))
  screen.fill()

  -- -30dB line for comp amount
  screen.level(5)
  screen.move(comp_amount_x, meters_y)
  screen.line(comp_amount_x + 5, meters_y)
  screen.stroke()

  -- post levels
  screen.level(7)
  local post_hL = self.post_comp_levels[1] * -meters_h
  local post_hR = self.post_comp_levels[2] * -meters_h
  local post_padding = 3
  screen.rect(post_meters_x, meters_y, meter_width, math.min(-1, post_hL))
  screen.fill()
  screen.rect(post_meters_x + post_padding, meters_y, meter_width, math.min(-1, post_hR))
  screen.fill()

  -- drive slider
  screen.level(5)
  local slider_h = 21
  draw_slider(drive_slider_x, center_y - 11, 4, slider_h, self.drive_amount)

  -- final out level, calculate here, to save a poll to supercollider
  screen.level(15)
  local master_out_hL = self.out_levels[1] * -meters_h
  local master_out_hR = self.out_levels[2] * -meters_h

  screen.rect(master_out_x, meters_y, meter_width, math.min(-1, master_out_hL))
  screen.fill()
  screen.rect(master_out_x + 3, meters_y, meter_width, math.min(-1, master_out_hR))
  screen.fill()

  -- 0dB line for post level
  screen.level(5)
  screen.move(post_meters_x, center_y - 10)
  screen.line(post_meters_x + 5, center_y - 10)
  screen.stroke()

  -- 0dB line for master out
  screen.move(master_out_x, center_y - 10)
  screen.line(master_out_x + 5, center_y - 10)
  screen.stroke()

  -- lissajous
  self:draw_lissajous()
end

return MasterGraphic
