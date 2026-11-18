require("./stub_env")

local Config = Test.need("Config")
local Factory = Test.need("CharacterFactory")

-- An attribute may live on the model or on its Body part; check both.
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

for _, snack in ipairs(Config.Snacks) do
	local model = Factory.buildSnack(snack, 1)
	Test.check(snack.Name .. " builds a Model", model ~= nil and model.ClassName == "Model")
	Test.check(snack.Name .. " has Body as PrimaryPart", model ~= nil and model.PrimaryPart ~= nil and model.PrimaryPart.Name == "Body")
	Test.check(snack.Name .. " has parts", model ~= nil and Factory.countParts(model) > 0)
	Test.check(snack.Name .. " attribute SnackName", getAttr(model, "SnackName") == snack.Name)
	Test.check(snack.Name .. " attribute Rarity", getAttr(model, "Rarity") == snack.Rarity)
	Test.check(snack.Name .. " attribute Price", getAttr(model, "Price") == snack.Price)
	Test.check(snack.Name .. " attribute Rate", getAttr(model, "Rate") == snack.Rate)
end

-- Click detector: parented to Body, fires the callback on click.
local model = Factory.buildSnack(Config.Snacks[1], 1)
local clicked = false
Factory.attachClick(model, function()
	clicked = true
end)
local detector = nil
if model.PrimaryPart ~= nil then
	detector = model.PrimaryPart:FindFirstChildOfClass("ClickDetector")
end
Test.check("click detector parented to Body", detector ~= nil)
if detector ~= nil then
	detector.MouseClick:Fire(game:GetService("Players").LocalPlayer)
	Test.check("click detector fires the callback", clicked == true)
end

-- Caption: some descendant carries the text (or an attribute).
Factory.setCaption(model, "Hello snack")
local captionFound = false
for _, descendant in ipairs(model:GetDescendants()) do
	if descendant.Text == "Hello snack" then
		captionFound = true
		break
	end
end
if not captionFound and model:GetAttribute("Caption") == "Hello snack" then
	captionFound = true
end
Test.check("setCaption shows the text", captionFound)

-- Higher tiers still build.
local tiered = Factory.buildSnack(Config.Snacks[9], 3)
Test.check("tier 3 mythic builds", tiered ~= nil and tiered.PrimaryPart ~= nil and Factory.countParts(tiered) > 0)

Test.finish()
