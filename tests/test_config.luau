require("./stub_env")

local Config = Test.need("Config")

local expected = {
	{ "Soggy Fry", "Common", 50, 1 },
	{ "Noodle Ned", "Common", 100, 2 },
	{ "Dancing Dumpling", "Rare", 300, 5 },
	{ "Turbo Taco", "Rare", 500, 8 },
	{ "Lord Lasagna", "Epic", 1500, 15 },
	{ "Queen Queso", "Epic", 2500, 20 },
	{ "King Kebab", "Legendary", 6000, 40 },
	{ "Baron Burger", "Legendary", 10000, 60 },
	{ "Eternal Ramen", "Mythic", 25000, 120 },
}

Test.check("config has 9 snacks", #Config.Snacks == 9, "got " .. tostring(#Config.Snacks))
for i, want in ipairs(expected) do
	local snack = Config.Snacks[i]
	Test.check("snack " .. i .. " name", snack ~= nil and snack.Name == want[1])
	Test.check("snack " .. i .. " rarity", snack ~= nil and snack.Rarity == want[2])
	Test.check("snack " .. i .. " price", snack ~= nil and snack.Price == want[3])
	Test.check("snack " .. i .. " rate", snack ~= nil and snack.Rate == want[4])
end

Test.check("BaseSlots is 6", Config.BaseSlots == 6)
Test.check("IncomeTickSeconds is 1", Config.IncomeTickSeconds == 1)
Test.check("SpawnIntervalSeconds is 8", Config.SpawnIntervalSeconds == 8)
Test.check("PlayCode", Config.PlayCode == "makefun-parcel-ranch-highland")
Test.check("StartingCash is 100", Config.StartingCash == 100)
Test.check("WeatherCycleSeconds is 120", Config.WeatherCycleSeconds == 120)
Test.check("WaveIntervalSeconds is 180", Config.WaveIntervalSeconds == 180)
Test.check("RebirthMultiplierStep is 0.5", Config.RebirthMultiplierStep == 0.5)

local colorCount = 0
local seenColors = {}
local distinct = true
for rarity, color in pairs(Config.RarityColors) do
	colorCount += 1
	local key = string.format("%.3f,%.3f,%.3f", color.R, color.G, color.B)
	if seenColors[key] then
		distinct = false
	end
	seenColors[key] = true
	Test.check("rarity color for " .. rarity .. " exists", color ~= nil and color.R ~= nil)
end
Test.check("rarity colors cover 5 rarities", colorCount == 5, "got " .. tostring(colorCount))
Test.check("rarity colors are distinct", distinct)

Test.check("RarityOrder lists 5 rarities", Config.RarityOrder ~= nil and #Config.RarityOrder == 5)

Test.finish()
