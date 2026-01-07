local Page = {
  -- A page defines which functionality is bound to the currently rendered screen.
  -- It is therefore created with callback functions for the three hardware knobs and encoders,
  -- and one for rendering the screen.
  name = nil,
  interface = nil, -- table with functions the page may invoke
  e1 = nil,
  e2 = nil,
  e3 = nil,
  k1_hold_on = nil,
  k1_hold_off = nil,
  k2_on = nil,
  k2_off = nil,
  k3_on = nil,
  k3_off = nil,
  graphic = nil,
  footer = nil,
}

function Page:create(o)
  -- create state if not provided
  o = o or {}

  -- define prototype
  setmetatable(o, self)
  self.__index = self

  -- return instance
  return o
end

function Page:pre_render()
  -- can be overriden. called before update_graphics_state
    return false
end

-- overrideable hook
function Page:update_graphics_state()
  -- can be overriden. called before render
end

function Page:needs_rerender()
  return (self.graphic and self.graphic.changed)
      or (self.footer and self.footer.changed or not self.footer.animation_finished)
      or (window and window.changed)
end

function Page:render(force)
  -- hook to insert before rendering; if returns true, skips render
  if self:pre_render() then return end

  -- hook to make window/footer/graphic updates, which will toggle their `changed` flag
  self:update_graphics_state()

  -- determine if rendering is necessary
  if not force and not self:needs_rerender() then return end

  -- render all layers
  screen.clear()
  window:render()
  window.changed = false

  self.graphic:render()
  self.graphic.changed = false

  self.footer:render()
  self.footer.changed = false

  screen.update()
end

function Page:enter()
  -- can be overriden. should be called when page is entered
end

function Page:exit()
  -- can be overriden. should be called when page is exited
end

return Page
