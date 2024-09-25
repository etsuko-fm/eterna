function zigzag_line(x, y, w, h, zigzag_width)
  zigzag_width = zigzag_width or 4
  screen.line_width(1)
  screen.level(1)
  screen.move(x, y - h / 2)
  screen.level(3)
  
  for i = 1, w/zigzag_width do
    screen.line(
      i * zigzag_width,
      y - h / 2 + (i % 2 * h)
    )
  end
  screen.stroke()
  screen.update()
end
--todo: make it a class with a render method would make sense? only if it had more methods
shapes = {
  zigzag_line = zigzag_line,
}
return shapes
