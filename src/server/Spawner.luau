-- Spawner.luau
-- Spawns snack walkers on the belt on a timer. Walkers stroll along the
-- belt's X axis; clicking one tries to buy it through Economy, and on
-- success the walker is removed and the snack lands on the buyer's base.
-- The loop only runs after start() is called, never at require time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local State = require(script.Parent.State)
local Economy = require(script.Parent.Economy)
local Bases = require(script.Parent.Bases)
local CharacterFactory = require(script.Parent.CharacterFactory)

local Spawner = {}

-- Belt geometry: walkers travel from START_X to END_X at BELT_Y.
local START_X = -45
local END_X = 45
local BELT_Y = 3
local BELT_Z = 0
local WALK_SPEED = 2.5 -- studs per second

local labelTier = 0
local running = false

-- Base spawn weights by rarity; commons show up far more often.
local RARITY_WEIGHTS = {
	Common = 50,
	Rare = 25,
	Epic = 15,
	Legendary = 8,
	Mythic = 2,
}

-- Rarity order used to bias later waves toward rarer snacks.
local RARITY_ORDER = {
	Common = 0,
	Rare = 1,
	Epic = 2,
	Legendary = 3,
	Mythic = 4,
}

local function pickSnack()
	local wave = State.CurrentWave or 1
	local total = 0
	local weighted = {}
	for _, snack in ipairs(Config.Snacks) do
		local base = RARITY_WEIGHTS[snack.Rarity] or 10
		local rarityIndex = RARITY_ORDER[snack.Rarity] or 0
		-- Each wave past the first lifts rarer snacks a little.
		local weight = base * (1 + (wave - 1) * 0.12 * rarityIndex)
		table.insert(weighted, { snack = snack, weight = weight })
		total += weight
	end
	-- Empty snack list: nothing to pick, instead of indexing a nil entry.
	if total <= 0 or #weighted == 0 then
		return nil
	end
	local roll = math.random() * total
	local runningTotal = 0
	for _, entry in ipairs(weighted) do
		runningTotal += entry.weight
		if roll <= runningTotal then
			return entry.snack
		end
	end
	return weighted[#weighted].snack
end

local function getWalkersFolder(): Folder
	local folder = workspace:FindFirstChild("SnackWalkers")
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "SnackWalkers"
		folder.Parent = workspace
	end
	return folder
end

-- Walks one model from the start of the belt to the end, then removes it
-- if nobody bought it along the way.
local function walkAlongBelt(model: Model)
	task.spawn(function()
		local x = START_X
		while model.Parent ~= nil and x < END_X do
			model:PivotTo(CFrame.new(x, BELT_Y, BELT_Z))
			x += WALK_SPEED * 0.05
			task.wait(0.05)
		end
		if model.Parent ~= nil then
			model:Destroy()
		end
	end)
end

-- Spawns one walker for the given snack and returns the model.
function Spawner.spawnSnack(snackData): Model
	labelTier = (labelTier + 1) % 3
	local model = CharacterFactory.buildSnack(snackData, labelTier)
	model:PivotTo(CFrame.new(START_X, BELT_Y, BELT_Z))
	model.Parent = getWalkersFolder()

	CharacterFactory.attachClick(model, function(player: Player)
		if model.Parent == nil then
			return
		end
		local ok = Economy.buySnack(player, snackData)
		if ok then
			model:Destroy()
			-- buySnack already placed the snack on the buyer's base
			-- (State entry + Bases.placeSnack), so nothing more to do here.
		end
	end)

	walkAlongBelt(model)
	return model
end

-- Starts the spawn timer loop. Safe to call once; a second call is a no-op.
function Spawner.start()
	if running then
		return
	end
	running = true
	task.spawn(function()
		-- Guard the interval so a misconfigured Config can never spin
		-- the loop with a zero / negative wait.
		local interval = Config.SpawnIntervalSeconds
		if type(interval) ~= "number" or interval <= 0 then
			interval = 8
		end
		while running do
			task.wait(interval)
			local snack = pickSnack()
			if snack ~= nil then
				Spawner.spawnSnack(snack)
			end
		end
	end)
end

return Spawner
