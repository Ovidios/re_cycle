local Letter = require "src.Letter"

local LetterStart = Letter:extend()

function LetterStart:new(x, y)
    LetterStart.super.new(self, "", x, y)
end

function LetterStart:draw()
    -- do nothing
end

function LetterStart:getNextX()
    return self.x
end

function LetterStart:getNextDrawX()
    return self.x
end

return LetterStart