local Object = require "lib.classic"

local function sign(x)
    if x > 0 then return 1 end
    if x < 0 then return -1 end
    return 0
end

local Particle = Object:extend()

function Particle:new(x, y, vx, vy)
    self.x = x or 0
    self.y = y or 0
    self.vx = vx or 0
    self.vy = vy or 0
    self.timer = 0
end

function Particle:update(dt)
    self.timer = self.timer + dt

    self.vy = self.vy + 1500 * dt
    self.vx = self.vx - self.vx * dt

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

function Particle:draw(colors, fonts, shaders)
    colors.accent:set()
    love.graphics.circle("fill", self.x, self.y, 5)
end

function Particle:remove()
    return self.timer >= 1
end

return Particle