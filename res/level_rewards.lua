local rewards = {
    {
        "+1 space",
        function(game) game.spaces = game.spaces + 1 end
    },
    {
        "+10% to all letter values (rounded down)",
        function(game) game.letterValueMult = game.letterValueMult * 1.1 end
    },
    {
        "+25% exp multiplier (does not affect score or timer)",
        function(game) game.expMult = game.expMult * 1.25 end
    },
    {
        "+1 option during level up",
        function(game) game.levelUpCardNumber = game.levelUpCardNumber + 1 end
    },
    {
        "-1 option during level up; +2 spaces",
        function(game)
            game.levelUpCardNumber = math.max(game.levelUpCardNumber - 1, 1)
            game.spaces = game.spaces + 2
        end
    },
    {
        "passively generate exp (+1 per second)",
        function(game) game.passiveExpRate = game.passiveExpRate + 1 end
    },
    {
        "clear a random word",
        function(game) game:clearRandomWord() end
    },
    {
        "clear the longest word",
        function(game) game:clearLongestWord() end
    },
    {
        "+1 quest",
        function(game) game:addRandomQuest() end
    },
    {
        "clone current quests",
        function(game)
            local newQuests = {}
            for _, quest in ipairs(game.quests) do
                table.insert(newQuests, quest:clone())
            end
            for _, quest in ipairs(newQuests) do
                table.insert(game.quests, quest)
            end 
        end
    },
    {
        "+1d4-2 to each letter value (before multipliers)",
        function(game)
            for l, m in pairs(game.letterValueModLookup) do
                local roll = math.random(1, 4) - 2
                game.letterValueModLookup[l] = m + roll
            end
            game.sounds.dice:setVolume(0.25)
            game.sounds.dice:play()
        end
    },
    {
        "-1 to each vowel (aeiouy), +1 to each consonant",
        function(game)
            for l, m in pairs(game.letterValueModLookup) do
                if l == "a" or l == "e" or l == "i" or l == "o" or l == "u" or l == "y" then
                    game.letterValueModLookup[l] = m - 1
                else
                    game.letterValueModLookup[l] = m + 1
                end
            end
        end
    },
    {
        "50% chance for +1 quest when typing q",
        function(game)
            game.onTypeQQuestRolls = game.onTypeQQuestRolls + 1
        end
    },
    {
        "-10% timer speed",
        function(game)
            game.fuseTimerMult = game.fuseTimerMult * 0.9
        end
    },
    {
        "+1d4-2 spaces",
        function(game)
            local roll = math.random(1, 4) - 2
            game.spaces = math.max(game.spaces + roll, 0)
            game.sounds.dice:setVolume(0.25)
            game.sounds.dice:play()
        end
    },
    {
        "+5 to a random letter, -5 to another",
        function(game)
            local alpha = "abcdefghijklmnopqrstuvwxyz"
            local n1, n2 = math.random(1, 26), math.random(1, 26)
            local key1 = string.sub(alpha, n1, n1)
            local key2 = string.sub(alpha, n2, n2)
            print(key1, key2)
            game.letterValueModLookup[key1] = game.letterValueModLookup[key1] + 5
            game.letterValueModLookup[key2] = game.letterValueModLookup[key2] - 5
            game.sounds.dice:setVolume(0.25)
            game.sounds.dice:play()
        end
    },
    {
        "+1d20 % to all letter values (rounded down)",
        function(game)
            local roll = math.random(1, 20)/100
            game.letterValueMult = game.letterValueMult * (1 + roll)
            game.sounds.dice:setVolume(0.25)
            game.sounds.dice:play()
        end
    },
    {
        "for 15 seconds: +200% to letter values",
        function(game)
            game.letterValueMult = game.letterValueMult * 2
            table.insert(game.timedTriggers, {
                timer = 15,
                callback = function(game)
                    game.letterValueMult = game.letterValueMult / 2
                end,
                text = "+200% to letter values"
            })
        end
    },
    {
        "nothing :(",
        function(game) end
    }
}

return rewards