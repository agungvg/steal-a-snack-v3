require("./stub_env")

local Config = Test.need("Config")
local Spawner = Test.need("Spawner")

local function getAttr(model, name)
	local value = model:GetAttribute(name)
	if value ~= nil then
		return value
	end
	if model.PrimaryPart ~= nil then
		return model.PrimaryPart:GetAttribute(name)
	end
	return nil
end

local workspace = game:GetService("Workspace")

local first = Spawner.spawnSnack(Config.Snacks[1])
Test.check("spawnSnack returns a model", first ~= nil and first.ClassName == "Model")
Test.check("spawned walker is named for its snack", getAttr(first, "SnackName") == "Soggy Fry", "got " .. tostring(getAttr(first, "SnackName")))

-- A spread of rarities spawns with matching attributes (the label tier
-- follows the snack being spawned).
for _, snack in ipairs({ Config.Snacks[3], Config.Snacks[5], Config.Snacks[9] }) do
	local model = Spawner.spawnSnack(snack)
	Test.check(snack.Name .. " spawns", model ~= nil and model.ClassName == "Model")
	Test.check(snack.Name .. " rarity label", getAttr(model, "Rarity") == snack.Rarity, "got " .. tostring(getAttr(model, "Rarity")))
	Test.check(snack.Name .. " rate label", getAttr(model, "Rate") == snack.Rate)
end

local models = 0
for _, descendant in ipairs(workspace:GetDescendants()) do
	if descendant.ClassName == "Model" then
		models += 1
	end
end
Test.check("spawned walkers live in the Workspace", models >= 4, "found " .. tostring(models))

local started, startErr = Test.runStart("Spawner", Spawner.start)
Test.check("Spawner.start runs", started, startErr)
local spawnErrors = Test.runSpawned()
Test.check("spawned spawner jobs are clean", #spawnErrors == 0, table.concat(spawnErrors, "; "))

Test.finish()
