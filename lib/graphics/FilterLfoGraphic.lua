local GraphicBase = require(from_root("lib/graphics/GraphicBase"))

FilterLfoGraphic = {
    hide = false,
    graph_w = 24,
    graph_h = 24,
    lfo_range = {}, -- start / end freq
    current = 0,
    current_history = {},
}

setmetatable(FilterLfoGraphic, { __index = GraphicBase })

function FilterLfoGraphic:set_lfo_range(start, _end)
    self:set_table("lfo_range", "start", start)
    self:set_table("lfo_range", "end", _end)
end

local function push_history(history, value, max_size)
    table.insert(history, 1, value)
    if max_size and #history > max_size then
        table.remove(history)
    end
end
function FilterLfoGraphic:draw_stripes(level)
    -- draw vertical black lines to make graphic less intense
    local start = 16
    local to = 128
    local y = 12
    for i = start, to do
        local x = i * 2
        screen.level(level)
        screen.line_width(1)
        screen.move(x, y)
        screen.line(x, y + 32)
        screen.stroke()
    end
end

function FilterLfoGraphic:render()
    if self.hide then return end

    screen.level(15)
    screen.line_width(1)
    local x = 64 - self.graph_w/2
    local y = 32 - self.graph_h/2 - 4
    -- screen.rect(x, y, self.graph_w, self.graph_h )
    -- screen.stroke()

    push_history(self.current_history, self.current, 24)

    screen.level(15)
    screen.rect(x - 4, y + self.current * (self.graph_h - 2), 2, 1)
    screen.fill()
    for i, c in ipairs(self.current_history) do
        screen.rect(x + (i-1), y + c * (self.graph_h - 2), 1, 1)
        screen.fill()
    end

    self:draw_stripes(0)

    self.rerender = false
end

return FilterLfoGraphic
