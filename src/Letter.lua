local Object = require "lib.classic"

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

local function lerp(a, b, p)
    return a * (1-p) + b * p
end

local Letter = Object:extend()

function Letter:new(char, x, y, score)
    self.char = char or "?"
    self.x = x or 0
    self.y = y or 0
    self.draw_x = self.x
    self.draw_y = self.y
    self.timer = 0
    self.score = score or 0
end

function Letter:update(dt)
    self.draw_x = lerp(self.draw_x, self.x, dt * 4)
    self.draw_y = lerp(self.draw_y, self.y, dt * 4)
    self.timer = self.timer + dt
end

function Letter:draw(colors, fonts)
    -- manage rotate-in animation
    local p = math.min(self.timer, 1)
    local p_eased = easeOutElastic(p)
    love.graphics.push()
    love.graphics.translate(self.draw_x - 50, self.draw_y + 50)
    love.graphics.rotate(-math.pi/3 + p_eased * math.pi/3)
    love.graphics.translate(-10 + 10 * p_eased, -100)

    colors.main:set(p_eased)
    love.graphics.rectangle("fill", 0, 0, 100, 100, 10, 10)

    love.graphics.setFont(fonts.letter)
    colors.background:set()
    love.graphics.printf(self.char, 0, 5, 100, "center")

    love.graphics.setFont(fonts.main)
    colors.secondary:set(0.25)
    love.graphics.printf(self.score, 5, 5, 90, "right")

    love.graphics.pop()
end

function Letter:getNextX()
    return self.x + 110
end

function Letter:getNextDrawX()
    return self.draw_x + 110
end

function Letter:onClick()
    -- do nothing
end

function Letter:contains(x, y)
    return x >= self.x - 50 and x <= self.x + 50 and y >= self.y - 50 and y <= self.y + 50
end

return Letter