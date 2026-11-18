-- Steal.luau
-- Stealing a snack off another player's base.
-- Written fresh for Steal a Snack v3 from the design spec.

local Bases = require(script.Parent.Bases)
local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)
local RateLimit = require(script.Parent.RateLimit)

local Steal = {}

function Steal.trySteal(thiefPlayer, ownerUserId, snackId)
	if not thiefPlayer or not ownerUserId or not snackId then
		return false, "Invalid steal"
	end

	local owner = State.getPlayer(ownerUserId)
	if not owner then
		return false, "Owner not found"
	end
	if thiefPlayer.UserId == ownerUserId then
		return false, "You cannot steal from yourself"
	end
	if State.isLocked(ownerUserId) then
		return false, "Base is locked"
	end

	-- Find the snack on the owner's base before touching anything.
	local target = nil
	for _, snack in ipairs(State.getSnacks(ownerUserId)) do
		if snack.Id == snackId then
			target = snack
			break
		end
	end
	if not target then
		return false, "Snack not found"
	end

	if not Bases.getFreeSlot(thiefPlayer) then
		return false, "Your base is full"
	end

	if not RateLimit.check(thiefPlayer.UserId, "Steal") then
		return false, "Steal is on cooldown"
	end

	local removed = Bases.removeSnack(owner, snackId)
	if not removed then
		return false, "Snack not found"
	end

	State.addSnack(thiefPlayer.UserId, removed)
	Bases.placeSnack(thiefPlayer, removed)

	if thiefPlayer.Base then
		local pos = thiefPlayer.Base:GetPivot().Position + Vector3.new(0, 4, 0)
		Effects.playStealEffect(pos)
	end

	return true, "Stole " .. removed.Name
end

return Steal
