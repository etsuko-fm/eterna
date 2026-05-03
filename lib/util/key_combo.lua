-- Detects when any two keys are held down simultaneously.
-- Usage:
--[=====[ 
local combo = ComboDetector.new()
local result = combo:press("left")      -- nil
result = combo:press("space")           -- {"left", "space"}
if result then
    print("Combo: " .. result[1] .. " + " .. result[2])
end

combo:release("space")

result = combo:press("right")           -- {"left", "right"}
if result then
    print("Combo: " .. result[1] .. " + " .. result[2])
end
--]=====]

local ComboDetector = {}
ComboDetector.__index = ComboDetector

function ComboDetector.new()
    local self = setmetatable({}, ComboDetector)
    self.held = {}
    self.count = 0
    return self
end

function ComboDetector:press(key)
    if self.held[key] then
        -- state did not change
        return nil
    end

    self.held[key] = true
    self.count = self.count + 1

    if self.count == 2 then
        local a, b
        for k in pairs(self.held) do
            if not a then a = k else b = k end
        end
        return {a, b}
    end

    return nil
end

function ComboDetector:release(key)
    if self.held[key] then
        self.held[key] = nil
        self.count = self.count - 1
    end
end

function ComboDetector:keys_held()
    return self.count
end


function ComboDetector:reset()
    self.held = {}
    self.count = 0
end

return ComboDetector