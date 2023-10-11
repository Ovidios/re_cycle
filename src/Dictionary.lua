local Object = require "lib.classic"
local words = require "res.dict"
local pokemon = require "res.lists.pokemon"
local mtg = require "res.lists.mtg"
local mtg_keywords = require "res.lists.mtg_keywords"
local elements = require "res.lists.elements"
local colors = require "res.lists.colors"
local emojis = require "res.lists.emojis"
local tng = require "res.lists.tng"
local zodiac = require "res.lists.zodiac"

local Dictionary = Object:extend()

local function contains(tbl, el)
    for _, e in ipairs(tbl) do
        if e == el then return true end
    end
    return false
end

function Dictionary:new()
    self.words = words

    self:addWords(pokemon)
    self:addWords(mtg)
    self:addWords(elements)
    self:addWords(colors)
    self:addWords(mtg_keywords)
    self:addWords(emojis)
    self:addWords(tng)
    self:addWords(zodiac)

    self.lookup = self:createLookup()
    self.usedWords = {}
    self.usedPokemon = {}
end

function Dictionary:addWords(tbl)
    for _, w in ipairs(tbl) do
        table.insert(self.words, w)
    end
end

function Dictionary:createLookup()
    local lookup = {}
    for _, word in ipairs(self.words) do
        lookup[word] = true
    end

    return lookup
end

function Dictionary:hasWord(word)
    -- always allow single-character "words"
    if #word == 1 then return true end

    if self.lookup[word] then return true end
    return false
end

function Dictionary:isLegalString(str)
    for word in str:gmatch("%S+") do
        if not self:hasWord(word) then
            return false
        end
    end
    return true
end

function Dictionary:registerWord(word)
    if contains(pokemon, word) and not contains(self.usedPokemon, word) then
        table.insert(self.usedPokemon, word)
    end
    if self.usedWords[word] then
        return false -- word has already been registered!
    end
    self.usedWords[word] = true
    return true
end

return Dictionary