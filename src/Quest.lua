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

local function easeInBack(x)
    local c1 = 1.70158
    local c3 = c1 + 1

    return c3 * x * x * x - c1 * x * x
end

local Quest = Object:extend()

function Quest:new(name, rewardText, condition, reward)
    self.name = name or "a word!"
    self.rewardText = rewardText or "+0"
    self.condition = condition or function(self, word) return true end
    self.awardReward = reward or function(self, game) print("hurray!") end
    self.timer = 0
    self.fadeTimer = 0
    self.completed = false
end

function Quest:clone()
    return Quest(self.name, self.rewardText, self.condition, self.awardReward)
end

function Quest:update(dt)
    self.timer = self.timer + dt
    
    if self.completed then
        self.fadeTimer = math.min(self.fadeTimer + dt * 1.5, 1)
    end
end

function Quest:draw(x, y, colors, fonts)
    local p = math.min(self.timer, 1)
    local p_eased = easeOutElastic(p)

    local fade_p = math.min(self.fadeTimer * 2, 1)

    local containsMouse = self:containsMouse(x, y, fonts.quest)

    love.graphics.push()
    love.graphics.translate(x - 100 * easeInBack(fade_p), y)
    love.graphics.rotate(-math.pi/2 * (1 - p_eased))
    love.graphics.scale(p_eased)

    if containsMouse then love.graphics.rotate(-0.01 * math.pi) end

    local width = fonts.quest:getWidth(self.name) + 50
    
    colors.accent:set(1 - easeInBack(fade_p))
    love.graphics.rectangle("fill", -width/2, -75, width, 50, 25, 25)
    love.graphics.polygon("fill", -20, -25, 20, -25, 0, 0)

    colors.background:set(1 - easeInBack(fade_p))
    love.graphics.setFont(fonts.quest)
    love.graphics.printf(self.name, -width/2, -70, width, "center")
 
    colors.accent:set(1 - easeInBack(fade_p))
    love.graphics.printf(self.rewardText, -width/2 - 20, -90, 1000, "center", -math.pi/4, 1, 1, 500)

    love.graphics.pop()
end

function Quest:containsMouse(x, y, font)
    local width = font:getWidth(self.name) + 50
    local mx, my = love.mouse.getPosition()
    return
        mx >= x - width/2 and
        mx <= x + width/2 and
        my >= y - 75 and
        my <= y - 25
end

function Quest:checkWord(word)
    if self:condition(word) then

    end
end

return Quest