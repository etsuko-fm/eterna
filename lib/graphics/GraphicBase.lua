local GraphicBase = {
    changed = true
}

function GraphicBase:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function GraphicBase:init()
    -- can be overridden
end

function GraphicBase:set(key, value)
    if self[key] ~= value then
        self[key] = value
        self.changed = true
    end
end

function GraphicBase:set_table(tbl_name, key, value)
    local t = self[tbl_name]
    if t[key] ~= value then
        t[key] = value
        self.changed = true
    end
end

return GraphicBase
