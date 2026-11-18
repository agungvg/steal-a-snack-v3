require("./stub_env")

local State = Test.need("State")
local Leaderboard = Test.need("Leaderboard")

local function cashOf(entry)
	if entry == nil then
		return 0
	end
	if type(entry.Cash) == "number" then
		return entry.Cash
	end
	if type(entry.UserId) == "number" then
		return State.getCash(entry.UserId)
	end
	return 0
end

State.getPlayer(601)
local second = State.getPlayer(602)
State.addCash(602, 400)
local third = State.getPlayer(603)
State.addCash(603, 200)

-- Cash is now: 601 -> 100, 602 -> 500, 603 -> 300.
local richest = Leaderboard.getRichest(2)
Test.check("getRichest(2) returns two", richest ~= nil and #richest == 2, "got " .. tostring(richest and #richest))
if richest ~= nil and #richest == 2 then
	Test.check("richest is ordered", cashOf(richest[1]) >= cashOf(richest[2]))
	Test.check("richest first is the 500 player", cashOf(richest[1]) == 500, "got " .. tostring(cashOf(richest[1])))
end

local all = Leaderboard.getRichest(10)
Test.check("getRichest(10) returns every player", all ~= nil and #all >= 3, "got " .. tostring(all and #all))

local started, startErr = Test.runStart("Leaderboard", Leaderboard.start)
Test.check("Leaderboard.start runs", started, startErr)

Test.finish()
