require("./stub_env")

local Config = Test.need("Config")
local State = Test.need("State")
local Bases = Test.need("Bases")

-- Bases works on the Player object (it needs .Name and attaches .Slots to
-- it); the State table is a different object and must not be passed here.
local player = Test.mockPlayer(301, "BaseTester")
local base = Bases.createBase(player)
Test.check("createBase returns a base", base ~= nil)
Test.check("createBase names the base after the player", base ~= nil and base.Name == "BaseTester_Base", base and base.Name)
Test.check("createBase attaches slots to the player", player.Slots ~= nil)

local slot = Bases.getFreeSlot(player)
Test.check("first free slot is a slot number", type(slot) == "number" and slot >= 1 and slot <= Config.BaseSlots, "got " .. tostring(slot))

local function snackEntry(name, rate)
	return {
		Id = State.nextSnackId(),
		Name = name,
		Rarity = "Common",
		Price = 50,
		Rate = rate,
	}
end

local first = snackEntry("Soggy Fry", 1)
State.addSnack(301, first)
local placed = Bases.placeSnack(player, first)
Test.check("placeSnack accepts the snack", placed ~= false)
local slot2 = Bases.getFreeSlot(player)
Test.check("placing consumes a slot", type(slot2) == "number" and slot2 ~= slot, "slot was " .. tostring(slot) .. ", now " .. tostring(slot2))

-- Fill the rest of the base.
local placedIds = { first.Id }
for _ = 2, Config.BaseSlots do
	local entry = snackEntry("Noodle Ned", 2)
	State.addSnack(301, entry)
	Bases.placeSnack(player, entry)
	table.insert(placedIds, entry.Id)
end
Test.check("no free slot on a full base", Bases.getFreeSlot(player) == nil)

-- Removing one frees a slot again.
local removed = Bases.removeSnack(player, placedIds[1])
Test.check("removeSnack returns the entry", removed ~= nil and removed.Id == placedIds[1])
local freed = Bases.getFreeSlot(player)
Test.check("removeSnack frees a slot", type(freed) == "number", "got " .. tostring(freed))

-- World building creates parts in the Workspace.
local before = #game:GetService("Workspace"):GetDescendants()
local beltOk, belt = pcall(Bases.buildBelt)
Test.check("buildBelt runs", beltOk, tostring(belt))
local afterBelt = #game:GetService("Workspace"):GetDescendants()
Test.check("buildBelt adds world parts", belt ~= nil or afterBelt > before, "before " .. tostring(before) .. " after " .. tostring(afterBelt))

local envOk, env = pcall(Bases.buildEnvironment)
Test.check("buildEnvironment runs", envOk, tostring(env))
local afterEnv = #game:GetService("Workspace"):GetDescendants()
Test.check("buildEnvironment adds world parts", env ~= nil or afterEnv > afterBelt, "after belt " .. tostring(afterBelt) .. " after env " .. tostring(afterEnv))

-- The design calls for exactly 16 PointLights across the build (beacon
-- + spawn + stalls + wheel hub + rim + tower flanks + gates + base row),
-- never more than 20.
local lightCount = 0
if env ~= nil then
	for _, descendant in ipairs(env:GetDescendants()) do
		if descendant.ClassName == "PointLight" then
			lightCount += 1
		end
	end
end
Test.check("environment holds exactly 16 PointLights", lightCount == 16, "got " .. tostring(lightCount))

-- Locking lives in State and Bases honours it through the same flag.
State.setLocked(301, true)
Test.check("base lock flag reads back", State.isLocked(301) == true)

Test.finish()
