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

function Page:enter()
  -- can be overloaded. should be called when page is entered
end

function Page:exit()
  -- can be overloaded. should be called when page is exited
end

return Page