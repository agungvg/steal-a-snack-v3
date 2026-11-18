-- Wave.luau
-- Timed waves that bias spawns toward rarer snacks over time.
-- Written fresh for Steal a Snack v3 from the design spec.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local State = require(script.Parent.State)

local Wave = {}

local BASE_WEIGHTS = {
	Common = 50,
	Rare = 30,
	Epic = 12,
	Legendary = 6,
	Mythic = 2,
}

function Wave.getWave()
	return State.CurrentWave or 1
end

function Wave.getRarityWeights()
	local wave = Wave.getWave()
	-- Each wave past the first shifts weight from Common toward the rares.
	local shift = math.max(0, wave - 1)
	local common = math.max(10, BASE_WEIGHTS.Common - shift * 4)
	local rare = math.max(8, BASE_WEIGHTS.Rare - shift * 1)
	local epic = BASE_WEIGHTS.Epic + shift * 2
	local legendary = BASE_WEIGHTS.Legendary + shift * 1.5
	local mythic = BASE_WEIGHTS.Mythic + shift * 1
	return {
		Common = common,
		Rare = rare,
		Epic = epic,
		Legendary = legendary,
		Mythic = mythic,
	}
end

function Wave.start()
	task.spawn(function()
		while true do
			task.wait(Config.WaveIntervalSeconds)
			State.CurrentWave = (State.CurrentWave or 1) + 1
			print("[Wave] Wave " .. State.CurrentWave .. " has begun!")
		end
	end)
end

return Wave
