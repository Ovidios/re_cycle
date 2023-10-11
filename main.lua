local Game = require "src.Game"
local Letter = require "src.Letter"

-- "globals"
game = Game()

STATE = "tutorial"

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

local function advanceTutorial()
    tutorialCard = tutorialCard + 1

    if tutorialCard <= #tutorialText then
        table.insert(tutorialCards, {
            video = tutorialVideos[tutorialCard],
            text = tutorialText[tutorialCard],
            x = math.random(-50, 50),
            y = math.random(-50, 50),
            r = (math.random() - 0.5) * math.pi/16,
            timer = 0
        })
        game.sounds.flip:stop()
        game.sounds.flip:setPitch(0.5)
        game.sounds.flip:play()
    end
end

function love.load()
    game:setupWindow()

    tutorialVideos = {
        love.graphics.newImage("res/img/tutorial_heart.png"),
        love.graphics.newVideo("res/video/tutorial_1.ogv"),
        love.graphics.newVideo("res/video/tutorial_2.ogv"),
        love.graphics.newVideo("res/video/tutorial_3.ogv"),
        love.graphics.newVideo("res/video/tutorial_3a.ogv"),
        love.graphics.newImage("res/img/tutorial_level.png"),
        love.graphics.newVideo("res/video/tutorial_4.ogv"),
        love.graphics.newImage("res/img/tutorial_heart.png")
    }
    tutorialText = {
        "welcome to the tutorial!\n[space] to continue",
        "type to add to your word",
        "only proper words (and single letters) are allowed",
        "spaces are useful, but limited\nuse them wisely!",
        "detonate multiple spaces at once to create complex words",
        "fulfill quests and level up for rewards",
        "keep typing to stall the timer, or lose the game",
        "that's it!\nyou'll figure out the rest!"
    }
    tutorialCard = 0
    tutorialCards = {}
    tutorialTimer = 0

    math.randomseed(os.time())

    advanceTutorial()
end

function love.update(dt)
    if STATE == "tutorial" then
        for i, card in ipairs(tutorialCards) do
            card.timer = math.min(card.timer + dt, 1)
            if i == #tutorialCards and card.video.play then
                card.video:play()
            elseif card.video.pause then
                card.video:pause()
            end
        end
        if tutorialCard > #tutorialVideos then
            tutorialTimer = tutorialTimer + dt
            if tutorialTimer >= 1 then
                STATE = "play"
            end
        end
    end

    if STATE == "play" then
        if not game.levelUp or (game.levelUp and game.isOver) then
            game:update(dt)
            game:updateQuests(dt)
            game.particles:update(dt)
            if not game:hasLegalMove() then
                game.isOver = true
            end
        else
            game:updateLevelUp(dt)
        end

        if game.isOver then
            game:updateOver(dt)
        end
    end
end

function love.draw()
    if STATE == "tutorial" then
        local w, h = love.graphics.getDimensions()
        for i, card in ipairs(tutorialCards) do
            local p = easeOutElastic(card.timer)

            game.colors.background:set(0.5 * card.timer)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

            love.graphics.push()
            love.graphics.translate(w/2 + card.x, h/2 + card.y)
            love.graphics.rotate(card.r)
            love.graphics.scale(p)

            game.colors.main:set()
            love.graphics.rectangle("fill", -250, -250 - 25, 500, 550)
            love.graphics.draw(card.video, 0, -25, 0, 1, 1, 225, 225)

            game.colors.background:set()
            love.graphics.setFont(game.fonts.main)
            love.graphics.printf(card.text, -225, 230 - 25, 450, "center")

            love.graphics.pop()
        end

        game.colors.accent:set()
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight() * tutorialTimer^5)
    end

    if STATE == "play" then
        game:drawCursor()
        game:drawLetters()
        game.particles:draw(game.colors, game.fonts, game.shaders)
        game:drawSpaceCounter()
        game:drawScrollBar()
        game:drawDetonateMessage()
        game:drawQuests()
        game:drawScore()
        game:drawFuseTimer()

        if(game.timer < 1) then
            game.colors.accent:set()
            love.graphics.rectangle("fill", 0, love.graphics.getHeight() * (1 - (1-game.timer)^5), love.graphics.getWidth(), love.graphics.getHeight())
        end
        
        if game.levelUp then
            game:drawLevelUp()
        end

        if game.isOver then
            game:drawGameOverScreen()
        end
    end
end

function love.keypressed(k, isrepeat)
    if k == "f11" or k == "1" then
        love.window.setFullscreen(not love.window.getFullscreen())
        game.shaders.letterShader:send("screenWidth", love.graphics.getWidth() * love.window.getDPIScale())
        game:scrollBy(0)
    end
    if STATE == "play" then
        game:keypressed(k, isrepeat)
    end
    if STATE == "tutorial" then
        if k == "space" or k == "return" then
            advanceTutorial()
        end
    end
end

function love.wheelmoved(x, y)
    game:scrollBy(-y * 100)
end

function love.resize(w, h)
    game.shaders.letterShader:send("screenWidth", w  * love.window.getDPIScale())
    game:scrollBy(0)
end

function love.mousepressed(x, y, button, istouch, presses)
    if STATE == "play" then
        game:mousepressed(x, y, button, istouch, presses)
    end
    if STATE == "tutorial" and button == 1 then
        advanceTutorial()
    end
end