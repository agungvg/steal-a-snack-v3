-- State.luau
-- Pure in-memory game state for Steal a Snack.
-- No Roblox services are touched at require time: this module is only
-- tables and functions, so it can be required by tests without a server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local State = {}

-- Map userId -> player table.
-- Player: { UserId, Cash, Multiplier, Rebirths, Snacks, Locked }
-- Snack entry: { Id, Name, Rarity, Price, Rate }
State.Players = {}

State.CurrentWeather = "Clear"
State.CurrentWave = 1

local nextId = 0

-- Returns the player table for userId, creating it on first sight.
function State.getPlayer(userId: number)
	local player = State.Players[userId]
	if player == nil then
		player = {
			UserId = userId,
			Cash = Config.StartingCash,
			Multiplier = 1,
			Rebirths = 0,
			Snacks = {},
			Locked = false,
		}
		State.Players[userId] = player
	end
	return player
end

function State.addCash(userId: number, amount: number)
	local player = State.getPlayer(userId)
	player.Cash += amount
	return player.Cash
end

function State.getCash(userId: number): number
	return State.getPlayer(userId).Cash
end

function State.setLocked(userId: number, locked: boolean)
	State.getPlayer(userId).Locked = locked
end

function State.isLocked(userId: number): boolean
	return State.getPlayer(userId).Locked
end

-- Appends a snack entry to the player's collection.
function State.addSnack(userId: number, snackEntry)
	local player = State.getPlayer(userId)
	table.insert(player.Snacks, snackEntry)
	return snackEntry
end

-- Removes the snack with the given id from the player's collection.
-- Returns the removed entry, or nil when the player does not own it.
function State.removeSnack(userId: number, snackId: number)
	local player = State.getPlayer(userId)
	for index, entry in ipairs(player.Snacks) do
		if entry.Id == snackId then
			table.remove(player.Snacks, index)
			return entry
		end
	end
	return nil
end

function State.getSnacks(userId: number)
	return State.getPlayer(userId).Snacks
end

-- Fresh incrementing snack id, unique for the whole server lifetime.
function State.nextSnackId(): number
	nextId += 1
	return nextId
end

return State
