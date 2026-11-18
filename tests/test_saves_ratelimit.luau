require("./stub_env")

local Saves = Test.need("Saves")
local RateLimit = Test.need("RateLimit")

-- DataStores are unavailable in the stub, so the store is nil and both
-- calls must degrade gracefully instead of erroring.
Test.check("Saves.Store is nil without DataStores", Saves.Store == nil)

local saveOk, saveErr = pcall(Saves.savePlayer, 701)
Test.check("savePlayer with nil store does not error", saveOk, tostring(saveErr))

local loadOk, loaded = pcall(Saves.loadPlayer, 701)
Test.check("loadPlayer with nil store does not error", loadOk, tostring(loaded))
Test.check("loadPlayer with nil store returns nothing", loaded == nil or loaded == false, "got " .. tostring(loaded))

Test.check("Buy limit is 2", RateLimit.Limits ~= nil and RateLimit.Limits.Buy == 2)
Test.check("Steal limit is 5", RateLimit.Limits ~= nil and RateLimit.Limits.Steal == 5)

Test.check("first Buy check passes", RateLimit.check(801, "Buy") == true)
Test.check("second immediate Buy check is rejected", RateLimit.check(801, "Buy") == false)
Test.check("first Steal check passes", RateLimit.check(801, "Steal") == true)
Test.check("second immediate Steal check is rejected", RateLimit.check(801, "Steal") == false)
Test.check("a different user is unaffected", RateLimit.check(802, "Buy") == true)

Test.finish()
