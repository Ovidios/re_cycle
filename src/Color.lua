local Object = require "lib.classic"

local Color = Object:extend()

local function allBetween01(tbl)
    for _, v in ipairs(tbl) do
        if v < 0 or v > 1 then
            return false
        end
    end
    return true
end

function Color:new(...)
    local args = {...}

    -- hexadecimal color values
    if type(args[1]) == "string" then
        self:fromHex(args[1])
        return
    end

    -- RGB(A) values from 0 to 1
    if allBetween01(args) then
        self:fromRGBA255(args[1], args[2], args[3], args[4])
        return
    end

    -- RGB(A) values from 0 to 255
    self:fromRGBA255(args[1], args[2], args[3], args[4])
end

function Color:fromRGBA(r, g, b, a)
    self.r = r or 0
    self.g = g or 0
    self.b = b or 0
    self.a = a or 1
end

function Color:fromRGBA255(r, g, b, a)
    local r, g, b, a = r or 0, g or 0, b or 0, a or 255
    self:fromRGBA(r/255, g/255, b/255, a/255)
end

function Color:fromHex(hex)
    -- TODO: implement
end

-- return the color values as a table
function Color:t()
    return {self.r, self.g, self.b, self.a}
end

function Color:set(a)
    local a = a or self.a
    love.graphics.setColor(self.r, self.g, self.b, a)
end

function Color:setBackground()
    love.graphics.setBackgroundColor(self:t())
end

Color.WHITE = Color(1, 1, 1, 1)

return Color