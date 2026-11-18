require("./stub_env")

local Config = Test.need("Config")
local State = Test.need("State")

local player = State.getPlayer(101)
Test.check("new player has starting cash", player.Cash == Config.StartingCash, "got " .. tostring(player.Cash))
Test.check("new player multiplier starts at 1", player.Multiplier == 1)
Test.check("new player rebirths start at 0", player.Rebirths == 0)
Test.check("new player has no snacks", player.Snacks ~= nil and #player.Snacks == 0)
Test.check("new player is not locked", player.Locked == false)
Test.check("new player UserId recorded", player.UserId == 101)

local same = State.getPlayer(101)
Test.check("getPlayer returns the same table", same == player)

State.addCash(101, 50)
Test.check("addCash adds", State.getCash(101) == Config.StartingCash + 50, "got " .. tostring(State.getCash(101)))

State.setLocked(101, true)
Test.check("setLocked(true) locks", State.isLocked(101) == true)
State.setLocked(101, false)
Test.check("setLocked(false) unlocks", State.isLocked(101) == false)

local idA = State.nextSnackId()
local idB = State.nextSnackId()
Test.check("nextSnackId increases", type(idA) == "number" and type(idB) == "number" and idB > idA)

local entry = { Id = State.nextSnackId(), Name = "Soggy Fry", Rarity = "Common", Price = 50, Rate = 1 }
State.addSnack(101, entry)
local snacks = State.getSnacks(101)
Test.check("addSnack stores the snack", #snacks == 1, "got " .. tostring(#snacks))
Test.check("stored snack keeps its id", snacks[1] ~= nil and snacks[1].Id == entry.Id)

State.removeSnack(101, entry.Id)
Test.check("removeSnack removes the snack", #State.getSnacks(101) == 0)

local ok = pcall(State.removeSnack, 101, 999999)
Test.check("removeSnack of a missing id does not error", ok)

Test.finish()
