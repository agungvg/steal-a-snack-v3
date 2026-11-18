-- Economy.luau
-- Buying snacks and the per-second income drip.
-- Written fresh for Steal a Snack v3 from the design spec.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local State = require(script.Parent.State)
local Bases = require(script.Parent.Bases)
local Effects = require(script.Parent.Effects)

local Economy = {}

function Economy.buySnack(player, snackData)
	if not player or not snackData then
		return false, "Invalid purchase"
	end
	if State.getCash(player.UserId) < snackData.Price then
		return false, "Not enough cash"
	end
	local freeSlot = Bases.getFreeSlot(player)
	if not freeSlot then
		return false, "Base is full"
	end

	State.addCash(player.UserId, -snackData.Price)
	local entry = {
		Id = State.nextSnackId(),
		Name = snackData.Name,
		Rarity = snackData.Rarity,
		Price = snackData.Price,
		Rate = snackData.Rate,
	}
	State.addSnack(player.UserId, entry)
	Bases.placeSnack(player, entry)

	-- The effect plays at the slot the snack just landed in, captured
	-- before placement so no post-hoc scan of the slots is needed.
	local slotPos = player.SlotPositions and player.SlotPositions[freeSlot]
	if slotPos then
		Effects.playBuyEffect(slotPos)
	end

	return true, "Bought " .. snackData.Name
end

function Economy.getIncomePerSecond(player)
	if not player then
		return 0
	end
	-- The State record is the single source of truth for the multiplier:
	-- Rebirth writes it there, and the drip loop passes State records
	-- here, so reading it off the Player instance would miss a rebirth.
	local record = State.getPlayer(player.UserId)
	local total = 0
	for _, snack in ipairs(State.getSnacks(player.UserId)) do
		total += snack.Rate or 0
	end
	return total * (record.Multiplier or 1)
end

function Economy.start()
	task.spawn(function()
		while true do
			task.wait(Config.IncomeTickSeconds)
			for _, player in pairs(State.Players) do
				local income = Economy.getIncomePerSecond(player) * Config.IncomeTickSeconds
				if income > 0 then
					State.addCash(player.UserId, income)
				end
			end
		end
	end)
end

return Economy
