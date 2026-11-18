-- Saves.luau
-- DataStore persistence for player progress. Session-only when the
-- DataStore is unavailable (normal in Studio).
-- Written fresh for Steal a Snack v3 from the design spec.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local State = require(script.Parent.State)
local Bases = require(script.Parent.Bases)

local Saves = {}

local store = nil
local ok, result = pcall(function()
	return DataStoreService:GetDataStore("StealASnackV3")
end)
if ok and result then
	store = result
else
	warn("[Saves] DataStore unavailable, saves disabled (session-only progress): "
		.. tostring(result))
end
Saves.Store = store

function Saves.savePlayer(userId)
	if not Saves.Store then
		return false
	end
	local player = State.getPlayer(userId)
	if not player then
		return false
	end
	local snackNames = {}
	for _, snack in ipairs(State.getSnacks(userId)) do
		table.insert(snackNames, snack.Name)
	end
	local data = {
		Cash = player.Cash or 0,
		Multiplier = player.Multiplier or 1,
		Rebirths = player.Rebirths or 0,
		SnackNames = snackNames,
	}
	local success, err = pcall(function()
		Saves.Store:SetAsync("player_" .. tostring(userId), data)
	end)
	if not success then
		warn("[Saves] Save failed for " .. tostring(userId) .. ": " .. tostring(err))
		return false
	end
	return true
end

function Saves.loadPlayer(userId)
	if not Saves.Store then
		return nil
	end
	local success, data = pcall(function()
		return Saves.Store:GetAsync("player_" .. tostring(userId))
	end)
	if not success then
		warn("[Saves] Load failed for " .. tostring(userId) .. ": " .. tostring(data))
		return false
	end
	if not data then
		return false
	end
	local player = State.getPlayer(userId)
	if not player then
		return false
	end

	player.Cash = data.Cash or player.Cash or 0
	player.Multiplier = data.Multiplier or 1
	player.Rebirths = data.Rebirths or 0

	-- Rebuild the snack list from saved names, looking each name up in Config.
	local byName = {}
	for _, snack in ipairs(Config.Snacks) do
		byName[snack.Name] = snack
	end
	if data.SnackNames then
		for _, name in ipairs(data.SnackNames) do
			local snackData = byName[name]
			if snackData then
				local entry = {
					Id = State.nextSnackId(),
					Name = snackData.Name,
					Rarity = snackData.Rarity,
					Price = snackData.Price,
					Rate = snackData.Rate,
				}
				State.addSnack(userId, entry)
				-- If the base already exists (rejoin after base build),
				-- show the snack on it; otherwise it stays in State until
				-- the base is created. Never place into a missing base.
				if player.Base then
					Bases.placeSnack(player, entry)
				end
			end
		end
	end
	return true
end

return Saves
