Window = {
  x = 0,
  y = 0,
  w = 128,
  h = 64,
  title = "WINDOW",
  title_x = 64,
  font_face = 68,   -- TITLE_FONT
  brightness = 15,
  bar_height = 7,
  num_pages = nil,
  current_page = nil,
  enc1n = 0,
  page_indicator_disabled = false,
}

function Window:new(o)
  o = o or {}             -- create state if not provided
  setmetatable(o, self)   -- define prototype
  self.__index = self
  return o
end

local page_breaks = { 2, 3, 4, 5, 6, 8, 10, 12, 13 }

local function spacing_for(i)
  local s = 0
  for _, b in ipairs(page_breaks) do
    if i > b then
      s = s + 1
    end
  end
  return s
end

function Window:draw_page_indicator()
  -- draw stripes on top left that indicate which page is active
  screen.level(11)
  local h = 3
  local y = 2

  for page_id = 1, self.num_pages do
    local zero_idx = page_id-1
    local extra_spacing = spacing_for(page_id)
    local x = 2 + zero_idx * 1 + extra_spacing

    if page_id == self.current_page then
      screen.level(0)
      screen.rect(x, y, 1, h)
      screen.fill()
      screen.level(3)
      if self.enc1n > 0 then
        -- line from bottom to top
        screen.rect(x, y, 1, self.enc1n)
      elseif self.enc1n < 0 then
        -- line from top to bottom
        screen.rect(x, y + 3, 1, self.enc1n)
      end
    else
      screen.level(6)
      screen.rect(x, y, 1, h)
    end
    screen.fill()
  end
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
  if not self.page_indicator_disabled then
    self:draw_page_indicator()
  end

end

return Window
