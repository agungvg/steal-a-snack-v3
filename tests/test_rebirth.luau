require("./stub_env")

local Config = Test.need("Config")
local State = Test.need("State")
local Bases = Test.need("Bases")
local Economy = Test.need("Economy")
local Rebirth = Test.need("Rebirth")

-- Rebirth works on the Player object (it clears the base slots through
-- Bases, which live on that object); the State table only holds the cash.
local fresh = Test.mockPlayer(502, "Fresh")
Bases.createBase(fresh)
Test.check("canRebirth answers a boolean", type(Rebirth.canRebirth(fresh)) == "boolean")
Test.check("a snackless player cannot rebirth", Rebirth.canRebirth(fresh) == false)

-- A rich player with a snack on the base can rebirth.
local player = Test.mockPlayer(501, "Rebirther")
Bases.createBase(player)
State.addCash(501, 1000000)
local bought, _why = Economy.buySnack(player, Config.Snacks[1])
Test.check("setup buy succeeds", bought == true, tostring(_why))

Test.check("rich player can rebirth", Rebirth.canRebirth(player) == true)

local ok, _msg = Rebirth.doRebirth(player)
Test.check("doRebirth succeeds", ok ~= false, tostring(_msg))
Test.check("rebirth counts up", player.Rebirths == 1, "got " .. tostring(player.Rebirths))
Test.check(
	"rebirth raises the multiplier by one step",
	player.Multiplier == 1 + Config.RebirthMultiplierStep,
	"got " .. tostring(player.Multiplier)
)
Test.check("rebirth clears the snacks", #State.getSnacks(501) == 0, "got " .. tostring(#State.getSnacks(501)))
Test.check("rebirth resets cash to the starting amount", State.getCash(501) == Config.StartingCash, "got " .. tostring(State.getCash(501)))
Test.check("rebirth frees the base slot", Bases.getFreeSlot(player) == 1, "got " .. tostring(Bases.getFreeSlot(player)))

Test.finish()
