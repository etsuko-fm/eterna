MasterGraphic = {
  x = 32,
  y = 11,
  hide = false,
  drive_amount = 0,
  pre_comp_levels = { 0, 0 },
  post_comp_levels = { 0, 0 },
  post_gain_levels = { 0, 0 },
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
  local scale = 18
  screen.level(4)
  screen.rect(center_x - (scale + 2) / 2, center_y - (scale + 2) / 2, scale + 2, scale + 2) -- don't let graphic touch the boundary
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
      local divL = (s / 128 - 0.5) * scale
      local divR = (amp_historyR[i] / 128 - 0.5) * scale
      local x = center_x + divL
      local y = center_y - divR
      -- screen.rect(center_x - 8 + i, center_y, 1, divL)
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
local drive_slider_x = 64 - 17
local post_meters_x = 64 + 12
local center_y = 29
local meters_y = center_y + 10
local meters_h = 20


function MasterGraphic:render()
  if self.hide then return end
  screen.level(15)
  local draw_pre = false

  -- pre levels
  if draw_pre then
    local pre_h_left = self.pre_comp_levels[1] * -meters_h
    local pre_h_right = self.pre_comp_levels[2] * -meters_h
    local pre_padding = 3
    local pre_meter_width = 2
    screen.rect(pre_level_x, meters_y, pre_meter_width, math.min(pre_h_left, -1))
    screen.fill()
    screen.rect(pre_level_x + pre_padding, meters_y, pre_meter_width, math.min(pre_h_right, -1))
    screen.fill()
    screen.move(64, 32)
  end

  -- post levels
  local post_hL = self.post_comp_levels[1] * -meters_h
  local post_hR = self.post_comp_levels[2] * -meters_h
  local post_padding = 3
  local post_meter_width = 2
  screen.rect(post_meters_x, meters_y, post_meter_width, math.min(-1, post_hL))
  screen.fill()
  screen.rect(post_meters_x + post_padding, meters_y, post_meter_width, math.min(-1, post_hR))
  screen.fill()

  screen.level(5)
  local slider_h = 21
  draw_slider(drive_slider_x, center_y - 11, 4, slider_h, self.drive_amount)

  -- 0dB lines
  screen.level(5)
  screen.move(post_meters_x, center_y - 10)
  screen.line(post_meters_x + 5, center_y - 10)
  screen.stroke()

  -- lissajous
  self:draw_lissajous()
end

return MasterGraphic
