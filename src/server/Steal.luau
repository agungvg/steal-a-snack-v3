-- Steal.luau
-- Stealing a snack off another player's base.
-- Written fresh for Steal a Snack v3 from the design spec.

local Bases = require(script.Parent.Bases)
local State = require(script.Parent.State)
local Effects = require(script.Parent.Effects)
local RateLimit = require(script.Parent.RateLimit)

local Steal = {}

-- The owner's Player object carries the base slots, so removing through
-- it clears the slot and destroys the snack's model as well as dropping
-- it from State. When the server cannot see that Player (they left, or
-- the caller only has the userId), fall back to the State record:
-- Bases.removeSnack then does a State-only removal instead.
local function resolveOwner(ownerUserId, ownerRecord)
	local players = game:GetService("Players")
	local ownerPlayer = nil
	if players and players.GetPlayerByUserId then
		local ok, found = pcall(function()
			return players:GetPlayerByUserId(ownerUserId)
		end)
		if ok then
			ownerPlayer = found
		end
	end
	if ownerPlayer and ownerPlayer.Slots then
		return ownerPlayer
	end
	return ownerRecord
end

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

	-- The rate limit is spent only once the steal is otherwise certain to
	-- go through: every failure above returns before this check, so a
	-- failed attempt never burns the allowance and the retry is not
	-- greeted with "Steal is on cooldown".
	if not RateLimit.check(thiefPlayer.UserId, "Steal") then
		return false, "Steal is on cooldown"
	end

	local removed = Bases.removeSnack(resolveOwner(ownerUserId, owner), snackId)
	if not removed then
		-- The transfer itself failed after the allowance was spent:
		-- refund it so the next attempt is judged on its own merits.
		RateLimit.reset(thiefPlayer.UserId, "Steal")
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
