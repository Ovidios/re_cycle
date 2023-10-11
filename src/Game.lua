local Object = require "lib.classic"
local Color = require "src.Color"
local Letter = require "src.Letter"
local LetterSpace = require "src.LetterSpace"
local LetterStart = require "src.LetterStart"
local Dictionary  = require "src.Dictionary"
local ParticleSystem = require "src.ParticleSystem"
local Quest = require "src.Quest"
local LevelUpCard = require "src.LevelUpCard"
local Achievements= require "src.Achievements"

local function lerp(a, b, p)
    return a * (1-p) + b * p
end

local function isAlpha(x)
    return #x == 1 and x >= "a" and x <= "z"
end

local function toBitTable(n, padTo)
    local padTo = padTo or -1
    local t = {}

    while n > 0 do
        local remainder = math.fmod(n, 2)
        t[#t+1] = remainder
        n = (n - remainder)/2
    end

    while #t < padTo do
        table.insert(t, 0)
    end

    return t
end

-- adapted from https://easings.net/#easeOutBounce
local function easeOutBounce(x)
    local n1 = 7.5625
    local d1 = 2.75
    
    if (x < 1 / d1) then
        return n1 * x * x
    elseif (x < 2 / d1) then
        x = x - 1.5 / d1
        return n1 * x * x + 0.75
    elseif (x < 2.5 / d1) then
        x = x - 2.25 / d1
        return n1 * x * x + 0.9375
    else
        x = x - 2.625 / d1
        return n1 * x * x + 0.984375
    end
end

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

-- adapted from https://easings.net/#easeInOutBack
local function easeInOutBack(x)
    local c1 = 1.70158
    local c2 = c1 * 1.525

    if x < 0.5 then return ((2*x)^2 * ((c2 + 1) * 2 * x - c2))/2 end
    return ((2*x - 2)^2 * ((c2 + 1) * (x * 2 - 2) + c2) + 2)/2
end

local Game = Object:extend()

function Game:new()
    -- visuals
    self.colors = {
        background = Color(40, 40, 40),
        accent =     Color(255, 198, 108),
        accent_bad = Color(255, 108, 108),
        main =       Color(255, 255, 255),
        secondary =  Color(94, 94, 94)
    }
    self.fonts = {
        main = love.graphics.newFont("res/Roboto-Bold.ttf", 26),
        letter = love.graphics.newFont("res/Roboto-Bold.ttf", 72),
        quest = love.graphics.newFont("res/Roboto-Bold.ttf", 30),
        tiny = love.graphics.newFont("res/Roboto-Bold.ttf", 18),
    }
    self.shaders = {
        letterShader = love.graphics.newShader(love.filesystem.read("res/shaders/letterShader.glsl")),
        bounceShader = love.graphics.newShader(love.filesystem.read("res/shaders/bounceShader.glsl"))
    }

    self.shaders.letterShader:send("screenWidth", 1280 * love.window.getDPIScale())
    self.shaders.bounceShader:send("time", 0)

    -- audio
    self.sounds = {
        flip = love.audio.newSource("res/sounds/flip.ogg", "static"),
        dice = love.audio.newSource("res/sounds/dice.ogg", "static"),
        bad = love.audio.newSource("res/sounds/bad.wav", "static"),
        clear = love.audio.newSource("res/sounds/clear.wav", "static"),
        complete = love.audio.newSource("res/sounds/complete.wav", "static"),
        level = love.audio.newSource("res/sounds/level.wav", "static"),
        select = love.audio.newSource("res/sounds/select.wav", "static")
    }

    -- gameplay stuff
    self.spaces = 3
    self.expMax = 10
    self.expCurrent = 0
    self.expDisplay = 0
    self.score = 0
    self.scoreDisplay = 0
    self.scoreMultiplier = 10
    self.passiveExpRate = 0
    self.passiveExp = 0
    self.expMult = 1

    self.currentWord = ""
    self.letters = {
        LetterStart(150, 0)
    }
    self.questList = require "res.quests"
    self.quests = {}
    self.numQuestsCompleted = 0

    self.timer = 0
    self.scroll = 0
    self.scrollTarget = 0

    self.maxLength = 0

    self.fuseTimer = 30
    self.fuseTimerMult = 1

    self.isOver = false
    self.gameOverTimer = 0
    self.doRestart = false

    self.levelUp = false
    self.levelUpTimer = 0
    self.levelUpOutTimer = 0
    self.cardSelected = false
    self.cards = {
        LevelUpCard(),
        LevelUpCard(),
        LevelUpCard()
    }
    self.levelUpCardNumber = 3
    self.cardList = require "res.level_rewards"

    -- letter values
    self.letterValues = {
        a = 1, e = 1, i = 1, o = 1, u = 1, l = 1, n = 1, s = 1, t = 1, r = 1,
        d = 2, g = 2,
        b = 3, c = 3, m = 3, p = 3,
        f = 4, h = 4, v = 4, w = 4, y = 4,
        k = 5,
        j = 8, x = 8,
        q = 10, z = 10
    }
    self.letterValueMod = 0
    self.letterValueModLookup = {
        a = 0, e = 0, i = 0, o = 0, u = 0, l = 0, n = 0, s = 0, t = 0, r = 0,
        d = 0, g = 0, b = 0, c = 0, m = 0, p = 0, f = 0, h = 0, v = 0, w = 0,
        y = 0, k = 0, j = 0, x = 0, q = 0, z = 0
    }
    self.letterValueMult = 1
    self.minLetterValueScore = math.huge
    self.maxLetterValueScore = -math.huge

    self.dict = Dictionary()
    self.particles = ParticleSystem()
    self.achievements = Achievements("achievements.json")
    self.onTypeQQuestRolls = 0
    self.timedTriggers = {}
end

function Game:setupWindow()
    -- set up window
    love.window.setMode(1280, 720, {
        vsync = 0,
        msaa = (love.window.getDPIScale() <= 1) and 8 or 0,
        resizable = true,
        minwidth = 800,
        minheight = 600,
        highdpi = true
    })

    -- set background color
    self.colors.background:setBackground()
end

function Game:drawSpaceCounter()
    -- setup
    self.colors.accent:set()
    love.graphics.setFont(self.fonts.main)
    love.graphics.setLineWidth(5)
    
    -- draw circle
    love.graphics.circle("fill", 36, 36, 10)

    -- print counter
    love.graphics.print(self.spaces, 54, 21)

    -- draw progress bar
    love.graphics.rectangle("line", 26, 54, 128, 21, 10, 10)
    love.graphics.stencil(function()
        love.graphics.rectangle("fill", 26, 54, 128, 21, 10, 10)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.rectangle("fill", 26, 54, 128 * self.expDisplay/self.expMax, 21)
    love.graphics.setStencilTest()
end

function Game:drawCursor()
    love.graphics.push()
    love.graphics.translate(-self.scroll, love.graphics.getHeight()/2)
    love.graphics.setShader(self.shaders.letterShader)

    local p = (math.sin(self.timer * 4) + 0.5)/1.5 * 4

    self.colors.secondary:set(p)
    
    local lastLetter = self.letters[#self.letters]
    local x = lastLetter:getNextDrawX()
    local y = lastLetter.y

    love.graphics.rectangle("fill", x - 50, y - 50, 10, 100, 5, 5)

    love.graphics.setShader()
    love.graphics.pop()
end

function Game:update(dt)
    self.timer = self.timer + dt
    self.passiveExp = self.passiveExp + self.passiveExpRate * dt
    while self.passiveExp >= 1 and not self.levelUp and not self.isOver do
        self.passiveExp = self.passiveExp - 1
        self:addExp(1)
    end
    self.shaders.bounceShader:send("time", self.timer)
    self.expDisplay = lerp(self.expDisplay, self.expCurrent, dt * 4)
    self.scroll = lerp(self.scroll, self.scrollTarget, dt * 4)

    for _, letter in ipairs(self.letters) do
        letter:update(dt)
    end

    if #self.currentWord > 0 then
        self.fuseTimer = self.fuseTimer - dt * self.fuseTimerMult
        if self.fuseTimer <= 0 then
            self.isOver = true
        end
    end

    self.scoreDisplay = lerp(self.scoreDisplay, self.score, dt * 4)

    if not self.over then
        self.achievements:update(self)
    end

    for i = #self.timedTriggers, 1, -1 do
        local trigger = self.timedTriggers[i]
        trigger.timer = trigger.timer - dt
        if trigger.timer <= 0 then
            trigger.callback(self)
            table.remove(self.timedTriggers, i)
        end
    end
end

function Game:updateLevelUp(dt)
    self.levelUpTimer = math.min(self.levelUpTimer + dt, 1)

    if self.cardSelected then
        self.levelUpOutTimer = self.levelUpOutTimer + dt
        if self.levelUpOutTimer >= 1 then
            for _, card in ipairs(self.cards) do
                if card.selected then card.onSelect(self) end
            end

            self.cards = {}
            self.levelUp = false
            self.levelUpTimer = 0
            self.levelUpOutTimer = 0
            self.cardSelected = false
        end
    end

    local trySelect = true
    local w, h = love.graphics.getDimensions()
    for i, card in ipairs(self.cards) do
        card:update(w/2 + (i-(#self.cards + 1)/2) * 200, h - 100, dt, trySelect)
        trySelect = trySelect and not card.hovered
    end
end

function Game:drawLevelUp()
    local w, h = love.graphics.getDimensions()
    local p1 = easeOutElastic(self.levelUpTimer)
    local p2 = easeInOutBack(self.levelUpOutTimer)

    self.colors.background:set(0.75 * (self.levelUpTimer - self.levelUpOutTimer))
    love.graphics.rectangle("fill", 0, 0, w, h)

    for i = #self.cards, 1, -1 do
        local card = self.cards[i]
        local r = (i-(#self.cards + 1)/2) * 0.025 * math.pi
        card:draw(w/2 + (i-(#self.cards + 1)/2) * 200, h - 100, self.colors, self.fonts, p1, p2, r)
    end

    self.colors.accent:set(p1 - p2)
    love.graphics.setFont(self.fonts.letter)
    love.graphics.printf("level up!", 0, 50, w, "center")

    self.colors.main:set(p1 - p2)
    love.graphics.setFont(self.fonts.main)
    love.graphics.printf("choose your reward", 0, 125, w, "center")
end

function Game:updateOver(dt)
    if self.doRestart then
        self:reset()
        self.gameOverTimer = self.gameOverTimer - dt
        if self.gameOverTimer < 0 then
            self.isOver = false
            self.score = 0
            self.doRestart = false
        end
    else
        self.gameOverTimer = math.min(self.gameOverTimer + dt, 1)
    end
end

function Game:drawLetters()
    love.graphics.push()
    love.graphics.translate(-self.scroll, love.graphics.getHeight()/2)
    love.graphics.setShader(self.shaders.letterShader)

    for i = #self.letters, 1, -1 do
        local letter = self.letters[i]
        letter:draw(self.colors, self.fonts)
    end

    love.graphics.setShader()
    love.graphics.pop()
end

function Game:drawFuseTimer()
    love.graphics.push()

    if self.fuseTimer < 5 then
        love.graphics.translate((math.random()-0.5) * (5 - self.fuseTimer) * 10, (math.random()-0.5) * (5 - self.fuseTimer) * 10)
    end
    self.colors.accent_bad:set(1/self.fuseTimer)
    local time = math.ceil(self.fuseTimer)
    if self.fuseTimer <= 10 then
        time = math.ceil(self.fuseTimer * 10)/10
        if time == math.ceil(time) then
            time = time .. ".0"
        end
    end
    love.graphics.setFont(self.fonts.letter)
    love.graphics.printf(time, 25, 15, love.graphics.getWidth() - 50, "right")

    if self.fuseTimer < 5 then
        love.graphics.setLineWidth((5 - self.fuseTimer) * 10)
        love.graphics.rectangle("line", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end

    love.graphics.pop()
end

function Game:drawScrollBar()
    self.colors.secondary:set(0.5)

    local scrollMax = self.letters[#self.letters]:getNextX() - love.graphics.getWidth() + 200
    local contentMax = love.graphics.getWidth() + scrollMax
    local screenMin = self.scroll
    local screenMax = self.scroll + love.graphics.getWidth()

    local startP = screenMin / contentMax
    local endP = math.min(screenMax / contentMax, 1)
    local pLen = endP - startP
    local barWidth = love.graphics.getWidth() - 40

    love.graphics.rectangle("fill",
    20 + startP * barWidth, love.graphics.getHeight()-30,
    pLen * barWidth, 10, 5, 5)
end

function Game:drawDetonateMessage()
    if self:hasSelected() then
        local message = "[space] to detonate"
        self.colors.accent:set()
        if not self.dict:isLegalString(self:getUnselectedString()) then
            message = "this would form illegal words!"
            self.colors.accent_bad:set()
        end
        love.graphics.setShader(self.shaders.bounceShader)
        love.graphics.setFont(self.fonts.main)
        love.graphics.printf(message, 0, love.graphics.getHeight()/2 + 65, love.graphics.getWidth(), "center")
        love.graphics.setShader()
    end
end

function Game:drawQuests()
    local lastLetter = self.letters[#self.letters]
    local y = love.graphics.getHeight()/2 + lastLetter.y - 75

    love.graphics.setShader(self.shaders.letterShader)
    for i, quest in ipairs(self.quests) do
        local x = lastLetter:getNextDrawX() - 44 - self.scroll
        quest:draw(x, y, self.colors, self.fonts)
        y = y - 85 * (1 - easeOutBounce(quest.fadeTimer))
    end
    love.graphics.setShader()
end

function Game:updateQuests(dt)
    for i = #self.quests, 1, -1 do
        local quest = self.quests[i]
        quest:update(dt)
        if quest.fadeTimer >= 1 then 
            table.remove(self.quests, i)
        end
    end
end

function Game:getLetterValue(char)
    return math.floor(
        (
            (self.letterValues[char] or 0) +
            self.letterValueMod +
            (self.letterValueModLookup[char] or 0)
        )
        * self.letterValueMult
    )
end

function Game:addLetter(char)
    local lastLetter = self.letters[#self.letters]
    local x = lastLetter:getNextX()
    local y = lastLetter.y
    local newLetter = Letter(char, x, y, self:getLetterValue(char))

    if char == " " then
        newLetter = LetterSpace(x, y)
    else
        self.fuseTimer = self.fuseTimer + self:getLetterValue(char)
        self.minLetterValueScore = math.min(self.minLetterValueScore, self:getLetterValue(char))
        self.maxLetterValueScore = math.max(self.maxLetterValueScore, self:getLetterValue(char))
        self.sounds.flip:setPitch(1 + (math.random() - 0.5) * 2 * 0.1)
        self.sounds.flip:stop()
        self.sounds.flip:play()
    end

    if char == "q" then
        for _ = 1, self.onTypeQQuestRolls, 1 do
            if math.random(1, 2) == 1 then
                self:addRandomQuest()
            end
        end
    end

    table.insert(self.letters, newLetter)
    self:scrollBy(math.huge) -- scrolling by a huge amount, since it's capped anyway
    self:updateRegisteredWords()
    self:updateMaxLength()
end

function Game:updateMaxLength()
    if #self.currentWord > self.maxLength then
        if math.floor(#self.currentWord / 10 + 0.5) > math.floor(self.maxLength / 10 + 0.5) then
            self:addRandomQuest()
            self.timer = self.timer * 1.01
        end
        self.maxLength = #self.currentWord
    end
end

function Game:addExp(x)
    local amount = x
    if type(x) == "string" then
        amount = self:getLetterValue(x)
    end

    self.expCurrent = self.expCurrent + amount * self.expMult
    self.score = self.score + math.floor(amount * self.scoreMultiplier)

    if self.expCurrent >= self.expMax then
        self.expCurrent = self.expCurrent - self.expMax
        self.expMax = self.expMax + math.floor(self.expMax * 1)
        
        self.levelUp = true
        self.sounds.level:stop()
        self.sounds.level:play()
        self:randomCards(self.levelUpCardNumber)
    end
end

function Game:clearRandomWord()
    local count = 0
    for _ in self.currentWord:gmatch("%S+") do
        count  = count + 1
    end
    local num = math.random(1, count)
    local wordNum = 0
    for _, letter in ipairs(self.letters) do
        if letter.char == " " or letter.char == "" then
            wordNum = wordNum + 1
        elseif wordNum == num then
            letter.kill = true
        end
    end

    for i = #self.letters, 1, -1 do
        local letter = self.letters[i]
        if letter.kill then table.remove(self.letters, i) end
    end

    self:collapseLetters()
    self:scrollBy(0)
end

function Game:clearLongestWord()
    local count = 0
    local i = 0
    local maxLength = 0
    for word in self.currentWord:gmatch("%S+") do
        count  = count + 1
        if #word > maxLength then
            i = count
            maxLength = #word
        end
    end

    local wordNum = 0
    for _, letter in ipairs(self.letters) do
        if letter.char == " " or letter.char == "" then
            wordNum = wordNum + 1
        elseif wordNum == i then
            letter.kill = true
        end
    end

    for i = #self.letters, 1, -1 do
        local letter = self.letters[i]
        if letter.kill then table.remove(self.letters, i) end
    end

    self:collapseLetters()
    self:scrollBy(0)
end

function Game:keypressed(k, isrepeat)
    if not self.isOver and not self.levelUp then
        if isAlpha(k) then
            if self.dict:isLegalString(self.currentWord .. k) then
                self.currentWord = self.currentWord .. k
                self:addExp(k)
                self:addLetter(k)
            else
                local lastLetter = self.letters[#self.letters]
                local x = lastLetter:getNextX() - self.scroll
                local y = lastLetter.y + love.graphics.getHeight()/2
                self.particles:addParticle("badLetter", k, x, y, 250, -50)
                self.sounds.bad:setVolume(0.75)
                self.sounds.bad:stop()
                self.sounds.bad:play()
            end
        elseif k == "space" then
            if self:hasSelected() then
                self:detonate()
            elseif self.spaces > 0 then
                self.spaces = self.spaces - 1
                self.currentWord = self.currentWord .. " "
                self:addLetter(" ")
            end
        end
    elseif not self.levelUp then
        if k == "space" then
            self.doRestart = true
            self.gameOverTimer = 1.25
        end
    end
end

function Game:scrollBy(amount)
    local scrollMax = self.letters[#self.letters]:getNextX() - love.graphics.getWidth() + 200
    self.scrollTarget = self.scrollTarget + amount
    self.scrollTarget = math.min(self.scrollTarget, scrollMax)
    self.scrollTarget = math.max(self.scrollTarget, 0)
end

function Game:mousepressed(x, y, button, istouch, presses)
    if not self.levelUp then
        if button == 1 then
            local x_fixed, y_fixed = x + self.scroll, y - love.graphics.getHeight()/2
            for _, letter in ipairs(self.letters) do
                if letter:contains(x_fixed, y_fixed) then
                    letter:onClick()
                    if letter.char == " " and letter.selected then
                        self.sounds.select:stop()
                        self.sounds.select:setVolume(1.1)
                        self.sounds.select:setPitch(0.9 + math.random() * 0.2)
                        self.sounds.select:play()
                    end
                end
            end
        end
    else
        if button == 1 then
            for _, card in ipairs(self.cards) do
                if card.hovered then
                    card.selected = true
                    self.cardSelected = true
                    break
                end
            end
        end
    end
end

function Game:detonate()
    -- would the resulting word be legal?
    if not self.dict:isLegalString(self:getUnselectedString()) then
        for _, letter in ipairs(self.letters) do
            if letter.selected then
                letter:onClick()
            end
        end
        return
    end
    -- destroy all selected spaces
    local destroyed = 0
    for i = #self.letters, 1, -1 do
        local letter = self.letters[i]
        if letter.char == " " and letter.selected then
            destroyed = destroyed + 1
            self.particles:addParticle("explosion_many", letter.x - self.scroll - 25, letter.y + love.graphics.getHeight()/2, 16, 500)
            table.remove(self.letters, i)
            self.spaces = self.spaces + 1
        end
    end
    self.sounds.clear:stop()
    self.sounds.clear:setVolume(0.75)
    self.sounds.clear:setPitch(0.9 + destroyed * 0.1)
    self.sounds.clear:play()
    self:collapseLetters()
end

function Game:getUnselectedString()
    local s = ""
    for _, letter in ipairs(self.letters) do
        if not letter.selected then
            s = s .. letter.char
        end
    end
    return s
end

function Game:collapseLetters()
    for i = 2, #self.letters, 1 do
        local this = self.letters[i]
        local prev = self.letters[i-1]

        this.x = prev:getNextX()
    end
    self.currentWord = self:getUnselectedString()
    self:updateRegisteredWords()
end

function Game:hasSelected()
    for _, letter in ipairs(self.letters) do
        if letter.selected then
            return true
        end
    end
    return false
end

function Game:randomCards(num)
    self.cards = {}
    for _ = 1, num, 1 do
        local n = math.random(1, #self.cardList)
        table.insert(self.cards, LevelUpCard(unpack(self.cardList[n])))
    end
end

function Game:updateRegisteredWords()
    for word in self.currentWord:gmatch("%S+") do
        if self.dict:registerWord(word) then
            self:wordRegisteredCallback(word)
            print("New word registered: " .. word .. "!")
        end
    end
end

function Game:wordRegisteredCallback(word)
    for _, quest in ipairs(self.quests) do
        if quest:condition(word) then
            quest.completed = true
            quest:awardReward(self)
            self.numQuestsCompleted = self.numQuestsCompleted + 1
            self.sounds.complete:stop()
            self.sounds.complete:play()
            self.scoreMultiplier = self.scoreMultiplier * 1.1
        end
    end
end

function Game:addRandomQuest()
    local n = math.random(1, #self.questList)
    table.insert(self.quests, Quest(unpack(self.questList[n])))
end

function Game:hasLegalMove()
    -- test for spaces
    if self.spaces > 0 then
        return true
    end

    -- test for letters
    for l = string.byte("a"), string.byte("z"), 1 do
        if self.dict:isLegalString(self.currentWord .. string.char(l)) then
            return true
        end
    end

    -- test for removing spaces
    local _, num_spaces = string.gsub(self.currentWord, " ", "")
    if num_spaces > 15 then return true end -- hacky "fix"
    for n = 0, 2^(num_spaces) - 2, 1 do
        if self:testSpaceRemovalLegal(n, num_spaces) then
            return true
        end
    end

    return false
end

function Game:testSpaceRemovalLegal(num, padTo)
    local s = ""
    local tbl = toBitTable(num, padTo)
    local i = 0
    for _, l in ipairs(self.letters) do
        if l.char == " " then
            i = i + 1
            if tbl[#tbl - i + 1] == 1 then s = s .. l.char end
        else
            s = s .. l.char
        end
    end
    return self.dict:isLegalString(s)
end

function Game:drawScore()
    local w, h = love.graphics.getDimensions()
    self.colors.secondary:set()
    love.graphics.setFont(self.fonts.letter)
    love.graphics.printf(math.floor(self.scoreDisplay + 0.5), 0, h - 110, w, "center")
end

function Game:drawGameOverScreen()
    local w, h = love.graphics.getDimensions()

    local p = math.min(math.max(self.gameOverTimer, 0), 1)
    local p_eased = easeOutBounce(p)

    love.graphics.push()
    love.graphics.translate(0, -h + h * p_eased)

    self.colors.accent_bad:set()
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setShader(self.shaders.bounceShader)

    self.colors.main:set()
    love.graphics.setFont(self.fonts.letter)
    love.graphics.printf(self.score, 0, h/2 - 75, w, "center")

    self.colors.background:set()
    love.graphics.setFont(self.fonts.main)
    love.graphics.printf("game over!", 0, h/2, w, "center")

    self.colors.background:set(0.5)
    love.graphics.print("[space] to restart", 15, h - 45)

    love.graphics.setShader()

    self.achievements:drawProgressCard(100, 100, self.colors, self.fonts)

    love.graphics.pop()
end

function Game:reset()
    self.spaces = 3
    self.expMax = 10
    self.expCurrent = 0
    self.expDisplay = 0
    --self.score = 0            -- resetting the score only once the game has actually restarted, so the game over screen shows the correct score
    self.scoreDisplay = 0
    self.scoreMultiplier = 10
    self.passiveExpRate = 0
    self.passiveExp = 0
    self.expMult = 1
    self.currentWord = ""
    self.letters = {
        LetterStart(150, 0)
    }
    self.quests = {}
    self.timer = 1
    self.scroll = 0
    self.scrollTarget = 0
    self.maxLength = 0
    self.fuseTimer = 30
    self.fuseTimerMult = 1
    self.levelUp = false
    self.levelUpTimer = 0
    self.levelUpOutTimer = 0
    self.cardSelected = false
    self.levelUpCardNumber = 3
    self.letterValueMod = 0
    self.letterValueModLookup = {
        a = 0, e = 0, i = 0, o = 0, u = 0, l = 0, n = 0, s = 0, t = 0, r = 0,
        d = 0, g = 0, b = 0, c = 0, m = 0, p = 0, f = 0, h = 0, v = 0, w = 0,
        y = 0, k = 0, j = 0, x = 0, q = 0, z = 0
    }
    self.letterValueMult = 1
    self.onTypeQQuestRolls = 0
    self.dict = Dictionary()
    self.timedTriggers = {}
end

return Game