local Object = require "lib.classic"
local json = require "lib.json"

local dist = function(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

local Achievements = Object:extend()

function Achievements:new(filename)
    self.achievements = require "res.achievements"
    self.progress = {}
    self.filename = filename
    self:generateProgressTable()

    if filename and love.filesystem.getInfo(filename) then
        self.progress = json.decode(love.filesystem.read(filename))
    elseif filename then
        love.filesystem.write(filename, json.encode(self.progress))
    end
end

function Achievements:generateProgressTable()
    for i, _ in ipairs(self.achievements) do
        self.progress[i] = {
            complete = false
        }
    end
end

function Achievements:update(game)
    for i, achievement in ipairs(self.achievements) do
        if achievement[2](game) then
            self.progress[i].complete = true
        end
    end
    love.filesystem.write(self.filename, json.encode(self.progress))
end

function Achievements:drawProgressCard(x, y, colors, fonts)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(0.01 * math.pi)

    colors.main:set()
    love.graphics.rectangle("fill", -75, -75, 150, 200)

    colors.background:set()
    love.graphics.rectangle("fill", -62.5, -62.5, 125, 125)

    local mx, my = love.mouse.getPosition()
    mx = mx - x
    my = my - y

    local ach_i = 0
    local min_dist = math.huge

    if mx >= -62.5 and mx <= 62.5 and my >= -62.5 and my <= 62.5 then
        local text = ""

        for i, achievement in ipairs(self.achievements) do
            local x = (i-1)%4
            local y = math.floor((i-1)/4)
            local d = dist(-37.5 + 25 * x, -37.5 + 25 * y, mx, my)
            if d < min_dist then
                text = achievement[1]
                ach_i = i
                min_dist = d
            end
        end

        if min_dist <= 20 then
            colors.background:set()
            love.graphics.setFont(fonts.tiny)
            love.graphics.printf(text, -70, 70, 140, "center")
        end
    end

    love.graphics.setLineWidth(5)
    for i, achievement in ipairs(self.achievements) do
        local ach_prog = self.progress[i]
        colors.secondary:set()
        if ach_prog.complete then colors.accent:set() end
        local x = (i-1)%4
        local y = math.floor((i-1)/4)
        local radius = 8
        if i == ach_i and min_dist <= 20 then radius = 10 end
        love.graphics.circle("line", -37.5 + 25 * x, -37.5 + 25 * y, radius)
        if ach_prog.complete then
            love.graphics.circle("fill", -37.5 + 25 * x, -37.5 + 25 * y, radius)
        end
    end

    love.graphics.pop()
end

return Achievements