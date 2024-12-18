local Scene = {
  -- A scene defines which functionality is bound to the currently rendered screen.
  -- It is therefore created with callback functions for the three hardware knobs and encoders,
  -- and for rendering the screen.

  name = nil,
  render = nil,
  e1 = nil,
  e2 = nil,
  e3 = nil,
  k1_hold_on = nil,
  k1_hold_off = nil,
  k2_on = nil,
  k2_off = nil,
  k3_on = nil,
  k3_off = nil,
}

function Scene:create(o)
  -- create state if not provided
  o = o or {}

  -- define prototype
  setmetatable(o, self)
  self.__index = self

  -- return instance
  return o
end

return Scene
