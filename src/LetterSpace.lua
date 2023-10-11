local Letter = require "src.Letter"

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

local dist = function(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

local LetterSpace = Letter:extend()

function LetterSpace:new(x, y)
    LetterSpace.super.new(self, " ", x, y)

    self.selected = false
end

function LetterSpace:draw(colors, fonts)
    if self.selected then
        local p = math.max(math.min(self.timer, 1), 0)

        local p_eased = easeOutElastic(p)

        colors.accent:set()
        love.graphics.setLineWidth(7.5)
        love.graphics.circle("line", self.draw_x - 25, self.y, 5 + 15 * p_eased)
    else
        local p = math.min(self.timer, 1)
        local p_eased = easeOutElastic(p)

        colors.accent:set()
        love.graphics.circle("fill", self.draw_x - 125 + 100 * p_eased, self.y, 10)
    end
end

function LetterSpace:getNextX()
    return self.x + 60
end

function LetterSpace:onClick()
    if self.selected then
        self.selected = false
        self.timer = 1
    else
        self.selected = true
        self.timer = 0
    end
end

function LetterSpace:contains(x, y)
    return dist(self.x - 25, self.y, x, y) <= 20
end

function LetterSpace:getNextDrawX()
    return self.draw_x + 60
end

return LetterSpace