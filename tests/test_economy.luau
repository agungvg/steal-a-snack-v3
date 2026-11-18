require("./stub_env")

local Config = Test.need("Config")
local State = Test.need("State")
local Bases = Test.need("Bases")
local Economy = Test.need("Economy")

-- Economy and Bases work on the Player object (createBase attaches .Slots
-- to it); the State record behind the UserId holds Cash, Multiplier,
-- Rebirths and Snacks.
local player = Test.mockPlayer(201, "EcoTester")
Bases.createBase(player)

-- Buy the cheapest snack: cash drops by exactly its price.
local ok, _msg = Economy.buySnack(player, Config.Snacks[1])
Test.check("buy Soggy Fry succeeds", ok == true)
Test.check("buy deducts the price", State.getCash(201) == Config.StartingCash - 50, "got " .. tostring(State.getCash(201)))
Test.check("income is the fry rate", Economy.getIncomePerSecond(player) == 1, "got " .. tostring(Economy.getIncomePerSecond(player)))

-- Too expensive: rejected, cash untouched.
local ok2, _msg2 = Economy.buySnack(player, Config.Snacks[9])
Test.check("buy Eternal Ramen with $50 fails", ok2 == false)
Test.check("failed buy leaves cash alone", State.getCash(201) == 50)

-- Fund the player, buy a second snack, income adds up.
State.addCash(201, 10000)
local ok3, _msg3 = Economy.buySnack(player, Config.Snacks[2])
Test.check("buy Noodle Ned succeeds", ok3 == true)
Test.check("income sums both snacks", Economy.getIncomePerSecond(player) == 3, "got " .. tostring(Economy.getIncomePerSecond(player)))

-- The multiplier lives on the State record, not on the Player object:
-- setting it there scales income, and a stray field on the Player is ignored.
State.getPlayer(201).Multiplier = 2
Test.check("multiplier doubles income", Economy.getIncomePerSecond(player) == 6, "got " .. tostring(Economy.getIncomePerSecond(player)))
State.getPlayer(201).Multiplier = 1

-- A full base rejects any further buy, end to end through buySnack.
local full = Test.mockPlayer(202, "FullTester")
Bases.createBase(full)
State.addCash(202, 100000)
for _ = 1, Config.BaseSlots do
	local bought, _why = Economy.buySnack(full, Config.Snacks[1])
	Test.check("filling buy succeeds", bought == true, tostring(_why))
end
Test.check("base holds 6 snacks", #State.getSnacks(202) == Config.BaseSlots)
local okFull, _msgFull = Economy.buySnack(full, Config.Snacks[1])
Test.check("buy with a full base fails", okFull == false)

-- The income loop starts without a real error.
local started, startErr = Test.runStart("Economy", Economy.start)
Test.check("Economy.start runs", started, startErr)
local spawnErrors = Test.runSpawned()
Test.check("spawned economy jobs are clean", #spawnErrors == 0, table.concat(spawnErrors, "; "))

Test.finish()
