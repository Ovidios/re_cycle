local Particle = require "src.Particle"

-- adapted from https://easings.net/#easeOutElastic
local function easeOutElastic(x)
    local c4 = (2 * math.pi) / 3

    if x == 0 then
        return 0
    elseif x == 1 then
        return 1
    else
        return 2^(-10 * x) * math.sin((x * 10 - 0.75) * c4) + 1
    end
end

local BadLetterParticle = Particle:extend()

function BadLetterParticle:new(char, x, y, vx, vy)
    BadLetterParticle.super.new(self, x, y, vx, vy)

    self.char = char or "?"
end

function BadLetterParticle:update(dt)
    self.timer = self.timer + dt * 0.5
end

function BadLetterParticle:draw(colors, fonts, shaders)
    local p = math.min(self.timer, 1)
    local p_eased = easeOutElastic(p)
    love.graphics.push()
    love.graphics.translate(self.x - 50, self.y + 50)
    love.graphics.rotate(-math.pi/3 + p_eased * math.pi * 3/3)
    love.graphics.translate(-10 + 10 * p_eased, -100)

    colors.accent_bad:set(math.sin(self.timer * math.pi))
    love.graphics.rectangle("fill", 0, 0, 100, 100, 10, 10)

    love.graphics.setFont(fonts.letter)
    colors.background:set()
    love.graphics.printf(self.char, 0, 5, 100, "center")

    love.graphics.pop()
end

return BadLetterParticle