local Object = require "lib.classic"

local ParticleSystem = Object:extend()

function ParticleSystem:new()
    self.particles = {}

    self.generators = {
        _base = require "src.Particle",
        explosion = require "src.ExplosionParticle",
        badLetter = require "src.BadLetterParticle"
    }

    self.generators.explosion_many = self.generators.explosion.createMany
end

function ParticleSystem:addParticle(particleType, ...)
    local newParticle = self.generators[particleType](...)

    if #newParticle > 0 then
        for _, p in ipairs(newParticle) do
            table.insert(self.particles, p)
        end
    else
        table.insert(self.particles, newParticle)
    end
end

function ParticleSystem:update(dt)
    for i, p in ipairs(self.particles) do
        p:update(dt)
        if(p:remove()) then
            table.remove(self.particles, i)
        end
    end
end

function ParticleSystem:draw(colors, fonts, shaders)
    for _, p in ipairs(self.particles) do
        p:draw(colors, fonts, shaders)
    end
end

return ParticleSystem