EnvGraphic = {
    x = 32,
    y = 24,
    hide = false,
    curve = 'lin', --lin, convex, concave
    attack = { 0, 0, 0, 0, 0, 0, },
    decay = { 0, 0.1, .2, .3, .4, .5, .6 }
}

function EnvGraphic:new(o)
    o = o or {}           -- create state if not provided
    setmetatable(o, self) -- define prototype
    self.__index = self
    return o              -- return instance
end

local h = 12
local spacing = 3
local env_scale = 9
function EnvGraphic:render()
    if self.hide then return end
    -- for i=1,6 do
    --     -- starting point for all envs
    --     screen.move(self.x + i*spacing, self.y+h)

    --     -- attack line
    --     screen.line(self.x + i * spacing + self.attack[i], self.y)

    --     -- decay line
    --     screen.line(self.x + i * spacing + h + self.decay[i], self.y+h)
    --     screen.stroke()
    -- end
    for i = 1, 6 do
        -- attack
        screen.level(15)
        local x = self.x + ((i - 1) % 3) * 22
        local y = self.y + math.floor((i - 1) / 3) * 18
        local attack_w = self.attack[i] * env_scale
        local decay_w = self.decay[i] * env_scale
        if attack_w < 2 and decay_w < 3 then
            decay_w = 3
        elseif attack_w < 3 and decay_w <2 then
            decay_w = 3
        end


        screen.move(x, y)
        screen.line(x + attack_w, y - h)
        screen.line(x + attack_w + decay_w, y)

        screen.line(x, y)
        screen.fill()
    end
end

return EnvGraphic
