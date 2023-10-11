local function getSunSign()
    local date = os.date("*t")
    local d = date.day
    local m = date.month

    if m == 1 then
        if d < 21 then return "capricorn" end
        return "aquarius"
    end
    if m == 2 then
        if d < 20 then return "aquarius" end
        return "pisces"
    end
    if m == 3 then
        if d < 21 then return "pisces" end
        return "aries"
    end
    if m == 4 then
        if d < 21 then return "aries" end
        return "taurus"
    end
    if m == 5 then
        if d < 22 then return "taurus" end
        return "gemini"
    end
    if m == 6 then
        if d < 22 then return "gemini" end
        return "cancer"
    end
    if m == 7 then
        if d < 24 then return "cancer" end
        return "leo"
    end
    if m == 8 then
        if d < 24 then return "leo" end
        return "virgo"
    end
    if m == 9 then
        if d < 24 then return "virgo" end
        return "libra"
    end
    if m == 10 then
        if d < 24 then return "libra" end
        return "scorpio"
    end
    if m == 11 then
        if d < 23 then return "scorpio" end
        return "sagittarius"
    end
    if m == 12 then
        if d < 22 then return "sagittarius" end
        return "capricorn"
    end
    return "oofouchowie"
end

return {
    {
        "score 100 points",
        function(game) return game.score >= 100 end
    },
    {
        "score 1000 points",
        function(game) return game.score >= 1000 end
    },
    {
        "score 10000 points",
        function(game) return game.score >= 10000 end
    },
    {
        "reach a timer of 1 min or more",
        function(game) return game.fuseTimer >= 60 end
    },
    {
        "complete 10+ quests",
        function(game) return game.numQuestsCompleted >= 10 end
    },
    {
        "score a negative letter value",
        function(game) return game.minLetterValueScore < 0 end
    },
    {
        "score 20+ with a single letter",
        function(game) return game.maxLetterValueScore >= 20 end
    },
    {
        "assemble a pokémon team",
        function(game) return #game.dict.usedPokemon >= 6 end
    },
    {
        "have 5+ quests at a time",
        function(game) return #game.quests == 5 end
    },
    {
        "type the current zodiac sun sign",
        function(game)
            return game.dict.usedWords[getSunSign()]
        end
    }
}