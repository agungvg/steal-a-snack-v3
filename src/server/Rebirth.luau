-- Rebirth.luau
-- Resetting a run for a permanent income multiplier.
-- Written fresh for Steal a Snack v3 from the design spec.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local State = require(script.Parent.State)
local Bases = require(script.Parent.Bases)

local Rebirth = {}

local REBIRTH_MIN_CASH = 500

function Rebirth.canRebirth(player)
	if not player then
		return false, "Invalid player"
	end
	if #State.getSnacks(player.UserId) < 1 then
		return false, "You need at least 1 snack to rebirth"
	end
	if State.getCash(player.UserId) < REBIRTH_MIN_CASH then
		return false, "You need at least $500 cash to rebirth"
	end
	return true, "Ready to rebirth"
end

function Rebirth.doRebirth(player)
	local can, reason = Rebirth.canRebirth(player)
	if not can then
		return false, reason
	end

	-- Clear every snack off the base and out of State. Copy the list first:
	-- removeSnack mutates the table we would otherwise be iterating.
	local owned = State.getSnacks(player.UserId)
	local snapshot = {}
	for _, snack in ipairs(owned) do
		table.insert(snapshot, snack)
	end
	for _, snack in ipairs(snapshot) do
		Bases.removeSnack(player, snack.Id)
	end

	-- Reset cash to the starting amount, then raise the multiplier.
	local currentCash = State.getCash(player.UserId)
	State.addCash(player.UserId, Config.StartingCash - currentCash)
	player.Multiplier = (player.Multiplier or 1) + Config.RebirthMultiplierStep
	player.Rebirths = (player.Rebirths or 0) + 1

	return true, string.format(
		"Rebirth complete! Income multiplier is now x%.1f (Rebirths: %d)",
		player.Multiplier,
		player.Rebirths
	)
end

return Rebirth
