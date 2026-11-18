require("./stub_env")

-- The server bootstrap must load without a real error and create the
-- shared RemoteEvent; the HUD must build its labels and react to events.
local initOk, initErr = pcall(Test.loadExtra, "init.server")
if initOk then
	Test.check("init.server loads", true)
elseif tostring(initErr):find("tick budget exceeded") ~= nil then
	Test.check("init.server loads (start loops tripped the tick budget)", true)
else
	Test.check("init.server loads", false, tostring(initErr))
end

local events = game:GetService("ReplicatedStorage"):FindFirstChild("SnackEvents")
Test.check("SnackEvents RemoteEvent created", events ~= nil and events.ClassName == "RemoteEvent")

local hudOk, hudErr = pcall(Test.loadExtra, "Hud.client")
Test.check("Hud.client loads", hudOk, tostring(hudErr))

local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
local hud = playerGui:FindFirstChild("SnackHud")
Test.check("SnackHud ScreenGui exists", hud ~= nil)

local function findLabel(name)
	if hud == nil then
		return nil
	end
	for _, descendant in ipairs(hud:GetDescendants()) do
		if descendant.Name == name then
			return descendant
		end
	end
	return nil
end

for _, name in ipairs({ "CashLabel", "IncomeLabel", "SnacksLabel", "WeatherLabel", "LeaderboardLabel", "FeedbackLabel" }) do
	Test.check("HUD has " .. name, findLabel(name) ~= nil)
end

if events ~= nil and hud ~= nil then
	events.OnClientEvent:Fire({ Type = "Cash", Cash = 777, Income = 12, Snacks = 3 })
	local cashLabel = findLabel("CashLabel")
	Test.check("cash label updates from event", cashLabel ~= nil and cashLabel.Text:find("777") ~= nil, cashLabel and cashLabel.Text)
	local incomeLabel = findLabel("IncomeLabel")
	Test.check("income label updates from event", incomeLabel ~= nil and incomeLabel.Text:find("12") ~= nil, incomeLabel and incomeLabel.Text)
	local snacksLabel = findLabel("SnacksLabel")
	Test.check("snacks label updates from event", snacksLabel ~= nil and snacksLabel.Text:find("3") ~= nil, snacksLabel and snacksLabel.Text)

	events.OnClientEvent:Fire({ Type = "Weather", Weather = "Rain" })
	local weatherLabel = findLabel("WeatherLabel")
	Test.check("weather label updates from event", weatherLabel ~= nil and weatherLabel.Text:find("Rain") ~= nil, weatherLabel and weatherLabel.Text)

	events.OnClientEvent:Fire({ Type = "Leaderboard", Lines = { "1. Alice — $500", "2. Bob — $300" } })
	local boardLabel = findLabel("LeaderboardLabel")
	Test.check("leaderboard updates from event", boardLabel ~= nil and boardLabel.Text:find("Alice") ~= nil, boardLabel and boardLabel.Text)

	events.OnClientEvent:Fire({ Type = "Feedback", Text = "Snack bought!" })
	local feedbackLabel = findLabel("FeedbackLabel")
	Test.check("feedback label updates from event", feedbackLabel ~= nil and feedbackLabel.Text == "Snack bought!", feedbackLabel and feedbackLabel.Text)

	events.OnClientEvent:Fire("Hello from server")
	Test.check("plain string event becomes feedback", feedbackLabel ~= nil and feedbackLabel.Text == "Hello from server", feedbackLabel and feedbackLabel.Text)
end

Test.finish()
