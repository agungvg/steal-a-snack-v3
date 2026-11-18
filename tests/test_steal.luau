require("./stub_env")

local Config = Test.need("Config")
local State = Test.need("State")
local Bases = Test.need("Bases")
local Economy = Test.need("Economy")
local Steal = Test.need("Steal")
local RateLimit = Test.need("RateLimit")

local function hasSnack(userId, snackId)
	for _, snack in ipairs(State.getSnacks(userId)) do
		if snack.Id == snackId then
			return true
		end
	end
	return false
end

-- Both players get a real base, the way the server builds them on join.
local owner = Test.mockPlayer(401, "Owner")
local thief = Test.mockPlayer(402, "Thief")
Bases.createBase(owner)
Bases.createBase(thief)

-- The owner buys a snack the real way, so it sits in State and on the base.
State.addCash(401, 10000)
local bought, _why = Economy.buySnack(owner, Config.Snacks[4])
Test.check("setup buy succeeds", bought == true, tostring(_why))
local snackId = State.getSnacks(401)[1].Id

local ok, _msg = Steal.trySteal(thief, 401, snackId)
Test.check("steal succeeds", ok == true, tostring(_msg))
Test.check("stolen snack leaves the owner", hasSnack(401, snackId) == false)
Test.check("stolen snack joins the thief", hasSnack(402, snackId) == true)

local okMissing, _msgMissing = Steal.trySteal(thief, 401, 999999)
Test.check("stealing a missing snack fails", okMissing == false)

-- A locked base cannot be stolen from.
State.addCash(401, 10000)
Economy.buySnack(owner, Config.Snacks[5])
local lockedId = State.getSnacks(401)[1].Id
State.setLocked(401, true)
local okLocked, _msgLocked = Steal.trySteal(thief, 401, lockedId)
Test.check("stealing from a locked base fails", okLocked == false)
Test.check("locked snack stays put", hasSnack(401, lockedId) == true)
State.setLocked(401, false)
-- The first successful steal above legitimately spent the thief's 5s
-- Steal allowance, so reset it here: this scenario tests lock/unlock,
-- not the cooldown (the cooldown gets its own check below).
RateLimit.reset(402, "Steal")
local okUnlocked, _msgUnlocked = Steal.trySteal(thief, 401, lockedId)
Test.check("stealing works again once unlocked", okUnlocked == true, tostring(_msgUnlocked))

-- The limiter itself still bites: an immediate repeat steal is refused,
-- because the unlocked steal just spent the allowance again.
State.addCash(401, 10000)
Economy.buySnack(owner, Config.Snacks[1])
local freshId = State.getSnacks(401)[1].Id
local okCool, msgCool = Steal.trySteal(thief, 401, freshId)
Test.check("immediate repeat steal is on cooldown", okCool == false and msgCool == "Steal is on cooldown", tostring(msgCool))
Test.check("cooldown steal leaves the snack put", hasSnack(401, freshId) == true)
-- And a failed attempt never burns the allowance: resetting once lets
-- the same steal go through.
RateLimit.reset(402, "Steal")
local okRetry, _msgRetry = Steal.trySteal(thief, 401, freshId)
Test.check("steal succeeds after the allowance resets", okRetry == true, tostring(_msgRetry))
Test.check("retried snack joins the thief", hasSnack(402, freshId) == true)

Test.finish()
