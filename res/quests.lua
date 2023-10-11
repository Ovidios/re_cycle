local gems = require "res.lists.gems"
local animals = require "res.lists.animals"
local pokemon = require "res.lists.pokemon"
local gen5 = {unpack(pokemon, 505, 669)}
local ld_themes = require "res.lists.ld_themes"
local mtg = require "res.lists.mtg"
local mtg_keywords = require "res.lists.mtg_keywords"
local elements = require "res.lists.elements"
local colors = require "res.lists.colors"
local emojis = require "res.lists.emojis"
local tng = require "res.lists.tng"
local zodiac = require "res.lists.zodiac"

local function contains(tbl, el)
    for _, e in ipairs(tbl) do
        if e == el then return true end
    end
    return false
end

local quests = {
    {
        "a gemstone!",
        "20exp",
        function(self, word) return contains(gems, word) end,
        function(self, game) game:addExp(20) end
    },
    {
        "an animal!",
        "20exp",
        function(self, word) return contains(animals, word) end,
        function(self, game) game:addExp(20) end
    },
    {
        "a 7+ letter word!",
        "+30exp",
        function(self, word) return #word >= 7 end,
        function(self, game) game:addExp(30) end
    },
    {
        "a 10+ letter word!",
        "+1",
        function(self, word) return #word >= 10 end,
        function(self, game) game.spaces = game.spaces + 1 end
    },
    {
        "a word containing q!",
        "+2",
        function(self, word) if #word > 1 and string.match(word, "q") then return true end return false end,
        function(self, game) game.spaces = game.spaces + 2 end
    },
    {
        "a word without a or e!",
        "+2",
        function(self, word) if #word > 1 and not string.match(word, "a") and not string.match(word, "e") then return true end return false end,
        function(self, game) game.spaces = game.spaces + 2 end
    },
    {
        "a pokémon!",
        "+1",
        function(self, word) return contains(pokemon, word) end,
        function(self, game) game.spaces = game.spaces + 1 end
    },
    {
        "a gen 5 pokémon!",
        "+3",
        function(self, word) return contains(gen5, word) end,
        function(self, game) game.spaces = game.spaces + 3 end
    },
    {
        "a single-word ludum dare theme!",
        "+1",
        function(self, word) return contains(ld_themes, word) end,
        function(self, game) game.spaces = game.spaces + 1 end
    },
    {
        "a single-word magic card name!",
        "+1",
        function(self, word) return contains(mtg, word) end,
        function(self, game) game.spaces = game.spaces + 1 end
    },
    {
        "a magic the gathering keyword ability!",
        "+1",
        function(self, word) return contains(mtg_keywords, word) end,
        function(self, game) game.spaces = game.spaces + 1 end
    },
    {
        "an element of the periodic table!",
        "+1",
        function(self, word) return contains(elements, word) end,
        function(self, game) game.spaces = game.spaces + 1 end
    },
    {
        "a color!",
        "+20exp",
        function(self, word) return contains(colors, word) end,
        function(self, game) game:addExp(20) end
    },
    {
        "a palindrome!",
        "+1",
        function(self, word) return #word > 1 and word == string.reverse(word) end,
        function(self, game) game.spaces = game.spaces + 1 end
    },
    {
        "an emoji!",
        "+50exp",
        function(self, word) return contains(emojis, word) end,
        function(self, game) game:addExp(50) end
    },
    {
        "a star trek tng episode!",
        "+1",
        function(self, word) return contains(tng, word) end,
        function(self, game) game.spaces = game.spaces + 1 end
    },
    {
        "a zodiac sign!",
        "+50exp",
        function(self, word) return contains(zodiac, word) end,
        function(self, game) game:addExp(50) end
    }

}

return quests