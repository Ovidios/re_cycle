local Particle = require "src.Particle"

local ExplosionParticle = Particle:extend()

function ExplosionParticle:new(x, y, vx, vy)
    ExplosionParticle.super.new(self, x, y, vx, vy)

    self.trail = {}
    self.trailTimer = 0
end

function ExplosionParticle.createMany(x, y, num, str)
    local t = {}
    for i = 1, num, 1 do
        local a = i/num * math.pi * 2
        local p = ExplosionParticle(x, y, math.cos(a) * str, math.sin(a) * str)
        table.insert(t, p)
    end
    return t
end

function ExplosionParticle:update(dt)
    self.timer = self.timer + dt

    self:updateTrail(dt)

    self.vy = self.vy - self.vy * dt * 8
    self.vx = self.vx - self.vx * dt * 8

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

function ExplosionParticle:updateTrail(dt)
    self.trailTimer = self.trailTimer + dt
    if self.trailTimer >= 0.01 then
        self.trailTimer = self.trailTimer - 0.01
        table.insert(self.trail, {x = self.x, y = self.y})
        while #self.trail > 10 do
            table.remove(self.trail, 1)
        end
    end
end

function ExplosionParticle:draw(colors, fonts, shaders)
    love.graphics.setShader(shaders.letterShader)
    for i = 2, #self.trail, 1 do
        local this = self.trail[i]
        local prev = self.trail[i-1]
        colors.accent:set()
        love.graphics.setLineWidth(10 * (1 - self.timer))
        love.graphics.line(this.x, this.y, prev.x, prev.y)
        love.graphics.circle("fill", this.x, this.y, 5 * (1 - self.timer))
        love.graphics.circle("fill", prev.x, prev.y, 5 * (1 - self.timer))
    end
    love.graphics.setShader()
end

function ExplosionParticle:remove()
    return self.timer >= 1
end

return ExplosionParticle