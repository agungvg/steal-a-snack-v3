-- Steal a Snack — shared configuration.
-- The single source of truth for the snack ladder, tuning numbers and the
-- play code. Server modules and the client HUD both read this table, so a
-- balance change here flows everywhere without touching any other file.

local Config = {}

-- The snack ladder, cheapest first. Price is what a snack costs to buy,
-- Rate is the cash it earns every second while it sits on your base.
Config.Snacks = {
	{ Name = "Soggy Fry", Rarity = "Common", Price = 50, Rate = 1 },
	{ Name = "Noodle Ned", Rarity = "Common", Price = 100, Rate = 2 },
	{ Name = "Dancing Dumpling", Rarity = "Rare", Price = 300, Rate = 5 },
	{ Name = "Turbo Taco", Rarity = "Rare", Price = 500, Rate = 8 },
	{ Name = "Lord Lasagna", Rarity = "Epic", Price = 1500, Rate = 15 },
	{ Name = "Queen Queso", Rarity = "Epic", Price = 2500, Rate = 20 },
	{ Name = "King Kebab", Rarity = "Legendary", Price = 6000, Rate = 40 },
	{ Name = "Baron Burger", Rarity = "Legendary", Price = 10000, Rate = 60 },
	{ Name = "Eternal Ramen", Rarity = "Mythic", Price = 25000, Rate = 120 },
}

-- Lookup by name, built from the ladder above, so a buy or spawn by
-- name never has to scan the list.
Config.SnackByName = {}
for _, snack in ipairs(Config.Snacks) do
	Config.SnackByName[snack.Name] = snack
end

-- Rarest last; used wherever rarities need a stable order (weights, labels).
Config.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

-- Bright, distinct colours per rarity, used for snack bodies and labels.
Config.RarityColors = {
	Common = Color3.fromRGB(140, 205, 120),
	Rare = Color3.fromRGB(80, 160, 255),
	Epic = Color3.fromRGB(185, 95, 255),
	Legendary = Color3.fromRGB(255, 200, 40),
	Mythic = Color3.fromRGB(255, 70, 130),
}

-- How many snacks fit on one player's base.
Config.BaseSlots = 6

-- Seconds between income payouts.
Config.IncomeTickSeconds = 1

-- Seconds between snack spawns on the belt.
Config.SpawnIntervalSeconds = 8

-- make.fun play code for this entry. It also lives in the experience's
-- description on Roblox, which is what proves the place is ours.
Config.PlayCode = "makefun-parcel-ranch-highland"

-- Cash a new player starts with.
Config.StartingCash = 100

-- Seconds before the weather rolls to a new condition.
Config.WeatherCycleSeconds = 120

-- Seconds between waves; each wave raises the stakes and the rarity odds.
Config.WaveIntervalSeconds = 180

-- Extra income multiplier gained per rebirth.
Config.RebirthMultiplierStep = 0.5

return Config
