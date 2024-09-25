function zigzag_line()
  local y_offset = 4
  screen.line_width(1)
  screen.level(1)
  screen.move(0, 32 - y_offset / 2)
  screen.level(3)
  for i = 1, 32, 1 do
    screen.line(
      i * 4,
      32 - y_offset / 2 + (i % 2 * y_offset)
    )
  end
  screen.stroke()
  screen.update()
end

shapes = {
  zigzag_line = zigzag_line,
}
return shapes
