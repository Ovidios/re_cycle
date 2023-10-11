local Object = require "lib.classic"

-- adapted from https://easings.net/#easeInOutBack
local function easeInOutBack(x)
    local c1 = 1.70158
    local c2 = c1 * 1.525

    if x < 0.5 then return ((2*x)^2 * ((c2 + 1) * 2 * x - c2))/2 end
    return ((2*x - 2)^2 * ((c2 + 1) * (x * 2 - 2) + c2) + 2)/2
end

local LevelUpCard = Object:extend()

function LevelUpCard:new(name, onSelect)
    self.name = name or "(nothing)"
    self.onSelect = onSelect or function(game) end
    self.selected = false
    self.hovered = false
    self.hoverTimer = 0
end

function LevelUpCard:update(x, y, dt, trySelect)
    local mx, my = love.mouse.getPosition()
    if trySelect and mx >= x - 150 and mx <= x + 150 and my >= y - 200 and my <= y + 200 then
        self.hovered = true
        self.hoverTimer = math.min(self.hoverTimer + dt * 4, 1)
    else
        self.hovered = false
        self.hoverTimer = math.max(self.hoverTimer - dt * 4, 0)
    end
end

function LevelUpCard:draw(x, y, colors, fonts, p1, p2, r)
    love.graphics.push()
    love.graphics.translate(x, y + 400 * p2)
    if self.selected then
        love.graphics.translate(0, (- love.graphics.getHeight() - 800) * p2)
    end
    love.graphics.rotate(r * (1 - easeInOutBack(self.hoverTimer)))
    love.graphics.scale(1 + easeInOutBack(self.hoverTimer) * 0.1)

    colors.background:set()
    love.graphics.rectangle("fill", -150, -200 * (p1 - p2) - 200 * easeInOutBack(self.hoverTimer), 300, 400, 25, 25)

    colors.main:set()
    love.graphics.setLineWidth(10)
    love.graphics.rectangle("line", -150, -200 * (p1 - p2) - 200 * easeInOutBack(self.hoverTimer), 300, 400, 25, 25)

    love.graphics.setFont(fonts.main)
    colors.accent:set()
    love.graphics.printf(self.name, -130, -150 * (p1 - p2) - 200 * easeInOutBack(self.hoverTimer), 260, "center")
    love.graphics.pop()
end

return LevelUpCard