-- Steal a Snack — server bootstrap.
-- Loads every system module, creates the shared RemoteEvent, builds the
-- world, then starts the live systems in order.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local State = require(script:WaitForChild("State"))
local Economy = require(script:WaitForChild("Economy"))
local Bases = require(script:WaitForChild("Bases"))
local Spawner = require(script:WaitForChild("Spawner"))
local Steal = require(script:WaitForChild("Steal"))
local Rebirth = require(script:WaitForChild("Rebirth"))
local Wave = require(script:WaitForChild("Wave"))
local Weather = require(script:WaitForChild("Weather"))
local Leaderboard = require(script:WaitForChild("Leaderboard"))
local Effects = require(script:WaitForChild("Effects"))
local Saves = require(script:WaitForChild("Saves"))
local RateLimit = require(script:WaitForChild("RateLimit"))
local CharacterFactory = require(script:WaitForChild("CharacterFactory"))

-- Boot check: every system must have loaded as a module table. A missing or
-- broken module fails loudly here, at boot, instead of halfway through a game.
for name, module in pairs({
	State = State,
	Economy = Economy,
	Bases = Bases,
	Spawner = Spawner,
	Steal = Steal,
	Rebirth = Rebirth,
	Wave = Wave,
	Weather = Weather,
	Leaderboard = Leaderboard,
	Effects = Effects,
	Saves = Saves,
	RateLimit = RateLimit,
	CharacterFactory = CharacterFactory,
}) do
	assert(typeof(module) == "table", "[Steal a Snack] System failed to load: " .. name)
end

-- One channel for every server -> client update: cash, income, snacks,
-- weather, the leaderboard, and buy/steal feedback. Reuse an existing one
-- if this script ever runs twice (Studio re-runs), instead of doubling it.
local snackEvents = ReplicatedStorage:FindFirstChild("SnackEvents")
if snackEvents == nil then
	snackEvents = Instance.new("RemoteEvent")
	snackEvents.Name = "SnackEvents"
	snackEvents.Parent = ReplicatedStorage
end

-- Build the world. A failure here must not take the systems down with it.
local worldOk, worldErr = pcall(function()
	Bases.buildBelt()
	Bases.buildEnvironment()
end)
if not worldOk then
	warn("[Steal a Snack] World build failed: " .. tostring(worldErr))
end

if Saves.Store == nil then
	print("[Steal a Snack] DataStore unavailable — saves disabled (normal in Studio, live once published).")
end

-- Start each live system on its own thread so a system whose start() runs
-- its loop inline can never block the ones after it. A start error is
-- logged, not fatal: one sick system must not kill the server.
local function startSystem(name, startFn)
	task.spawn(function()
		local ok, err = pcall(startFn)
		if not ok then
			warn("[Steal a Snack] System failed to start: " .. name .. " — " .. tostring(err))
		end
	end)
end

startSystem("Economy", Economy.start)
startSystem("Spawner", Spawner.start)
startSystem("Wave", Wave.start)
startSystem("Weather", Weather.start)
startSystem("Leaderboard", Leaderboard.start)

print("[Steal a Snack] Server ready")
